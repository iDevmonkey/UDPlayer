//
//  UDConfigFrameExtra.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/5/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDConfigFrameExtra.h"
#import "UDMacro.h"

@implementation UDConfigFrameExtra
{
    uint8_t *_vps;
    uint8_t *_sps;
    
    // H265有前后两个pps
    uint8_t *_f_pps;
    uint8_t *_r_pps;
}

- (instancetype)initWithCodecId:(UDCodecId)codecId
{
    self = [super init];
    if (self) {
        _codecId = codecId;
    }
    return self;
}

- (BOOL)available {
    if (_codecId == UDCodecH264) {
        return _sps != NULL && _f_pps != NULL && _spsSize != 0 && _fppsSize != 0;
    }
    
    if (_codecId == UDCodecH265) {
        return _vps != NULL && _sps != NULL && _f_pps != NULL && _vpsSize !=0 && _spsSize != 0 && _fppsSize != 0;
    }
    
    return NO;
}

- (void)dispose
{
    if (_vps) {
        free(_vps);
        _vpsSize = 0;
        _vps = NULL;
    }
    
    if (_sps) {
        free(_sps);
        _spsSize = 0;
        _sps = NULL;
    }
    
    if (_f_pps) {
        free(_f_pps);
        _fppsSize = 0;
        _f_pps = NULL;
    }
    
    if (_r_pps) {
        free(_r_pps);
        _rppsSize = 0;
        _r_pps = NULL;
    }
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self dispose];
}

#pragma mark - Getter & Setter

- (void)setVps:(uint8_t *)vps size:(int)size
{
    _vps = vps;
    _vpsSize = size;
}

- (void)setSps:(uint8_t *)sps size:(int)size
{
    _sps = sps;
    _spsSize = size;
}

- (void)setFpps:(uint8_t *)f_pps size:(int)size
{
    _f_pps = f_pps;
    _fppsSize = size;
}

- (void)setRpps:(uint8_t *)r_pps size:(int)size
{
    _r_pps = r_pps;
    _rppsSize = size;
}

- (uint8_t *)getVps
{
    return _vps;
}

- (uint8_t *)getSps
{
    return _sps;
}

- (uint8_t *)getFpps
{
    return _f_pps;
}

- (uint8_t *)getRpps
{
    return _r_pps;
}

@end

@implementation UDConfigFrameExtra (Update)

- (void)updateWithFrame:(UDDemuxerFrame *)frame
{
    uint8_t *_data = frame.data + frame.prefixSize;
    uint32_t size = frame.dataSize - frame.prefixSize;
    
    uint8_t *data = (uint8_t *)malloc(size);
    memcpy(data, _data, size);

    if (frame.codecId == UDCodecH264) {
        if (frame.naleType == UDH264Nal_SPS) {
            [self setSps:data size:size];
        }
        else if (frame.naleType == UDH264Nal_PPS) {
            [self setFpps:data size:size];
        }
    }
    else if (frame.codecId == UDCodecH265) {
        if (frame.naleType == UDH265Nal_VPS) {
            [self setVps:data size:size];
        }
        else if (frame.naleType == UDH265Nal_SPS) {
            [self setSps:data size:size];
        }
        else if (frame.naleType == UDH265Nal_PPS) {
            if ([self getFpps] == NULL || self.fppsSize <= 0) {
               [self setFpps:data size:size];
            }
            else if ([self getRpps] == NULL || self.rppsSize <= 0) {
                [self setRpps:data size:size];
            }
        }
    }
}

- (BOOL)unavailableForFrame:(UDDemuxerFrame *)frame
{
    // 编码格式改变
    if (self.codecId != frame.codecId) return YES;
    
    // 帧数据改变
    uint8_t *frameData = frame.data + frame.prefixSize;
    
    uint8_t *data = NULL;
    int size = 0;
    
    if (frame.codecId == UDCodecH264) {
        if (frame.naleType == UDH264Nal_SPS) {
            data = [self getSps]; size = _spsSize;
        }
        else if (frame.naleType == UDH264Nal_PPS) {
            data = [self getFpps]; size = _fppsSize;
        }
    }
    else if (frame.codecId == UDCodecH265) {
        if (frame.naleType == UDH265Nal_VPS) {
            data = [self getVps]; size = _vpsSize;
        }
        else if (frame.naleType == UDH265Nal_SPS) {
            data = [self getSps]; size = _spsSize;
        }
        else if (frame.naleType == UDH265Nal_PPS) {
            if ([self getFpps] == NULL || self.fppsSize <= 0) {
                data = [self getFpps]; size = _fppsSize;
            }
            else if ([self getRpps] == NULL || self.rppsSize <= 0) {
                data = [self getRpps]; size = _rppsSize;
            }
        }
    }
    
    if (data != NULL && size != 0) {
        if (memcmp(frameData, data, size) != 0) {
            return YES;
        }
    }
    
    return NO;
}

@end
