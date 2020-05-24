//
//  UDConfigFrameExtra.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/5/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDConfigFrameExtra.h"

@implementation UDConfigFrameExtra

- (BOOL)available {
    if (_codecId == UDCodecH264) {
        return _sps.length && _f_pps.length;
    }
    
    if (_codecId == UDCodecH265) {
        return _vps.length && _sps.length && _f_pps.length;;
    }
    
    return false;
}

@end
