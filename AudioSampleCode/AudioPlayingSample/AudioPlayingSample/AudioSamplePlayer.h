//
//  AudioSamplePlayer.h
//  AudioPlayingSample
//
//  Created by HanGyo Jeong on 11/11/2019.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//

/*
 12 steps you need to not only play audio samples but get the most out of OpenAL
 
 1. Set up an Audio Session
 2. Open a device
 3. Create and activate a context
 4. Generate sound sources
 5. Manage a collection of sources
 6. Open your audio data files
 7. Transfer your audio data to a buffer
 8. Generate data buffers
 9. Manage a collection of data buffers
 10. Attach a buffer to a sound source
 11. Play the audio sample
 12. Clean up and shutdown OpenAL
 */
#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#include <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioSamplePlayer : NSObject

- (void)playSound;

@end

NS_ASSUME_NONNULL_END
