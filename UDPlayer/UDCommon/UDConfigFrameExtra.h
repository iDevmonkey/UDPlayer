//
//  UDConfigFrameExtra.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/5/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDDefines.h"
#import "UDDemuxerFrame.h"

@interface UDConfigFrameExtra : NSObject

@property (nonatomic, assign) UDCodecId codecId;

@property (nonatomic, assign) int vpsSize;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int fppsSize;
@property (nonatomic, assign) int rppsSize;

@property (nonatomic, assign) uint32_t  lastDecodePts;

- (instancetype)initWithCodecId:(UDCodecId)codecId;
- (BOOL)available;
- (void)dispose;

#pragma mark - Getter & Setter

- (void)setVps:(uint8_t *)vps size:(int)size;
- (void)setSps:(uint8_t *)sps size:(int)size;
- (void)setFpps:(uint8_t *)f_pps size:(int)size;
- (void)setRpps:(uint8_t *)r_pps size:(int)size;

- (uint8_t *)getVps;
- (uint8_t *)getSps;
- (uint8_t *)getFpps;
- (uint8_t *)getRpps;

@end

@interface UDConfigFrameExtra (Update)

- (void)updateWithFrame:(UDDemuxerFrame *)frame;

- (BOOL)unavailableForFrame:(UDDemuxerFrame *)frame;

@end
