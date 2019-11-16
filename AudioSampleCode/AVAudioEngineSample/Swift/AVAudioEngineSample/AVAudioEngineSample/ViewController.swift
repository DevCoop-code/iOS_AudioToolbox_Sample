//
//  ViewController.swift
//  AVAudioEngineSample
//
//  Created by HanGyo Jeong on 14/11/2019.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//
//Use Free icons : https://icons8.com"

import UIKit
import AVFoundation

class ViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var countUpLabel: UILabel!
    @IBOutlet weak var countDownLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    //MARK: AVAudio Properties
    var engine = AVAudioEngine()
    var player = AVAudioPlayerNode()        //Plays buffers or segments of audio files
    var rateEffect = AVAudioUnitTimePitch() //Provides good-quality playback rate and pitch shifting independently of each other
    
    /*
     [AVAudioFile]
     An audio file that can be opened for reading or writing
     */
    var audioFile: AVAudioFile? {
        didSet{
            if let audioFile = audioFile{
                audioLengthSamples = audioFile.length   //Number of sample frames in these file
                audioFormat = audioFile.processingFormat
                audioSampleRate = Float(audioFormat?.sampleRate ?? 44100)   //Audio Sample rating in hartz
                audioLengthSeconds = Float(audioLengthSamples) / audioSampleRate
            }
        }
    }
    var audioFileURL: URL?{
        didSet{
            if let audioFileURL = audioFileURL{
                audioFile = try? AVAudioFile(forReading: audioFileURL)
            }
        }
    }
    
    //MARK: Other properties
    var audioFormat: AVAudioFormat?
    var audioSampleRate: Float = 0
    var audioLengthSeconds: Float = 0
    var audioLengthSamples: AVAudioFramePosition = 0
    var needsFileScheduled = true
    let rateSliderValues: [Float] = [0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    var rateValue: Float = 1.0 {
        didSet{
            rateEffect.rate = rateValue
            updateRateLabel()
        }
    }
    var updater: CADisplayLink?
    var currentFrame: AVAudioFramePosition{
        guard let lastRenderTime = player.lastRenderTime, let playerTime = player.nodeTime(forPlayerTime: lastRenderTime) else{
            return 0
        }
        
        return playerTime.sampleTime
    }
    var skipFrame: AVAudioFramePosition = 0
    var currentPosition: AVAudioFramePosition = 0
    let minDb: Float = -80.0
    
    enum TimeConstant {
        static let secsPerMin = 60
        static let secsPerHour = TimeConstant.secsPerMin * 60
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupRateBar()
        countUpLabel.text = formatted(time: 0)
        countDownLabel.text = formatted(time: audioLengthSeconds)
        setupAudio()

        updater = CADisplayLink(target: self, selector: #selector(updateUI))
        updater?.add(to: .current, forMode: .default)   //Registers the display link with a run loop.
        updater?.isPaused = true
    }
}

//MARK: - Actions
extension ViewController{
    @IBAction func playTapped(_ sender: UIButton) {
        //Toggle the selection state of button
        sender.isSelected = !sender.isSelected
        
        //
        if player.isPlaying{    //Whether or not player is playing
            disconnectVolumeTap()
            updater?.isPaused = true
            player.pause()
        }else{
            if needsFileScheduled{
                needsFileScheduled = false
                scheduleAudioFile()
            }
            connectVolumeTap()
            updater?.isPaused = false
            player.play()
        }
    }
    
    @objc func updateUI(){
        print("updateUI");
        //skipFrame is an offset added to or subtracted from currentFrame
        currentPosition = currentFrame + skipFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)
        
        progressBar.progress = Float(currentPosition) / Float(audioLengthSamples)
        let time = Float(currentPosition) / audioSampleRate
        countUpLabel.text = formatted(time: time)
        countDownLabel.text = formatted(time: audioLengthSeconds - time)
        
        if currentPosition >= audioLengthSamples{
            player.stop()                       //Stop the player
            updater?.isPaused = true            //Pause the timer
            playPauseButton.isSelected = false  //Reset the playPause selection state
            disconnectVolumeTap()               //Disconnect volume tap
        }
    }
}

//MARK: - Display Related Logic
extension ViewController{
    
