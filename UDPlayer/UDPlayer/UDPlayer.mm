//
//  UDPlayer.m
//  UDPlayer
//
//  Created by CHEN on 2020/6/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDPlayer.h"

#include <iostream>
#import "Player/MediaPlayer.h"
#import "Util/TimeTicker.h"
#import "Util/RingBuffer.h"

#import "UDMacro.h"
#import "UDZLDemuxerFrame.h"
#import "UDZLAudioDemuxerFrame.h"
#import "UDVideoDecoder.h"
#import "MediaDecoder.h"
#import "UDZLDemuxer.h"
#import "UDRenderView.h"
#import "GLView.h"
#import "UDGCDTimer.h"
#import "UDPlayerItem.h"
#import "UDRTXPDemuxer.h"

#import "UDAudioPlayer.h"
#import "AudioDec.h"

using namespace std;
using namespace toolkit;
using namespace mediakit;

#define PCM_BUF_SIZE (1024*4)
#define UD_MAX_BUFFER_IN_MS (400)

@interface UDPlayer ()<UDVideoDecoderDelegate, UDDemuxerDelegate, UDAudioPlayerDelegate>

@property (nonatomic, strong) UDZLDemuxer               *demuxer;

@property (nonatomic, strong) NSObject<IUDVideoDecoder> *decoder;

@property (nonatomic, strong) UDAudioPlayer             *audioPlayer;

@property (nonatomic, strong) NSString                  *arg_url;

//@property (nonatomic, strong) CADisplayLink             *displayLink;

@property (nonatomic, weak) UIView                      *convasView;

@property (nonatomic, strong) UIView<IUDRenderView>     *renderView;

@property (nonatomic, strong) UDGCDTimer                *timer;

@property (nonatomic, strong) UDPlayerItem              *playerItem;

@property (nonatomic, assign) BOOL                      starting;

@property (nonatomic, strong) UDRenderFrame             *renderFrame;
@property (nonatomic, strong) UDZLAudioDemuxerFrame     *audioFrame;

@end

@implementation UDPlayer
{
    BOOL _aspectFit;
    UDRenderMode _renderMode;
    
    shared_ptr<AudioDec> _aacDec;
}

@synthesize delegate = _delegate;

- (instancetype)initWithConvas:(UIView *)convasView
{
    self = [super init];
    if (self) {
        _convasView = convasView;
        
        _demuxer = [[UDZLDemuxer alloc] init];
        _demuxer.delegate = self;
        
        _playerItem = [[UDPlayerItem alloc] init];
        
        _aspectFit = YES;
        _renderMode = UDRenderModeNormal;
        
        _starting = NO;
                
        [self createDisplayLink];
//
//        if(![UIApplication sharedApplication].idleTimerDisabled){
//            [UIApplication sharedApplication].idleTimerDisabled = true;
//        }
    }
    
    return self;
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self dispose];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if([UIApplication sharedApplication].idleTimerDisabled){
//            [UIApplication sharedApplication].idleTimerDisabled = false;
//        }
//    });
}

#pragma mark - Public

- (void)play:(NSString *)url
{
    _arg_url = url;
        
    [_demuxer start:url];
}

- (void)rePlay
{
    if(_arg_url)
    {
        [self play:_arg_url];
    }
}

- (void)dispose
{
    [self cleanDidplayLink];
    
    if (_demuxer) {
        _demuxer.delegate = nil;
        [_demuxer disponse];
        _demuxer = nil;
    }
    
    if (_decoder) {
        _decoder.delegate = nil;
        _decoder = nil;
    }
    
    if (_renderView) {
        [_renderView disponse];
        _renderView = nil;
    }
    
    if (_aacDec) {
        _aacDec.reset();
        _aacDec = NULL;
    }
    
    if (_audioPlayer) {
        [_audioPlayer StopPlay];
        _audioPlayer = nil;
    }
}

#pragma mark - Private

- (void)createDisplayLink
{
//    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
//    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [self startDisplayLink];
    
    double timeinterval = 1.0 / 60.0;

    UDWeakify(self)

    _timer = [UDGCDTimer ud_scheduledTimerWithTimeInterval:timeinterval block:^(UDGCDTimer *timer) {

        UDStrongify(weak_obj);

        [strong_obj displayLinkCallbac];

    } repeats:YES];
}

- (void)cleanDidplayLink
{
//    if (self.displayLink) {
//        [self stopDisplayLink];
//        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//        self.displayLink = nil;
//    }
    
//    if (_timer) {
//        [_timer invalidate];
//        _timer = nil;
//    }
}

- (void)startDisplayLink
{
//    [self.displayLink setPaused:NO];
}

- (void)stopDisplayLink
{
//    [self.displayLink setPaused:YES];
}

#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
}

- (void)displayLinkCallbac
{
    if (!_starting) {
        return;
    }
    
    [self onDrawFrame];
}

