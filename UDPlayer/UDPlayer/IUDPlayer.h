//
//  IUDPlayer.h
//  UDPlayer
//
//  Created by CHEN on 2020/6/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef IUDPlayer_h
#define IUDPlayer_h

@protocol IUDPlayer;
@protocol UDPlayerDelegate <NSObject>

@optional
- (void)player:(NSObject<IUDPlayer> *)player onShutdown:(NSError *)error;

- (void)player:(NSObject<IUDPlayer> *)player onPlayRusult:(NSError *)error;

@end


@protocol IUDPlayer <NSObject>

@property (weak, nonatomic) id<UDPlayerDelegate> delegate;

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

#endif /* IUDPlayer_h */
