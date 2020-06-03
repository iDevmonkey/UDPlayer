//
//  IUDVideoDecoder.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDDefines.h"
#import "UDRenderFrame.h"
#import "UDDemuxerFrame.h"

#ifndef IUDVideoDecoder_h
#define IUDVideoDecoder_h

@protocol UDVideoDecoderDelegate <NSObject>

@optional
- (void)onDecoded:(UDRenderFrame *)renderFrame isFirstFrame:(BOOL)isFirstFrame;

@end

@protocol IUDVideoDecoder <NSObject>

@property (weak, nonatomic) id<UDVideoDecoderDelegate> delegate;

- (void)startDecodeFrame:(UDDemuxerFrame *)frame;
- (void)stopDecode;

- (void)disponse;

@end

#endif /* IUDVideoDecoder_h */
