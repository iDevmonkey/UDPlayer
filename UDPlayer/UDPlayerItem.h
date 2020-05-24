//
//  UDPlayerItem.h
//  UDPlayer
//
//  Created by Mac on 2020/5/21.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UDRenderFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDPlayerItem : NSObject

/**
 *  视频宽高
 */
@property (nonatomic, assign)   CGFloat         videoWidth;
@property (nonatomic, assign)   CGFloat         videoHeight;

/**
 *  视频帧操作
 */
- (NSInteger)playerItemValidFramesCount;

- (void)addPlayerItemValidFrames:(UDRenderFrame *)pixelFrame;
- (void)removePlayerItemValidFrames:(UDRenderFrame *)pixelFrame;

- (UDRenderFrame *)getNextPlayerItemValidFrames;

@end

NS_ASSUME_NONNULL_END
