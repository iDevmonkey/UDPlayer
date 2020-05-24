//
//  UDPlayerItem.m
//  UDPlayer
//
//  Created by Mac on 2020/5/21.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDPlayerItem.h"

#define kPlayerItemFrameCount     3

@interface UDPlayerItem ()

@property (nonatomic, strong) NSMutableArray         *itemOutputFrames;

@property (nonatomic, strong) dispatch_semaphore_t   bufferSemaphore;

@end

@implementation UDPlayerItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.itemOutputFrames = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark -
#pragma mark Public

- (NSInteger)playerItemValidFramesCount
{
    return self.itemOutputFrames.count;
}

- (void)addPlayerItemValidFrames:(UDRenderFrame *)pixelFrame
{
    [self _addPlayerItemValidFrames:pixelFrame];
}

- (void)removePlayerItemValidFrames:(UDRenderFrame *)pixelFrame
{
    if (!pixelFrame)
    {
        return;
    }
    
    [self _removePlayerItemValidFrames:pixelFrame];
}

- (UDRenderFrame *)getNextPlayerItemValidFrames
{
    if (self.itemOutputFrames.count > 0)
    {
        return [self.itemOutputFrames lastObject];
    }
    
    return nil;
}

#pragma mark -
#pragma mark - Private

- (void)_addPlayerItemValidFrames:(UDRenderFrame *)pixelFrame
{
    //
    if (!pixelFrame)
    {
        return;
    }
    [self.itemOutputFrames insertObject:pixelFrame atIndex:0];
    self.itemOutputFrames = [[self.itemOutputFrames subarrayWithRange:NSMakeRange(0, self.itemOutputFrames.count < kPlayerItemFrameCount ? self.itemOutputFrames.count : kPlayerItemFrameCount)] mutableCopy];
}

- (void)_removePlayerItemValidFrames:(UDRenderFrame *)pixelFrame
{
    [self.itemOutputFrames removeObject:pixelFrame];
}

@end