#pragma mark - Demuxer Delegate

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onDexumerSuccess:(void *)userData
{
    UDWeakify(self)
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UDStrongify(weak_obj)
        
        if([strong_obj.delegate respondsToSelector:@selector(player:onPlayRusult:)]){
            [strong_obj.delegate player:strong_obj onPlayRusult:nil];
        }
    });
}

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onShutdown:(NSError *)error userData:(void *)userData
{
    UDWeakify(self)
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UDStrongify(weak_obj)
        
        if([strong_obj.delegate respondsToSelector:@selector(player:onShutdown:)]){
            [strong_obj.delegate player:strong_obj onShutdown:error];
        }
    });
}

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onError:(NSError *)error userData:(void *)userData
{
    UDWeakify(self)
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UDStrongify(weak_obj)
        
        if([strong_obj.delegate respondsToSelector:@selector(player:onPlayRusult:)]){
            [strong_obj.delegate player:strong_obj onPlayRusult:error];
        }
    });
}

//- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onData:(UDDemuxerFrame *)demuxerFrame userData:(void *)userData
//{
//    [self onDecodeForFrame:demuxerFrame];
//}

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onData2:(const Frame::Ptr &)frame userData:(void *)userData
{
    UDZLDemuxerFrame *demuxerFrame = [[UDZLDemuxerFrame alloc] initWithFrame:frame];
    [self onDecodeForFrame:demuxerFrame];
}

//- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onData3:(UDRTXPDEmuxerFrame)frame userData:(void *)userData
//{
//    UDZLDemuxerFrame *demuxerFrame = [[UDZLDemuxerFrame alloc] initWithFrame_:frame];
//    [self onDecodeForFrame:demuxerFrame];
//}

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onAudioData:(const Frame::Ptr &)frame userData:(void *)userData
{
    UDZLAudioDemuxerFrame *demuxerFrame = [[UDZLAudioDemuxerFrame alloc] initWithFrame:frame];
    [self onAudioForFrame:demuxerFrame];
}

#pragma mark - Decode Delegate

- (void)onDecoded:(UDRenderFrame *)renderFrame isFirstFrame:(BOOL)isFirstFrame
{
//    UDWeakify(self)
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//            UDStrongify(weak_obj);
//
//            [strong_obj.renderView drawFrame:renderFrame];
//
//    //        [self.renderView drawFrame:renderFrame];
//        });
//
        
    UDWeakify(self)

    dispatch_async(dispatch_get_main_queue(), ^{

        UDStrongify(weak_obj);

        [strong_obj.playerItem addVideoFrame:renderFrame];

        strong_obj.starting = YES;

    });
    
//    UDWeakify(self)
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        UDStrongify(weak_obj);
//
//        [strong_obj.playerItem addPlayerItemValidFrames:renderFrame];
//
//        strong_obj.starting = YES;
//
//    });
    
    
//    uint32_t pts = (uint32_t)(CMTimeGetSeconds(renderFrame.pts) * 1000);
//
//    lock_guard<recursive_mutex> lck(_mtx_mapYuv);
//    _mapYuv.emplace(pts,renderFrame);
//    if (_mapYuv.rbegin()->second.ptsInt - _mapYuv.begin()->second.ptsInt >  UD_MAX_BUFFER_IN_MS) {
//        _mapYuv.erase(_mapYuv.begin());
//    }
//
//    if (!_firstVideoStamp) {
//        _firstVideoStamp = pts;
//
//        _starting = YES;
//
//        [self startDisplayLink];
//    }
}

#pragma mark - Decode

- (void)onDecodeForFrame:(UDDemuxerFrame *)demuxerFrame
{
    if (!_decoder && demuxerFrame.keyFrame) {
        _decoder = [[MediaDecoder alloc] init];
        _decoder.delegate = self;
    }
    
    if (_decoder) {
//        udlog_info("decode", "naleType: %d, pts: %d, dts:%d", demuxerFrame.naleType,demuxerFrame.pts, demuxerFrame.dts);
        
        [_decoder startDecodeFrame:demuxerFrame];
    }
}

#pragma mask - Draw

- (void)onDrawFrame
{
    UDWeakify(self)

    dispatch_async(dispatch_get_main_queue(), ^{

        UDStrongify(weak_obj)

        UDRenderFrame *frame = [strong_obj.playerItem getVideoFrame];

        if (frame) {
            [strong_obj.playerItem removeVideoFrame:frame];
            [strong_obj.renderView drawFrame:frame];
        }
    });
    
    
//    UDWeakify(self)
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        UDStrongify(weak_obj)
//
//        UDRenderFrame *frame = [strong_obj.playerItem getNextPlayerItemValidFrames];
//
//        if (frame) {
//            [strong_obj.playerItem removePlayerItemValidFrames:frame];
//            [strong_obj.renderView drawFrame:frame];
//        }
//    });
}

#pragma mark - Audio

