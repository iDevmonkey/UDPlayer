//
//  UDRenderFrame.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface UDRenderFrame : NSObject

@property (nonatomic) CVPixelBufferRef  frame;
@property (nonatomic, assign) CMTime    pts;
@property (nonatomic, assign) CMTime    dts;

- (instancetype) initWithFrame:(CVPixelBufferRef)frame pts:(CMTime)pts dts:(CMTime)dts;
- (uint32_t)ptsInt;
- (uint32_t)dtsInt;

@end
