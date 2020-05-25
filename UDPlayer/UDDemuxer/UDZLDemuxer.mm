//
//  UDZLDemuxer.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/5/6.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDZLDemuxer.h"

#import "Player/MediaPlayer.h"
#import "Poller/EventPoller.h"
#import "UDMacro.h"
#import "UDZLDemuxerFrame.h"
#import "UDVideoDecoder.h"
#import "UDUtils.h"

#include <iostream>
using namespace std;
using namespace toolkit;
using namespace mediakit;

@interface UDZLDemuxer ()

@property (nonatomic, strong) NSString  *currentUrl;

@end

@implementation UDZLDemuxer
{
    MediaPlayer::Ptr    _demuxer;
}

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _demuxer = std::make_shared<MediaPlayer>();
        
        [self setOnShutdownCallback];
    }
    return self;
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self disponse];
}

#pragma mark - Public

- (void)setOption:(NSString *)key stringValue:(NSString *)value
{
    if (!key || !value) return;
    
    auto demux = _demuxer;
    string key_str([key UTF8String]), val_str([value UTF8String]);
    
    demux->getPoller()->async([key_str,val_str,demux](){
        //切换线程后再操作
        (*demux)[key_str] = val_str;
    });
}

- (void)setOption:(NSString *)key intValue:(int)value {
    [self setOption:key stringValue:[@(value) stringValue]];
}

- (void)start:(NSString *)url
{
    _currentUrl = url;
    
    [self setOnResultCallback];
    
    _demuxer->play([_currentUrl UTF8String]);
}

- (void)disponse
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---disponse---");
    
    if (_delegate) {
        _delegate = nil;
    }
    
    if (_demuxer) {
//        _demuxer->teardown();
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
    auto track = dynamic_pointer_cast<VideoTrack>(_demuxer->getTrack(TrackVideo));
    return track ? (UDCodecId)track->getCodecId() : UDCodecInvalid;
}

- (double)getVideoWidth
{
    auto track = dynamic_pointer_cast<VideoTrack>(_demuxer->getTrack(TrackVideo));
    return track ? (double)track->getVideoWidth() : 0.0;
}

- (double)getVideoHeight
{
    auto track = dynamic_pointer_cast<VideoTrack>(_demuxer->getTrack(TrackVideo));
    return track ? (double)track->getVideoHeight() : 0.0;
}

- (int)getVideoFps
{
    auto track = dynamic_pointer_cast<VideoTrack>(_demuxer->getTrack(TrackVideo));
    return track ? track->getVideoFps() : 0;
}

- (UDCodecId)getAudioCodecId
{
    auto track = dynamic_pointer_cast<AudioTrack>(_demuxer->getTrack(TrackAudio));
    return track ? (UDCodecId)track->getCodecId() : UDCodecInvalid;
}

- (int)getAudioSamplerate
{
    auto track = dynamic_pointer_cast<AudioTrack>(_demuxer->getTrack(TrackAudio));
    return track ? track->getAudioSampleRate() : 0;
}

- (int)getAudioBit
{
    auto track = dynamic_pointer_cast<AudioTrack>(_demuxer->getTrack(TrackAudio));
    return track ? track->getAudioSampleBit() : 0;
}

- (int)getAudioChannel
{
    auto track = dynamic_pointer_cast<AudioTrack>(_demuxer->getTrack(TrackAudio));
    return track ? track->getAudioChannel() : 0;
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
    if ([self.delegate respondsToSelector:@selector(demuxer:onDexumerSuccess:)]) {
        [self.delegate demuxer:self onDexumerSuccess:NULL];
    }
}

- (void)onDemuxerErrorCallback:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(demuxer:onError:userData:)]) {
        [self.delegate demuxer:self onError:error userData:NULL];
    }
}

- (void)onDemuxerDataCallback:(const Frame::Ptr &)frame
{
    if ([self.delegate respondsToSelector:@selector(demuxer:onData2:userData:)]) {
        [self.delegate demuxer:self onData2:frame userData:NULL];
    }
}

- (void)onDemuxerShutdownCallback:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(demuxer:onShutdown:userData:)]) {
        [self.delegate demuxer:self onShutdown:error userData:NULL];
    }
}

#pragma mark - Setting Callback

- (void)setOnShutdownCallback
{
    UDWeakify(self)
    
    _demuxer->setOnShutdown([weak_obj](const SockException &ex){
        if (!weak_obj) return;
        
        UDStrongify(weak_obj)
                
        NSError *error = [UDUtils ud_errorWithEx:ex];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strong_obj onDemuxerShutdownCallback:error];
        });
    });
}

- (void)setOnResultCallback
{
    UDWeakify(self)
    
    _demuxer->setOnPlayResult([weak_obj](const SockException &ex){
        if (!weak_obj) return;
        
        UDStrongify(weak_obj)
        
        NSError *error = [UDUtils ud_errorWithEx:ex];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error || error.code == 0) {
                [strong_obj onDemuxerSucessCallback];
            }
            else {
                [strong_obj onDemuxerErrorCallback:error];
            }
        });
        
        if (!error || error.code == 0) {
            [strong_obj setOnDataCallback];
        }
    });
}

- (void)setOnDataCallback
{
    UDWeakify(self)
    
    _demuxer->getPoller()->async([weak_obj](){
        //切换线程后再操作
        if (!weak_obj) return;
        
        UDStrongify(weak_obj);
        
        [strong_obj setOnDataEventCallback];
    });
}

- (void)setOnDataEventCallback
{
    UDWeakify(self)
    
    auto delegate = std::make_shared<FrameWriterInterfaceHelper>([weak_obj](const Frame::Ptr &frame){
        if (!weak_obj) return;

        UDStrongify(weak_obj);

        if (frame->getTrackType() == TrackType::TrackVideo) {
            [strong_obj onDemuxerDataCallback:frame];
        }
        else if (frame->getTrackType() == TrackType::TrackAudio) {

        }
        else if (frame->getTrackType() == TrackType::TrackTitle) {

        }
    });

    for(auto &track : _demuxer->getTracks()){
        track->addDelegate(delegate);
    }
}

@end
