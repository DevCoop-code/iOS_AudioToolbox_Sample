//
//  AudioSamplePlayer.m
//  AudioPlayingSample
//
//  Created by HanGyo Jeong on 11/11/2019.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//

#import "AudioSamplePlayer.h"

@implementation AudioSamplePlayer

/*
 A device is a physical thing that you use to process sound(ex. sound card would be a device)
 */
static ALCdevice *openALDevice;
static ALCcontext *openALContext;

- (id)init
{
    self = [super init];
    if(self)
    {
        //Setting parameter NULL means that setting the default device
        openALDevice = alcOpenDevice(NULL);
        
        //Set up the context
        openALContext = alcCreateContext(openALDevice, NULL);
        alcMakeContextCurrent(openALContext);
    }
    return self;
}

- (void)playSound
{
    //Source is something that produces sound, like a speaker
    //To play a sound, need to specify a source to play it through
    NSUInteger sourceID;
    alGenSources(1, &sourceID);
    
    NSString *audioFilePath = [[NSBundle mainBundle]pathForResource:@"audioFile" ofType:@"caf"];
    NSURL *audioFileURL = [NSURL fileURLWithPath:audioFilePath];
    
    /*
     [AudioFileOpenURL]
     1st parameter : the URL of an existing audio file
     2nd parameter : The read-write permissions you want to assign to the file. Use the permission constants in AudioFilePermissions
     3rd parameter : A hint for the file type of the designated file, For files without filename extensions and with types not easily or uniquely determined from the data(such as ADTS or AC3)
     4th parameter : output, pointer to the newly opened audio file
     
     Audio File Services uses an AudioFileID to reference an audio file. AudioFileOpenURL will open the audio sample and place the data into AudioFileID variable.
     */
    AudioFileID afid;
    OSStatus openAudioFileResult = AudioFileOpenURL((__bridge CFURLRef)audioFileURL, kAudioFileReadPermission, 0, &afid);
    
    if(0 != openAudioFileResult)
    {
        NSLog(@"An error occured when attempting to open the audio file %@: %ld", audioFilePath, openAudioFileResult);
        return;
    }
    
    UInt64 audioDataByteCount = 0;
    UInt32 propertySize = sizeof(audioDataByteCount);
    /*
     [AudioFileGetProperty]
     Gets the value of an audio file property
     1st parameter : The audio file you want to obtain a property value from
     2nd parameter : The property whose value you want(https://developer.apple.com/documentation/audiotoolbox/1576499-audio_file_properties?language=objc)
     3rd parameter : output the number of bytes written to the buffer
     4th parameter : output the value of the property specified in 3rd parameter
     */
    //AudioFileGetProperty will query the audio file and extract the property we are searching for the audio data
    //kAudioFilePropertyAudioDataByteCount : Indicates the number of bytes of audio data in the designated file.
    OSStatus getSizeResult = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &propertySize, &audioDataByteCount);
    if(0 != getSizeResult)
    {
        NSLog(@"An error occured when attempting to determine the size of audio file %@: %ld", audioFilePath, getSizeResult);
    }
    
    UInt32 bytesRead = (UInt32)audioDataByteCount;
    
    void *audioData = malloc(bytesRead);
    /*
     [AudioFileReadBytes]
     Reads bytes of audio data from an audio file
     1st parameter : The audio file whose bytes of audio data you want to read
     2nd parameter : True => Cache the Data
     3rd parameter : byte offset of the audio data you want to be returned
     4th parameter : Input => pointer to the number of bytes to read / Output => pointer to the number of bytes actually read
     5th parameter : pointer to user-allocated memory large enough for the requested bytes
     */
    OSStatus readBytesResult = AudioFileReadBytes(afid, false, 0, &bytesRead, audioData);
    if(0 != readBytesResult)
    {
        NSLog(@"An error occured when attempting to read data from audio file %@: %ld", audioFilePath, readBytesResult);
    }
    AudioFileClose(afid);
    
    ALuint outputBuffer;
    alGenBuffers(1, &outputBuffer);
    
    /*
     [alBufferData]
     This function fills a buffer with audio data.
     1st parameter : Buffer name to be filled with data
     2nd parameter : format type(AL_FORMAT_MONO8, AL_FORMAT_MONO16, AL_FORMAT_STEREO8, AL_FORMAT_STEREO16)
     3rd parameter : pointer to the audio data
     4th parameter : the size of the audio data in bytes
     5th parameter : frequency of the audio data
     */
    alBufferData(outputBuffer, AL_FORMAT_STEREO16, audioData, bytesRead, 44100);
    if(audioData)
    {
        free(audioData);
        audioData = NULL;
    }
    
    //Set some parameters
    alSourcef(sourceID, AL_PITCH, 1.0f);
    alSourcef(sourceID, AL_GAIN, 1.0f);
    
    //Attach the buffer
    alSourcei(sourceID, AL_BUFFER, outputBuffer);
    
    //Passing in our sourceID to play our audio sample
    alSourcePlay(sourceID);
}

@end
