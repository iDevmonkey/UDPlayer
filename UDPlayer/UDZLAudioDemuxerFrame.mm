//
//  UDZLAudioDemuxerFrame.m
//  UDPlayer
//
//  Created by CHEN on 2021/10/10.
//  Copyright © 2021 com.hzhihui. All rights reserved.
//

#import "UDZLAudioDemuxerFrame.h"

#import "Extension/H264.h"
#import "Extension/H265.h"
#import "Extension/AAC.h"

#include <iostream>

@implementation UDZLAudioDemuxerFrame
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
//        self.naleType = [self getNaleType];
        self.keyFrame = frame->keyFrame();
        self.configFrame = frame->configFrame();
    }
    return self;
}

- (instancetype)initWithData:(void *)data len:(int)len trackType:(int)trackType codecId:(int)codecId
{
    self = [super init];
    if (self) {
        _data = (uint8_t *)data;
        _dataSize = len;
        
        self.trackType = (UDTrackType)(trackType);
        self.codecId = (UDCodecId)(codecId);
    }
    return self;
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
 

@end
