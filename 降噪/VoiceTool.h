//
//  VoiceTool.h
//  ASRDemo
//
//  Created by majianghai on 2019/3/28.
//  Copyright © 2019 cmcm. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

enum nsLevel {
    kLow,
    kModerate,
    kHigh,
    kVeryHigh
};


@interface VoiceTool : NSObject
/// 开始录音
- (void)startRecorder;

/// 结束录音
- (void)cancelRecorder;


/// 播放音频（降噪后的音频是不能直接播放的，需要用VLC播放工具）
- (void)playVoice;


/// 降噪方法
-(int)denoise;

@end

NS_ASSUME_NONNULL_END