- (void)onAudioForFrame:(UDDemuxerFrame *)demuxerFrame
{
//    if (_audioContext == NULL) {
//        _audioContext = faad_decoder_create(_demuxer.getAudioSamplerate, _demuxer.getAudioChannel, _demuxer.getAudioBit);
//    }
//
//    unsigned char *pcm;
//    unsigned int pcm_len;
//    int res = faad_decode_frame(_audioContext, (unsigned char *)[demuxerFrame data], (int)[demuxerFrame dataSize], pcm, &pcm_len);
//
//    if (res == 0 && pcm_len > 0) {
//        [self.playerItem addPlayerItemValidAudioFrames:[[UDZLAudioDemuxerFrame alloc] initWithData:pcm len:pcm_len trackType:demuxerFrame.trackType codecId:demuxerFrame.codecId]];
//
//        [self onDecodeAudio];
//    }
    
    
    
//    if (!_audioDecoder) {
//        _audioDecoder = [[UDAudioDecoder alloc] initWithPCMSampleRate:_demuxer.getAudioSamplerate];
//    }
//
//    if (_audioDecoder) {
//        UDWeakify(self);
//
//        [_audioDecoder decodeAudioWithSourceBuffer:[demuxerFrame data] sourceBufferSize:[demuxerFrame dataSize] completeHandler:^(AudioBufferList * _Nonnull destBufferList, UInt32 outputPackets, AudioStreamPacketDescription * _Nonnull outputPacketDescriptions) {
//            UDStrongify(weak_obj)
//
//            [strong_obj.playerItem addPlayerItemValidAudioFrames:[[UDZLAudioDemuxerFrame alloc] initWithData:destBufferList->mBuffers[0].mData len:destBufferList->mBuffers[0].mDataByteSize trackType:demuxerFrame.trackType codecId:demuxerFrame.codecId]];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                [strong_obj onDecodeAudio];
//            });
//        }];
//    }
    
    
    if (!_aacDec) {
        _aacDec.reset(new AudioDec());
        _aacDec->Init([demuxerFrame data], 7);
    }
    
    uint8_t *pcm;
    int pcmLen = _aacDec->InputData(&[demuxerFrame data][7], [demuxerFrame dataSize] - 7, &pcm);

    if (pcmLen > 0) {
        UDZLAudioDemuxerFrame *frame = [[UDZLAudioDemuxerFrame alloc] initWithData:pcm len:pcmLen trackType:demuxerFrame.trackType codecId:demuxerFrame.codecId];
        [_playerItem addAudioFrame:frame];

        [self onDecodeAudio];
    }
}

- (void)onDecodeAudio {
    if (!_audioPlayer) {
        _audioPlayer = [[UDAudioPlayer alloc] init];
        _audioPlayer.delegate = self;
    }
    
    if (_audioPlayer) {
        if (!_audioPlayer.isPlaying) {
            [_audioPlayer StartPlay];
        }
    }
}

#pragma mark - UDAudioPlayer Delegate

- (AudioFormatID)getAudioFormatID {
    return kAudioFormatLinearPCM;
}

-(int)getAudioBufferSize{
    return PCM_BUF_SIZE;
}
-(int)getAudioSampleBit{
    return _demuxer.getAudioBit;
}
-(int)getAudioSampleRate{
    return _demuxer.getAudioSamplerate;
}
-(int)getAudioChannel{
    return  _demuxer.getAudioChannel;
}
-(int)ReadData:(char *)buf Size:(int)bufsize{
    UDDemuxerFrame *frame = [_playerItem getAudioFrame];
    
    if (frame) {
        [_playerItem removeAudioFrame:frame];
        if ([frame dataSize] > 0) {
            memcpy(buf, [frame data], [frame dataSize]);
            return (int)[frame dataSize];
        }
    }
    
    return 0;
}

#pragma mark - Getter & Setter

- (UIView<IUDRenderView> *)renderView {
    if (_renderView == nil) {
        _renderView = [[UDRenderView alloc] initWithFrame:_convasView.bounds renderMode:_renderMode];
        [_convasView insertSubview:_renderView atIndex:0];
    }
    
    [_renderView setAspectFit:_aspectFit];
    
    return _renderView;
}

- (void)setOption:(NSString *)key stringValue:(NSString *)value
{
    [_demuxer setOption:key stringValue:value];
}

- (void)setOption:(NSString *)key intValue:(int)value
{
    if ([key isEqualToString:@"render_mode"]) {
        int v = MIN(MAX(0, value), 3);
        _renderMode = (UDRenderMode)v;
        return;
    }
    
    [_demuxer setOption:key intValue:value];
}

- (double)getVideoWidth
{
    return _demuxer.getVideoWidth;
}

- (double)getVideoHeight
{
    return _demuxer.getVideoHeight;
}

- (int)getVideoFps
{
    return _demuxer.getVideoFps;
}

- (void)setAspectFit:(BOOL)aspectFit
{
    _aspectFit = aspectFit;
}

- (BOOL)getAspectFit
{
    return _aspectFit;
}

@end
