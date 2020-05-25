//
//  UDConfigFrameExtra.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/5/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDConfigFrameExtra : NSObject

@property (nonatomic, assign) UDCodecId codecId;

@property (nonatomic, assign) int vpsSize;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int fppsSize;
@property (nonatomic, assign) int rppsSize;

@property (nonatomic, assign) uint32_t  lastDecodePts;

- (void)setVps:(uint8_t *)vps;
- (void)setSps:(uint8_t *)sps;
- (void)setFpps:(uint8_t *)f_pps;
- (void)setRpps:(uint8_t *)r_pps;

- (uint8_t *)getVps;
- (uint8_t *)getSps;
- (uint8_t *)getFpps;
- (uint8_t *)getRpps;

- (BOOL)available;

- (void)dispose;

@end

NS_ASSUME_NONNULL_END
