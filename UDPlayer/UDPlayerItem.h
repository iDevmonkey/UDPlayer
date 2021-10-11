//
//  UDPlayerItem.h
//  UDPlayer
//
//  Created by Mac on 2020/5/21.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UDRenderFrame.h"
#import "UDDemuxerFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDPlayerItem : NSObject

/**
 *  视频帧操作
 */
- (void)addVideoFrame:(UDRenderFrame *)frame;
- (UDRenderFrame *)getVideoFrame;
- (void)removeVideoFrame:(UDRenderFrame *)frame;

/**
 *  音频帧操作
 */
- (void)addAudioFrame:(UDDemuxerFrame *)frame;
- (UDDemuxerFrame *)getAudioFrame;
- (void)removeAudioFrame:(UDDemuxerFrame *)frame;

@end

NS_ASSUME_NONNULL_END
