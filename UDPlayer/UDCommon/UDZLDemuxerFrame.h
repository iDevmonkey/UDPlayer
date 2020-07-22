//
//  UDZLDemuxerFrame.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDDemuxerFrame.h"
#import "Extension/Frame.h"
#import "IUDDemuxer.h"

using namespace std;
using namespace mediakit;

NS_ASSUME_NONNULL_BEGIN

@interface UDZLDemuxerFrame : UDDemuxerFrame

- (instancetype)initWithFrame:(const Frame::Ptr &)frame;

- (instancetype)initWithData:(void *)data len:(int)len trackType:(int)trackType codecId:(int)codecId dts:(uint32_t)dts pts:(uint32_t)pts;

- (instancetype)initWithFrame_:(UDRTXPDEmuxerFrame)frame;

@end

NS_ASSUME_NONNULL_END
