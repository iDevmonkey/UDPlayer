//
//  UDZLAudioDemuxerFrame.h
//  UDPlayer
//
//  Created by CHEN on 2021/10/10.
//  Copyright © 2021 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Extension/Frame.h"
#import "IUDDemuxer.h"

using namespace std;
using namespace mediakit;

NS_ASSUME_NONNULL_BEGIN

@interface UDZLAudioDemuxerFrame : UDDemuxerFrame

- (instancetype)initWithFrame:(const Frame::Ptr &)frame;

- (instancetype)initWithData:(void *)data len:(int)len trackType:(int)trackType codecId:(int)codecId;

@end

NS_ASSUME_NONNULL_END
