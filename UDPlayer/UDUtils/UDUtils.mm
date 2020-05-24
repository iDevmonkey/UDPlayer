//
//  UDUtils.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDUtils.h"
#import "UDDefines.h"

@implementation UDUtils

+ (NSError *)ud_errorWithCode:(NSInteger)code message:(NSString *)message
{
    return [NSError errorWithDomain:@"com.hzh.udplayer" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

+ (NSError *)ud_errorWithEx:(const SockException &)ex
{
    if(!ex) return nil;
    
    NSInteger code = ex.getErrCode();
    NSString *message = [NSString stringWithUTF8String:ex.what()];
    
    return [self ud_errorWithCode:code message:message];
}

@end
