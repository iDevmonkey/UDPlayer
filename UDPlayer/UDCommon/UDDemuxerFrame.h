//
//  UDDemuxerFrame.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDDemuxerFrame : NSObject

// CodecInfo

/**
 * 音视频类型
*/
@property (nonatomic, assign) UDTrackType trackType;

/**
 * 编解码器类型
*/
@property (nonatomic, assign) UDCodecId   codecId;

// Frame

/**
 * 解码时间戳，单位毫秒
*/
@property (nonatomic, assign) uint32_t    dts;

/**
 * 显示时间戳，单位毫秒
*/
@property (nonatomic, assign) uint32_t    pts;

/**
 * 前缀长度，譬如264前缀为0x00 00 00 01,那么前缀长度就是4
 * aac前缀则为7个字节
*/
@property (nonatomic, assign) uint32_t    prefixSize;

/**
 * 是否为关键帧
 */
@property (nonatomic, assign) BOOL        keyFrame;

/**
 * 为配置帧，譬如sps pps vps
 */
@property (nonatomic, assign) BOOL        configFrame;

/**
 * NaleType
*/
@property (nonatomic, assign) int         naleType;

// Data

- (uint8_t *)data;
- (uint32_t)dataSize;

@end

NS_ASSUME_NONNULL_END
