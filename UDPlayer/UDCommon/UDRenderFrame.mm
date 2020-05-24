//
//  UDRenderFrame.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDRenderFrame.h"

@implementation UDRenderFrame

- (instancetype) initWithFrame:(CVPixelBufferRef)frame pts:(CMTime)pts dts:(CMTime)dts {
    self = [super init];
    if (self) {
        _frame = CVPixelBufferRetain(frame);
        _pts = pts;
        _dts = dts;
    }
    return self;
}

- (uint32_t)ptsInt {
    return (uint32_t)CMTimeGetSeconds(_pts) * 1000;
}

- (uint32_t)dtsInt {
    return (uint32_t)CMTimeGetSeconds(_dts) * 1000;
}

- (void)dealloc {
    CVPixelBufferRelease(_frame);
}

@end
