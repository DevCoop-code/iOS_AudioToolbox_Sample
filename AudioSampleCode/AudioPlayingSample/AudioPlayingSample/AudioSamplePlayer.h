//
//  AudioSamplePlayer.h
//  AudioPlayingSample
//
//  Created by HanGyo Jeong on 11/11/2019.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#include <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioSamplePlayer : NSObject

- (void)playSound;

@end

NS_ASSUME_NONNULL_END
