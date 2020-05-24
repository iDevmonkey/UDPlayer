//
//  UDRTXPDemuxer.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDRTXPDemuxer.h"
#import "UDMacro.h"
#import "UDUtils.h"
#import "UDZLDemuxerFrame.h"

#include "mk_player.h"

@implementation UDRTXPDemuxer
{
    mk_player _demuxer;
}

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _demuxer = mk_player_create();
    }
    return self;
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self disponse];
}

#pragma mark - Public

- (void)setOption:(NSString *)key value:(NSObject *)value
{
    if (!key || !value) return;
    
    if ([value isKindOfClass:[NSString class]]) {
        mk_player_set_option(_demuxer, [key UTF8String], [(NSString *)value UTF8String]);
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        mk_player_set_option(_demuxer, [key UTF8String], [[(NSNumber *)value stringValue] UTF8String]);
    }
}

- (void)start:(NSString *)url
{
    UDWeakify(self);
    
    mk_player_set_on_result(_demuxer, on_mk_play_result_callback, (__bridge void *)(weak_obj));
    mk_player_set_on_shutdown(_demuxer, on_mk_play_shutdown_callback, (__bridge void *)(weak_obj));
    mk_player_play(_demuxer, [url UTF8String]);
}

- (void)disponse
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---disponse---");
    
    if (_demuxer) {
        mk_player_release(_demuxer);
        _demuxer = NULL;
    }
}

/*
 * 点播相关
 
- (void)pause
{
    mk_player_pause(_demuxer, 1);
}

- (void)resume
{
    mk_player_pause(_demuxer, 0);
}

- (void)seekTo:(float)progress
{
    mk_player_seekto(_demuxer, progress);
}
 
 */

- (UDCodecId)getVideoCodecId
{
//    return mk_player_video_codecId(_demuxer);
    return UDCodecInvalid;
}

- (double)getVideoWidth
{
    return (double)mk_player_video_width(_demuxer);
}

- (double)getVideoHeight
{
    return (double)mk_player_video_height(_demuxer);
}

- (int)getVideoFps
{
    return mk_player_video_fps(_demuxer);
}

- (UDCodecId)getAudioCodecId
{
//    return mk_player_audio_codecId(_demuxer);
    return UDCodecInvalid;
}

- (int)getAudioSamplerate
{
    return mk_player_audio_samplerate(_demuxer);
}

- (int)getAudioBit
{
    return mk_player_audio_bit(_demuxer);
}

- (int)getAudioChannel
{
    return mk_player_audio_channel(_demuxer);
}

/*
* 点播相关

- (float)getDuration
{
    return mk_player_duration(_demuxer);
}

- (float)getProgress
{
    return mk_player_progress(_demuxer);
}

*/

#pragma mark - Callback

- (void)onDemuxerSucessCallback
{
    UDWeakify(self);
    
    if ([self.delegate respondsToSelector:@selector(demuxer:onDexumerSuccess:)]) {
        [self.delegate demuxer:self onDexumerSuccess:NULL];
    }
    
    mk_player_set_on_data(_demuxer, on_mk_play_data_callback, (__bridge void *)(weak_obj));
}

- (void)onDemuxerErrorCallback:(int)err_code message:(const char *)err_msg
{
    NSError *error = [UDUtils ud_errorWithCode:err_code message:[NSString stringWithUTF8String:err_msg]];
    
    if ([self.delegate respondsToSelector:@selector(demuxer:onError:userData:)]) {
        [self.delegate demuxer:self onError:error userData:NULL];
    }
}

- (void)onDemuxerDataCallback:(UDDemuxerFrame *)demuxerFrame
{
    if ([self.delegate respondsToSelector:@selector(demuxer:onData:userData:)]) {
        [self.delegate demuxer:self onData:demuxerFrame userData:NULL];
    }
}

- (void)onDemuxerShutdownCallback:(int)err_code message:(const char *)err_msg
{
    NSError *error = [UDUtils ud_errorWithCode:err_code message:[NSString stringWithUTF8String:err_msg]];
    
    if ([self.delegate respondsToSelector:@selector(demuxer:onShutdown:userData:)]) {
        [self.delegate demuxer:self onShutdown:error userData:NULL];
    }
}

#pragma mark - C Callback

void on_mk_play_result_callback(void *user_data,int err_code,const char *err_msg)
{
    __strong UDRTXPDemuxer *strong_obj = (__bridge UDRTXPDemuxer *)user_data;
        
    if (err_code == 0) {
        [strong_obj onDemuxerSucessCallback];
    }
    else {
        [strong_obj onDemuxerErrorCallback:err_code message:err_msg];
    }
}

void on_mk_play_data_callback(void *user_data,int track_tycpe,int codec_id,void *data,int len,uint32_t dts,uint32_t pts)
{
    __strong UDRTXPDemuxer *strong_obj = (__bridge UDRTXPDemuxer *)user_data;
    
    UDZLDemuxerFrame *frame = [[UDZLDemuxerFrame alloc] initWithData:data len:len trackType:track_tycpe codecId:codec_id dts:dts pts:pts];
    [strong_obj onDemuxerDataCallback:frame];
}

void on_mk_play_shutdown_callback(void *user_data,int err_code,const char *err_msg)
{
    __strong UDRTXPDemuxer *strong_obj = (__bridge UDRTXPDemuxer *)user_data;
    
    [strong_obj onDemuxerShutdownCallback:err_code message:err_msg];
}

@end
