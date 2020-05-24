//
//  UDDefines.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#ifndef UDDefines_h
#define UDDefines_h

typedef NS_ENUM(int, UDTrackType) {
    UDTrackInvalid = -1,
    UDTrackVideo = 0,
    UDTrackAudio,
    UDTrackTitle,
    UDTrackMax = 3
};

typedef NS_ENUM(int, UDCodecId) {
    UDCodecInvalid = -1,
    UDCodecH264 = 0,
    UDCodecH265,
    UDCodecAAC,
    UDCodecG711A,
    UDCodecG711U,
    UDCodecMax = 0x7FFF
};

typedef NS_ENUM(int, UDH264NalType) {
    UDH264Nal_SPS = 7,
    UDH264Nal_PPS = 8,
    UDH264Nal_IDR = 5,
    UDH264Nal_SEI = 6,
};

typedef NS_ENUM(int, UDH265NalType) {
    UDH265Nal_TRAIL_N = 0,
    UDH265Nal_TRAIL_R = 1,
    UDH265Nal_TSA_N = 2,
    UDH265Nal_TSA_R = 3,
    UDH265Nal_STSA_N = 4,
    UDH265Nal_STSA_R = 5,
    UDH265Nal_RADL_N = 6,
    UDH265Nal_RADL_R = 7,
    UDH265Nal_RASL_N = 8,
    UDH265Nal_RASL_R = 9,
    UDH265Nal_BLA_W_LP = 16,
    UDH265Nal_BLA_W_RADL = 17,
    UDH265Nal_BLA_N_LP = 18,
    UDH265Nal_IDR_W_RADL = 19,
    UDH265Nal_IDR_N_LP = 20,
    UDH265Nal_CRA_NUT = 21,
    UDH265Nal_VPS = 32,
    UDH265Nal_SPS = 33,
    UDH265Nal_PPS = 34,
    UDH265Nal_AUD = 35,
    UDH265Nal_EOS_NUT = 36,
    UDH265Nal_EOB_NUT = 37,
    UDH265Nal_FD_NUT = 38,
    UDH265Nal_SEI_PREFIX = 39,
    UDH265Nal_SEI_SUFFIX = 40,
};

/**
 * UserData
 */

typedef struct {
    CMTime pts;
    CMTime dts;
    int    rotate;
    int    fps;
} UDDecodeUserData;

/*
 Error
 */


#endif /* UDDefines_h */