    func setupRateBar(){
        let numSteps = rateSliderValues.count - 1
        rateSlider.minimumValue = 0
        rateSlider.maximumValue = Float(numSteps)
        rateSlider.isContinuous = true
        rateSlider.setValue(1.0, animated: false)
        rateValue = 1.0
        updateRateLabel()
    }

    func updateRateLabel(){
        rateLabel.text = "\(rateValue)x"
    }
    
    func formatted(time: Float) -> String{
        var secs = Int(ceil(time))
        var hours = 0
        var mins = 0
        
        if secs > TimeConstant.secsPerHour {
            hours = secs / TimeConstant.secsPerHour
            secs -= hours * TimeConstant.secsPerHour
        }
        
        if secs > TimeConstant.secsPerMin {
            mins = secs / TimeConstant.secsPerMin
            secs -= mins * TimeConstant.secsPerMin
        }
        
        var formattedString = ""
        if hours > 0{
            formattedString = "\(String(format: "%02d", hours)):"
        }
        formattedString += "\(String(format: "%02d", mins)):\(String(format: "%02d", secs))"
        return formattedString
    }
}

//MARK: - Audio
extension ViewController{
    func setupAudio() -> Void {
        audioFileURL = Bundle.main.url(forResource: "SimpsonMovie", withExtension: "mp4")
        
        //Attach the player node to the engine, which you must do before connecting other nodes
        engine.attach(player);
        engine.connect(player, to: engine.mainMixerNode, format: audioFormat)   //Establishes a connection between two audio nodes
        
        do{
            try engine.start()
        }catch let error{
            print(error.localizedDescription)
        }
    }
    
    func scheduleAudioFile(){
        guard let audioFile = audioFile else {
            return
        }
        
        skipFrame = 0
        /*
         There are other variants of scheduling audio for playback
         - scheduleBuffer(AVAudioPCMBuffer, completionHandler: AVAudioNodeCompletionHandler? = nil)
         - scheduleSegment(AVAudioFile, startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount, at: AVAudioTime?, completionHandler: AVAudioNodeCompletionHandler? = nil)
         */
        player.scheduleFile(audioFile, at: nil) {       //Schedules playing of an entire audio file.
            [weak self] in self?.needsFileScheduled = true
        }
    }
    
    func connectVolumeTap(){
        /*
         [mainMixerNode]
         Audio engine's optional singleton main mixer node
         */
        //1
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        
        /*
         [installTap]
         Installs an audio tap on the bus to record, monitor, and observe the output of the node
         1st: The node output bus to which to attach the tap
         2nd: requested size of the incoming buffers
         3rd: format
         4th: Block(receives copies of the output of an AVAudioNode) to be called with audio buffers
            (AVAudioPCMBuffer, AVAudioTime)
                1st: buffer parameter is a buffer of audio captured from the output of an AVAudioNode
                2nd: time the buffer was captured
         */
        //2
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
            //3
            guard
            let channelData = buffer.floatChannelData,
            let updater = self.updater
                else{
                    return
            }
            
            let channelDataValue = channelData.pointee
            //4
            let channelDataValueArray = stride(from: 0,
                                               to: Int(buffer.frameLength),
                                               by: buffer.stride).map { channelDataValue[$0] }

            //5
            let leftOper = channelDataValueArray.map{ $0 * $0 }.reduce(0, +)
            let rightOper = Float(buffer.frameLength)
            let rms = sqrt(leftOper / rightOper)
            
            //6
            let avgPower = 20 * log10(rms)
            
            //7
            let meterLevel = self.scaledPower(power: avgPower)
            
        }
    }
    
    func disconnectVolumeTap(){
        engine.mainMixerNode.removeTap(onBus: 0)
    }
    
    func seek(to time: Float){
        
    }
    
    /*
     Compute the average power on a 1k buffer of audio samples
     Common way to determine the average power of a buffer of audio samples is to
     calculate the Root Mean Square(RMS)
     */
    func scaledPower(power: Float) -> Float{
        //Check to make sure power is a valid value
        guard power.isFinite else { return 0.0 }
        
        //Sets the dynamic range of vuMeter(Volume Unit Meter)
        if power < minDb{
            return 0.0
        }
        else if power >= 1.0{
            return 1.0
        }
        else{
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
}
