//
//  ViewController.m
//  AVAudioEngineSample
//
//  Created by HanGyo Jeong on 2019/12/07.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    AVAudioEngine *engine;
    AVAudioPlayerNode *player;
    AVAudioFile *file;
    
    NSURL *audioSourcePath;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAudio];
}

- (void)setupAudio{
    NSError *error;
    audioSourcePath = [[NSBundle mainBundle] pathForResource:@"MP3_Sample" ofType:@"mp3"];
    file = [[AVAudioFile alloc]initForReading:[NSURL URLWithString:audioSourcePath] error:&error];
    
    //Create Engine & Node
    engine = [[AVAudioEngine alloc] init];
    player = [[AVAudioPlayerNode alloc] init];
    [engine attachNode:player];
    
    AVAudioMixerNode *mainMixer = [engine mainMixerNode];
    [engine connect:player to:mainMixer format:file.processingFormat];  //Connect two Nodes
    
    [engine startAndReturnError:&error];    //Starts Audio Engine
}

- (IBAction)playAudio:(id)sender {
    [player scheduleFile:file atTime:nil completionHandler:nil];
    
    //Set up Player(Buffer)
    /*
    AVAudioPCMBuffer *buffer = ...
    AVAudioMixerNode *mainMixer = [engine mainMixerNode];
    [engine connect:player to:mainMixer format:buffer.format]
     
    [player scheduleBuffer:buffer atTime:nil options:nil completionHandler:nil];
    */
    
    //Start Engine & Play
    [player play];
}


@end
