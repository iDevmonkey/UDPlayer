//
//  IUDDemuxer.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDDefines.h"
#import "UDDemuxerFrame.h"
#import "Extension/Frame.h"

using namespace std;
using namespace mediakit;

#ifndef IUDDemuxer_h
#define IUDDemuxer_h

@protocol IUDDemuxer;
@protocol UDDemuxerDelegate <NSObject>

@optional
- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onDexumerSuccess:(void *)userData;

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onShutdown:(NSError *)error userData:(void *)userData;

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onError:(NSError *)error userData:(void *)userData;

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onData:(UDDemuxerFrame *)demuxerFrame userData:(void *)userData;

- (void)demuxer:(NSObject<IUDDemuxer> *)demuxer onData2:(const Frame::Ptr &)frame userData:(void *)userData;

@end

@protocol IUDDemuxer <NSObject>

@property (weak, nonatomic) id<UDDemuxerDelegate> delegate;

- (void)disponse;

@end

#endif /* IUDDemuxer_h */
