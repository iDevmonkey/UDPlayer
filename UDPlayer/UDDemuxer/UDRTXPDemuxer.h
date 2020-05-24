//
//  UDRTXPDemuxer.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IUDDemuxer.h"
#import "UDDefines.h"

NS_ASSUME_NONNULL_BEGIN

//
//  RTSP/RTMP Demuxer(Player)
//  Use ZLMediaKit(https://github.com/xiongziliang/ZLMediaKit)
//
@interface UDRTXPDemuxer : NSObject<IUDDemuxer>

/**
* 设置配置选项
* @param key 配置项键,支持 net_adapter/rtp_type/rtsp_user/rtsp_pwd/protocol_timeout_ms/media_timeout_ms/beat_interval_ms/max_analysis_ms
* @param value 配置项值,类型支持NSString或者NSNumber
*/
- (void)setOption:(NSString *)key value:(NSObject *)value;

/**
* 开始url
* @param url rtsp[s]/rtmp[s] url
*/
- (void)start:(NSString *)url;

///////////////////////////获取音视频相关信息接口在播放成功回调触发后才有效///////////////////////////////

/**
* 获取视频codec_id
*/
- (UDCodecId)getVideoCodecId;

/**
* 获取视频宽度
*/
- (double)getVideoWidth;

/**
* 获取视频高度
*/
- (double)getVideoHeight;

/**
* 获取视频帧率
*/
- (int)getVideoFps;

/**
* 获取音频codec_id
*/
- (UDCodecId)getAudioCodecId;

/**
* 获取音频采样率
*/
- (int)getAudioSamplerate;

/**
* 获取音频采样位数，一般为16
*/
- (int)getAudioBit;

/**
* 获取音频通道数
*/
- (int)getAudioChannel;

@end

NS_ASSUME_NONNULL_END
