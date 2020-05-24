//
//  UDGCDTimer.h
//  UDTimer
//
//  Created by CHEN on 16/6/30.
//  Copyright © 2016年 CHEN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UDGCDTimer : NSObject

+ (UDGCDTimer *)ud_scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block repeats:(BOOL)yesOrNo;

+ (UDGCDTimer *)ud_scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block repeats:(BOOL)yesOrNo dispatchQueue:(dispatch_queue_t)dispatchQueue;

+ (UDGCDTimer *)ud_scheduledTimerWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block userInfo:(id)userInfo repeats:(BOOL)yesOrNo dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (instancetype)initWithTimeInterval:(NSTimeInterval)ti block:(void (^)(UDGCDTimer *timer))block userInfo:(id)userInfo repeats:(BOOL)yesOrNo dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)schedule;

- (void)fire;

/**
 *  Sets the amount of time after the scheduled fire date that the timer may fire to the given interval.
 *
 *  Setting a tolerance for a timer allows it to fire later than the scheduled fire date, improving the ability of the system to optimize for increased power savings and responsiveness. The timer may fire at any time between its scheduled fire date and the scheduled fire date plus the tolerance. The timer will not fire before the scheduled fire date. For repeating timers, the next fire date is calculated from the original fire date regardless of tolerance applied at individual fire times, to avoid drift. The default value is zero, which means no additional tolerance is applied. The system reserves the right to apply a small amount of tolerance to certain timers regardless of the value of this property.
 *  As the user of the timer, you will have the best idea of what an appropriate tolerance for a timer may be. A general rule of thumb, though, is to set the tolerance to at least 10% of the interval, for a repeating timer. Even a small amount of tolerance will have a significant positive impact on the power usage of your application. The system may put a maximum value of the tolerance.
 */
@property (atomic, assign) NSTimeInterval tolerance;

- (void)invalidate;

@property (nonatomic, strong, readonly) id userInfo;

@end
