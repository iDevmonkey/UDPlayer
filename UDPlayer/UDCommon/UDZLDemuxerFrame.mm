//
//  UDZLDemuxerFrame.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDZLDemuxerFrame.h"

#import "Extension/H264.h"
#import "Extension/H265.h"
#import "Extension/AAC.h"

#include <iostream>

@interface UDZLDemuxerFrame ()

@end

@implementation UDZLDemuxerFrame
{
    uint8_t *_data;
    uint32_t _dataSize;
}

- (instancetype)initWithFrame:(const Frame::Ptr &)frame
{
    self = [super init];
    if (self) {
        _data = (uint8_t *)frame->data();
        _dataSize = frame->size();
                
        self.trackType = (UDTrackType)(frame->getTrackType());
        self.codecId = (UDCodecId)(frame->getCodecId());
        self.dts = frame->dts();
        self.pts = frame->pts();
        
        self.prefixSize = frame->prefixSize();
        self.naleType = [self getNaleType];
        self.keyFrame = frame->keyFrame();
        self.configFrame = frame->configFrame();
    }
    return self;
}

- (instancetype)initWithData:(void *)data len:(int)len trackType:(int)trackType codecId:(int)codecId dts:(uint32_t)dts pts:(uint32_t)pts
{
    self = [super init];
    if (self) {
        _data = (uint8_t *)data;
        _dataSize = len;
        
        self.trackType = (UDTrackType)(trackType);
        self.codecId = (UDCodecId)(codecId);
        self.dts = dts;
        self.pts = pts;
        
        [self initFrame];
    }
    return self;
}

- (void)initFrame
{
    self.prefixSize = [self getPrefixSize];
    
    self.naleType = [self getNaleType];
    self.keyFrame = [self getKeyFrame];
    self.configFrame = [self configFrame];
}

- (void)dealloc
{
    
}

#pragma mark - Public

- (uint8_t *)data
{
    return _data;
}

- (uint32_t)dataSize
{
    return _dataSize;
}

#pragma mark - Private

- (uint32_t)getPrefixSize
{
    switch (self.codecId) {
        case UDCodecH264:
        case UDCodecH265:
            return 4;
            break;
        case UDCodecAAC:
            return 7;
            break;
        default:
            break;
    }
    
    return 0;
}

- (int)getNaleType{
    uint8_t type = (uint8_t)(_data[self.prefixSize]);
    
    switch (self.codecId) {
        case UDCodecH264:
            return H264_TYPE(type);
            break;
        case UDCodecH265:
            return H265_TYPE(type);
            break;
        default:
            break;
    }
    return -1;
}

- (BOOL)getKeyFrame
{
    switch (self.codecId) {
        case UDCodecH264:
            return self.naleType == UDH264Nal_IDR;
            break;
        case UDCodecH265:
            return H265Frame::isKeyFrame(self.naleType) ? YES : NO;
            break;
        default:
            break;
    }
    
    return NO;
}
 
- (BOOL)getConfigFrame
{
    switch (self.codecId) {
        case UDCodecH264:
            return self.naleType == UDH264Nal_SPS || self.naleType == UDH264Nal_PPS;
            break;
        case UDCodecH265:
            return self.naleType == UDH265Nal_VPS || self.naleType == UDH265Nal_SPS || self.naleType == UDH265Nal_PPS;
            break;
        default:
            break;
    }
    
    return NO;
}

@end
