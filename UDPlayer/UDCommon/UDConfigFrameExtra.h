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

@property (nonatomic, strong) NSData *vps;

@property (nonatomic, strong) NSData *sps;

@property (nonatomic, strong) NSData *f_pps;

@property (nonatomic, strong) NSData *r_pps;

@property (nonatomic, assign) uint32_t  lastDecodePts;

- (BOOL)available;

@end

NS_ASSUME_NONNULL_END
