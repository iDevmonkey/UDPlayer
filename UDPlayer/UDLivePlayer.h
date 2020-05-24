//
//  UDLivePlayer.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UDLivePlayer;
@protocol UDLivePlayerDelegate <NSObject>

@optional
- (void)player:(UDLivePlayer *)player onShutdown:(NSError *)error;

- (void)player:(UDLivePlayer *)player onPlayRusult:(NSError *)error;

@end

@interface UDLivePlayer : NSObject

@property (weak, nonatomic) id<UDLivePlayerDelegate> delegate;

- (instancetype)initWithConvas:(UIView *)convasView;

- (void)play:(NSString *)url;
- (void)rePlay;

- (void)dispose;

/*
 Setter & Getter
 */
- (void)setOption:(NSString *)key stringValue:(NSString *)value;
- (void)setOption:(NSString *)key intValue:(int)value;

- (double)getVideoWidth;
- (double)getVideoHeight;
- (int)getVideoFps;

- (void)setAspectFit:(BOOL)aspectFit;
- (BOOL)getAspectFit;

@end








