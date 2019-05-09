//
//  VoiceTool.m
//  ASRDemo
//
//  Created by majianghai on 2019/3/28.
//  Copyright © 2019 cmcm. All rights reserved.
//

#import "VoiceTool.h"
#import <AVFoundation/AVFoundation.h>
#include "noise_suppression.h"

#define VOICE_RATE 16000
#define VOICE_RATE_UNIT 160

//#define VOICE_RATE 8000
//#define VOICE_RATE_UNIT 80


#ifndef nullptr
#define nullptr 0
#endif

@interface VoiceTool ()
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation VoiceTool


+ (NSString *)filePath {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)lastObject];
    
    NSString *filePa = [NSString stringWithFormat:@"%@/voice.pcm",docPath];
    
    return  filePa;
}


- (void)startRecorder {
    
    AVAudioSession * session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    if (session == nil) {
    }else{
        [session setActive:YES error:nil];
    }
    
    //录音设置
    NSMutableDictionary * recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式
    [recordSetting  setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率（HZ）
    [recordSetting setValue:[NSNumber numberWithFloat:VOICE_RATE] forKey:AVSampleRateKey];
    //录音通道数
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数
    [recordSetting  setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting  setValue:[NSNumber numberWithInt:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)lastObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:docPath]) {
        [fileManager createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSURL * url = [NSURL fileURLWithPath:[VoiceTool filePath]];//voice.aac
    NSError *error;
    //初始化AVAudioRecorder
    if(!self.recorder){
        self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&error];
        //开启音量监测
        self.recorder.meteringEnabled = YES;
    }
    
    if(error){
        NSLog(@"创建录音对象时发生错误，错误信息：%@",error.localizedDescription);
    }
    
    [self.recorder record];
}

- (void)cancelRecorder {
    [self.recorder stop];
}


- (void)playVoice {
    NSURL * url = [NSURL fileURLWithPath:[VoiceTool filePath]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    self.player = [[AVAudioPlayer alloc] initWithData:data error:nil];
    [self.player prepareToPlay];
    [self.player play];
}


+ (int)voiceLength {
    
    NSString *filePath = [VoiceTool filePath];

    NSURL *url = [NSURL fileURLWithPath:filePath];
    
    NSData *data = [NSData dataWithContentsOfURL:url];

    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithData:data error:nil];
    
    float duration = player.duration;

    float lengMs = duration * 1000;

    int len = lengMs / 10 * VOICE_RATE_UNIT;
    
    return len;
}


-(int)denoise {
    
    NSString *filePath = [VoiceTool filePath];
    NSData *sourceData = [NSData dataWithContentsOfFile:filePath];
    int16_t *buffer = (int16_t *)[sourceData bytes];
    
    
    uint32_t sampleRate = VOICE_RATE;
    int samplesCount = [VoiceTool voiceLength];
    int level = kLow;
    
    if (buffer == nullptr) return -1;
    if (samplesCount == 0) return -1;
    size_t samples = MIN(VOICE_RATE_UNIT, sampleRate / 100);
    if (samples == 0) return -1;
    uint32_t num_bands = 1;
    int16_t *input = buffer;
    size_t nTotal = (samplesCount / samples);
    NsHandle *nsHandle = WebRtcNs_Create();
    int status = WebRtcNs_Init(nsHandle, sampleRate);
    if (status != 0) {
        printf("WebRtcNs_Init fail\n");
        return -1;
    }
    status = WebRtcNs_set_policy(nsHandle, level);
    if (status != 0) {
        printf("WebRtcNs_set_policy fail\n");
        return -1;
    }
    for (int i = 0; i < nTotal; i++) {
        int16_t *nsIn[1] = {input};   //ns input[band][data]
        int16_t *nsOut[1] = {input};  //ns output[band][data]
        WebRtcNs_Analyze(nsHandle, nsIn[0]);
        WebRtcNs_Process(nsHandle, (const int16_t *const *) nsIn, num_bands, nsOut);
        input += samples;
    }
    WebRtcNs_Free(nsHandle);
    
    NSData *data = [NSData dataWithBytes:buffer length:[sourceData length]];
    BOOL isWrite = [data writeToFile:filePath atomically:YES];
    if (isWrite) {
        NSLog(@"----写入成功");
    }
    
    return 1;
}



@end
