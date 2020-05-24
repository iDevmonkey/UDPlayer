//
//  UDUtils.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player/MediaPlayer.h"

using namespace toolkit;

NS_ASSUME_NONNULL_BEGIN

@interface UDUtils : NSObject

+ (NSError *)ud_errorWithCode:(NSInteger)code message:(NSString *)message;

+ (NSError *)ud_errorWithEx:(const SockException &)ex;

@end

NS_ASSUME_NONNULL_END
