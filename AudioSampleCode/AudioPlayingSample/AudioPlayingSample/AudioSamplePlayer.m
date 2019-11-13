//
//  AudioSamplePlayer.m
//  AudioPlayingSample
//
//  Created by HanGyo Jeong on 11/11/2019.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//

#import "AudioSamplePlayer.h"

#define kMaxConcurrentSources 32
#define kMaxBuffers 256

@implementation AudioSamplePlayer

/*
 A device is a physical thing that you use to process sound(ex. sound card would be a device)
 */
static ALCdevice *openALDevice;
static ALCcontext *openALContext;

static NSMutableArray *audioSampleSources;
static NSMutableDictionary *audioSampleBuffers; //To Store buffers so that we can provide a key and get the related buffer ID(key is the audio sample)

- (id)init
{
    self = [super init];
    if(self)
    {
        /*
         [AudioSessionInitialize]
         Initializes an iOS application's audio session object
         1st parameter : run loop that interruption listener callback
         2nd parameter : run loop that interruption listener function will run on
         3rd parameter : interruption listener callback function. The application's audio session object invokes the callback when the session is interrupted and when the interruption ends
         4th parameter : Data what you would like to be passed to your interruption listener callback
         */
        AudioSessionInitialize(NULL, NULL, AudioInterruptionListenerCallback, NULL);
        
        UInt32 session_category = kAudioSessionCategory_MediaPlayback;
        
        //Set the value of a specified audio session property
        AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(session_category), &session_category);
        
        AudioSessionSetActive(true);
        
        //Setting parameter NULL means that setting the default device
        openALDevice = alcOpenDevice(NULL);
        
        //Set up the context
        openALContext = alcCreateContext(openALDevice, NULL);
        alcMakeContextCurrent(openALContext);
        
        NSUInteger sourceID;
        for(int i = 0; i < kMaxConcurrentSources; i++)
        {
            //Create a single OpenAL source
            alGenSources(1, &sourceID);
            //Add the source to the audioSampleSources Array
            [audioSampleSources addObject:[NSNumber numberWithUnsignedInt:sourceID]];
        }
    }
    return self;
}

void AudioInterruptionListenerCallback(void* user_data, UInt32 interruption_state)
{
    if(kAudioSessionBeginInterruption == interruption_state)    //what we do when our app is interrupted
    {
        alcMakeContextCurrent(NULL);
    }
    else if(kAudioSessionEndInterruption == interruption_state) //what we do when our app is relaunched
    {
        //When app is interrupted, Audio Session will automatically deactivated(No need to setActive false) so when the interrupted ended, we need to setactive true
        AudioSessionSetActive(true);
        alcMakeContextCurrent(openALContext);
    }
}

- (void)preloadAudioSample:(NSString *)sampleName
{
    if([audioSampleBuffers objectForKey:sampleName])
    {
        return;
    }
    if([audioSampleBuffers count] > kMaxBuffers)
    {
        NSLog(@"Warning: You are trying to create more than 256 buffers! This is not allowed now");
        return;
    }
    
    NSString *audioFilePath = [[NSBundle mainBundle]pathForResource:sampleName ofType:@"caf"];
    
    AudioFileID afid = [self openAudioFile:audioFilePath];
    UInt32 audioFileSizeInBytes = [self getSizeOfAudioComponent:afid];
    
    void *audioData = malloc(audioFileSizeInBytes);
    
    OSStatus readBytesResult = AudioFileReadBytes(afid, false, 0, &audioFileSizeInBytes, audioData);
    
    if(0 != readBytesResult)
    {
        NSLog(@"An error occured when attempting to read data from audio file %@: %ld", audioFilePath, readBytesResult);
    }
    
    AudioFileClose(afid);
    
    ALuint outputBuffer;
    alGenBuffers(1, &outputBuffer);
    
    alBufferData(outputBuffer, AL_FORMAT_STEREO16, audioData, audioFileSizeInBytes, 44100);
    
    [audioSampleBuffers setObject:[NSNumber numberWithInt:outputBuffer] forKey:sampleName];
    
    if(audioData)
    {
        free(audioData);
        audioData = NULL;
    }
}

/*
 Takes a file path as a string, opens the audio sample and returns the AudioFileID
 */
- (AudioFileID)openAudioFile:(NSString *)audioFilePathAsString
{
    NSURL *audioFileURL = [NSURL fileURLWithPath:audioFilePathAsString];
    
    AudioFileID afid;
    OSStatus openAudioFileResult = AudioFileOpenURL((__bridge CFURLRef)audioFileURL, kAudioFileReadPermission, 0, &afid);
    if(0 != openAudioFileResult)
    {
        NSLog(@"An error occured when attempting to open the audio file %@: %ld", audioFilePathAsString, openAudioFileResult);
    }
    return afid;
}

/*
 Takes an AudioFileID and returns the size of the audio data as a UInt32
 */
- (UInt32)getSizeOfAudioComponent:(AudioFileID)afid
{
    UInt64 audioDataSize = 0;
    UInt32 propertySize = sizeof(UInt64);
    
    OSStatus getSizeResult = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &propertySize, &audioDataSize);
    if(0 != getSizeResult)
    {
        NSLog(@"An error occured when attempting to determine the size of audio file");
    }
    return (UInt32)audioDataSize;
}

/*
 Attach a buffer to a sound source
 Play the audio Sample
 */
- (void)playAudioSample:(NSString *)sampleName
{
    ALuint source = [self getNextAvailableSource];
    
    alSourcef(source, AL_PITCH, 1.0f);
    alSourcef(source, AL_GAIN, 1.0f);
    
    ALuint outputBuffer = (ALuint)[[audioSampleBuffers objectForKey:sampleName] intValue];
    
    alSourcei(source, AL_BUFFER, outputBuffer);
    
    alSourcePlay(source);
}

- (ALuint)getNextAvailableSource
{
    ALint sourceState;
    for(NSNumber *sourceID in audioSampleSources)
    {
        alGetSourcei([sourceID unsignedIntValue], AL_SOURCE_STATE, &sourceState);
        if(sourceState != AL_PLAYING)
        {
            return [sourceID unsignedIntValue];
        }
    }
    
    ALuint sourceID = [[audioSampleSources objectAtIndex:0] unsignedIntegerValue];
    alSourceStop(sourceID);
    
    return sourceID;
}

/*
 Clean up and shutdown OpenAL
 */
- (void)shutdownAudioSamplePlayer
{
    ALint source;
    for(NSNumber *sourceValue in audioSampleSources)
    {
        NSUInteger sourceID = [sourceValue unsignedIntValue];
        alGetSourcei(sourceID, AL_SOURCE_STATE, &source);
        alSourceStop(sourceID);
        alDeleteSources(1, &sourceID);
    }
    [audioSampleSources removeAllObjects];
    
    NSArray *bufferIDs = [audioSampleBuffers allValues];
    for(NSNumber *bufferValue in bufferIDs)
    {
        NSUInteger bufferID = [bufferValue unsignedIntValue];
        alDeleteBuffers(1, &bufferID);
    }
    [audioSampleBuffers removeAllObjects];
    
    alcDestroyContext(openALContext);
    alcCloseDevice(openALDevice);
}
@end
