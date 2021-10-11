//
//  UDThreadSafeMutableArray.m
//  UDPlayer
//
//  Created by CHEN on 2021/10/10.
//  Copyright © 2021 com.hzhihui. All rights reserved.
//

#import "UDThreadSafeMutableArray.h"

@interface UDThreadSafeMutableArray ()

@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, strong) NSMutableArray* array;

@end

@implementation UDThreadSafeMutableArray

#pragma mark - init 方法
- (instancetype)initCommon{

    self = [super init];
    if (self) {
        //%p 以16进制的形式输出内存地址，附加前缀0x
        NSString* uuid = [NSString stringWithFormat:@"com.jzp.array_%p", self];
        //注意：_syncQueue是并行队列
        _syncQueue = dispatch_queue_create([uuid UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (instancetype)init{

    self = [self initCommon];
    if (self) {
        _array = [NSMutableArray array];
    }
    return self;
}

//其他init方法略

#pragma mark - 数据操作方法 (凡涉及更改数组中元素的操作，使用异步派发+栅栏块；读取数据使用 同步派发+并行队列)
- (NSUInteger)count{

    __block NSUInteger count;
    dispatch_sync(_syncQueue, ^{
        count = _array.count;
    });
    return count;
}

- (id)objectAtIndex:(NSUInteger)index{

    __block id obj;
    dispatch_sync(_syncQueue, ^{
        if (index < [_array count]) {
            obj = _array[index];
        }
    });
    return obj;
}

- (NSEnumerator *)objectEnumerator{

    __block NSEnumerator *enu;
    dispatch_sync(_syncQueue, ^{
        enu = [_array objectEnumerator];
    });
    return enu;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index{

    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (anObject && index <= [strongSelf.array count]) {
            [strongSelf.array insertObject:anObject atIndex:index];
        }
    });
}

- (void)addObject:(id)anObject{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_syncQueue, ^{
        if(anObject){
            __strong typeof(weakSelf) strongSelf = weakSelf;
           [strongSelf.array addObject:anObject];
        }
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (index < [strongSelf.array count]) {
            [strongSelf.array removeObjectAtIndex:index];
        }
    });
}

- (void)removeLastObject{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.array removeLastObject];
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (anObject && index < [strongSelf.array count]) {
            [strongSelf.array replaceObjectAtIndex:index withObject:anObject];
        }
    });
}

- (void)removeObjectsInRange:(NSRange)range {
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.array removeObjectsInRange:range];
    });
}

- (NSUInteger)indexOfObject:(id)anObject{

    __block NSUInteger index = NSNotFound;
    dispatch_sync(_syncQueue, ^{
        for (int i = 0; i < [_array count]; i ++) {
            if ([_array objectAtIndex:i] == anObject) {
                index = i;
                break;
            }
        }
    });
    return index;
}

- (void)dealloc{

    if (_syncQueue) {
        _syncQueue = NULL;
    }
}

@end
