//
//  UDGCDTimer.m
//  UDTimer
//
//  Created by CHEN on 16/6/30.
//  Copyright © 2016年 CHEN. All rights reserved.
//

#import "UDGCDTimer.h"

#import <libkern/OSAtomic.h>

typedef void (^UDGCDTimerBlock)(UDGCDTimer *timer);

@interface UDGCDTimer ()

@property (nonatomic, assign) NSTimeInterval timeInterval;

@property (nonatomic, copy) UDGCDTimerBlock  block;
@property (nonatomic, strong) id             userInfo;
@property (nonatomic, assign) BOOL           repeats;

@end

@implementation UDGCDTimer
{
    dispatch_queue_t  _privateSerialQueue;
    
    dispatch_source_t _timer;
    
    struct
    {
        uint32_t timerIsInvalidated;
    } _timerFlags;
}

@synthesize tolerance = _tolerance;

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"UDGCDTimer init error" reason:@"UDGCDTimer must be initialized with some parmas. Use 'initWithTimeInterval:block:userInfo:repeats:dispatchQueue:' instead." userInfo:nil];
    return [self initWithTimeInterval:0 block:nil userInfo:nil repeats:NO dispatchQueue:NULL];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)ti
                               block:(void (^)(UDGCDTimer *timer))block
                            userInfo:(id)userInfo
                             repeats:(BOOL)yesOrNo
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    NSParameterAssert(dispatchQueue);
    
    self = [super init];
    if (!self) return nil;
    
    _timeInterval = ti;
    _block = block;
    _userInfo = userInfo;
    _repeats = yesOrNo;
    
    NSString *privateQueueName = [NSString stringWithFormat:@"com.chen.ud.%p", self];
    _privateSerialQueue = dispatch_queue_create([privateQueueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    
    dispatch_set_target_queue(_privateSerialQueue, dispatchQueue);
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _privateSerialQueue);
    
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

#pragma mark - Public

+ (UDGCDTimer *)ud_scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block repeats:(BOOL)yesOrNo
{
    return [self ud_scheduledTimerWithTimeInterval:ti block:block userInfo:nil repeats:yesOrNo dispatchQueue:dispatch_get_main_queue()];
}

+ (UDGCDTimer *)ud_scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block repeats:(BOOL)yesOrNo dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    return [self ud_scheduledTimerWithTimeInterval:ti block:block userInfo:nil repeats:yesOrNo dispatchQueue:dispatchQueue];
}

+ (UDGCDTimer *)ud_scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block userInfo:(id)userInfo repeats:(BOOL)yesOrNo dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    UDGCDTimer *udTimer =  [[self alloc] initWithTimeInterval:ti block:block userInfo:userInfo repeats:yesOrNo dispatchQueue:dispatchQueue];
    
    [udTimer schedule];
    
    return udTimer;
}

- (void)setTolerance:(NSTimeInterval)tolerance
{
    @synchronized(self)
    {
        if (tolerance != _tolerance)
        {
            _tolerance = tolerance;
            
            [self resetTimerProperties];
        }
    }
}

- (NSTimeInterval)tolerance
{
    @synchronized(self)
    {
        return _tolerance;
    }
}

- (void)schedule
{
    [self resetTimerProperties];
    
    __weak typeof(self)weakSelf = self;
    
    dispatch_source_set_event_handler(_timer, ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        [strongSelf timerFired];
    });
    
    dispatch_resume(_timer);
}

- (void)fire
{
    [self timerFired];
}

- (void)invalidate
{
    // We check with an atomic operation if it has already been invalidated. Ideally we would synchronize this on the private queue,
    // but since we can't know the context from which this method will be called, dispatch_sync might cause a deadlock.
    if (!OSAtomicTestAndSetBarrier(7, &_timerFlags.timerIsInvalidated))
    {
        dispatch_source_t timer = _timer;
        dispatch_async(_privateSerialQueue, ^{
            
            dispatch_source_cancel(timer);
        });
    }
}

#pragma mark - Private

- (void)resetTimerProperties
{
    int64_t intervalInNanoseconds = (int64_t)(self.timeInterval * NSEC_PER_SEC);
    int64_t toleranceInNanoseconds = (int64_t)(self.tolerance * NSEC_PER_SEC);
    
    dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds);
    
    dispatch_source_set_timer(_timer,dispatchTime,(uint64_t)intervalInNanoseconds,toleranceInNanoseconds);
}

- (void)timerFired
{
    // Checking attomatically if the timer has already been invalidated.
    if (OSAtomicAnd32OrigBarrier(1, &_timerFlags.timerIsInvalidated))
    {
        return;
    }
    
    !_block ?: _block(self);
    
    if (!self.repeats)
    {
        [self invalidate];
    }
}

@end
