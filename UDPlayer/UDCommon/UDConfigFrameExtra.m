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

- (void)setVps:(uint8_t *)vps 
{
    _vps = vps;
}

- (void)setSps:(uint8_t *)sps
{
    _sps = sps;
}

- (void)setFpps:(uint8_t *)f_pps
{
    _f_pps = f_pps;
}

- (void)setRpps:(uint8_t *)r_pps
{
    _r_pps = r_pps;
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

//

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

@end
