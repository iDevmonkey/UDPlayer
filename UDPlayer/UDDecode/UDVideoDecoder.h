//
//  UDVideoDecoder.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "UDDefines.h"
#import "IUDVideoDecoder.h"
#import "UDDemuxerFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface UDVideoDecoder : NSObject<IUDVideoDecoder>

/**
    Reset timestamp when you parse a new file (only use the decoder as global var)
 */
- (void)resetTimestamp;

@end

NS_ASSUME_NONNULL_END
