//
//  UDLivePlayer.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDLivePlayer.h"

#include <iostream>
#import "Player/MediaPlayer.h"
#import "Util/TimeTicker.h"

#import "UDMacro.h"
#import "UDZLDemuxerFrame.h"
#import "UDVideoDecoder.h"
#import "MediaDecoder.h"
#import "UDZLDemuxer.h"
#import "UDRenderView.h"
#import "GLView.h"
#import "UDGCDTimer.h"

using namespace std;
using namespace toolkit;
using namespace mediakit;

#define UD_MAX_BUFFER_IN_MS (400)

@interface UDLivePlayer ()<UDVideoDecoderDelegate, UDDemuxerDelegate>

@property (nonatomic, strong) UDZLDemuxer               *demuxer;

@property (nonatomic, strong) NSObject<IUDVideoDecoder> *decoder;

@property (nonatomic, strong) NSString                  *arg_url;

//@property (nonatomic, strong) CADisplayLink             *displayLink;

@property (nonatomic, weak) UIView                      *convasView;

@property (nonatomic, strong) UIView<IUDRenderView>     *renderView;

@property (nonatomic, strong) UDGCDTimer                *timer;

@end

@implementation UDLivePlayer
{
    BOOL _aspectFit;
    
    BOOL _starting;
}

@synthesize delegate = _delegate;

- (instancetype)initWithConvas:(UIView *)convasView
{
    self = [super init];
    if (self) {
        _convasView = convasView;
        
        _demuxer = [[UDZLDemuxer alloc] init];
        _demuxer.delegate = self;
        
        _aspectFit = YES;
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

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onData2:(const Frame::Ptr &)frame userData:(void *)userData
{
    UDZLDemuxerFrame *demuxerFrame = [[UDZLDemuxerFrame alloc] initWithFrame:frame];
    [self onDecodeForFrame:demuxerFrame];
}

#pragma mark - Decode Delegate

- (void)onDecoded:(UDRenderFrame *)renderFrame isFirstFrame:(BOOL)isFirstFrame
{
    _starting = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.renderView drawFrame:renderFrame];
    });
    
    
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
        udlog_info("decode", "pts: %d, dts:%d",demuxerFrame.pts, demuxerFrame.dts);
        
        [_decoder startDecodeFrame:demuxerFrame];
    }
}

#pragma mask - Draw

- (void)onDrawFrame
{
    
}

#pragma mark - Getter & Setter

- (UIView<IUDRenderView> *)renderView {
    if (_renderView == nil) {
        _renderView = [[UDRenderView alloc] initWithFrame:_convasView.bounds];
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
