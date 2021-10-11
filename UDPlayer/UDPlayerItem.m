//
//  UDPlayerItem.m
//  UDPlayer
//
//  Created by Mac on 2020/5/21.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDPlayerItem.h"
#import "UDMacro.h"

#define kVideoFrameCount     2
#define kAudioFrameCount     2

@interface UDPlayerItem ()

@property (nonatomic, strong) NSMutableArray<UDRenderFrame *>  *vFrames;
@property (nonatomic, strong) NSMutableArray<UDDemuxerFrame *> *aFrames;

@property (nonatomic, strong) dispatch_queue_t vSyncQueue;
@property (nonatomic, strong) dispatch_queue_t aSyncQueue;

@end

@implementation UDPlayerItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _vFrames = [NSMutableArray<UDRenderFrame *> array];
        _aFrames = [NSMutableArray<UDDemuxerFrame *> array];
        
        _vSyncQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.udplayer_v_%p", self] UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _aSyncQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.udplayer_a_%p", self] UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self dispose];
}

- (void)dispose
{
    if (_vFrames)
    {
        [_vFrames removeAllObjects];
        _vFrames = nil;
    }
    
    if (_aFrames)
    {
        [_aFrames removeAllObjects];
        _aFrames = nil;
    }
    
    if (_vSyncQueue)
    {
        _vSyncQueue = NULL;
    }
    
    if (_aSyncQueue)
    {
        _aSyncQueue = NULL;
    }
}

#pragma mark -
#pragma mark Public

- (void)addVideoFrame:(UDRenderFrame *)frame
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_vSyncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (frame) {
            [strongSelf.vFrames insertObject:frame atIndex:0];
            
            if (strongSelf.vFrames.count > kVideoFrameCount) {
                [strongSelf.vFrames removeObjectsInRange:NSMakeRange(kVideoFrameCount, strongSelf.vFrames.count - kVideoFrameCount)];
            }
        }
    });
}

- (UDRenderFrame *)getVideoFrame
{
    __block id obj;
    dispatch_sync(_vSyncQueue, ^{
        if (_vFrames.count > 0) {
            obj = _vFrames.lastObject;
        }
    });
    return obj;
}

- (void)removeVideoFrame:(UDRenderFrame *)frame
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_vSyncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (frame && [strongSelf.vFrames containsObject:frame]) {
            [strongSelf.vFrames removeObject:frame];
        }
    });
}

- (void)addAudioFrame:(UDDemuxerFrame *)frame
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_aSyncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (frame) {
            [strongSelf.aFrames insertObject:frame atIndex:0];
            
            if (strongSelf.aFrames.count > kAudioFrameCount) {
                [strongSelf.aFrames removeObjectsInRange:NSMakeRange(kAudioFrameCount, strongSelf.aFrames.count - kAudioFrameCount)];
            }
        }
    });
}

- (UDDemuxerFrame *)getAudioFrame
{
    __block id obj;
    dispatch_sync(_aSyncQueue, ^{
        if (_aFrames.count > 0) {
            obj = _aFrames.lastObject;
        }
    });
    return obj;
}

- (void)removeAudioFrame:(UDDemuxerFrame *)frame
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_aSyncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (frame &&  [strongSelf.aFrames containsObject:frame]) {
            [strongSelf.aFrames removeObject:frame];
        }
    });
}

@end
