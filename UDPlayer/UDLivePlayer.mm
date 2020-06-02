//
//  UDLivePlayer.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDLivePlayer.h"

#import "UDMacro.h"
#import "UDPlayer.h"

@interface UDLivePlayer ()<UDPlayerDelegate>

@property (nonatomic, weak) UIView                      *convasView;

@property (nonatomic, strong) NSObject<IUDPlayer>       *player;

@end

@implementation UDLivePlayer
{
    BOOL _aspectFit;
}

@synthesize delegate = _delegate;

- (instancetype)initWithConvas:(UIView *)convasView
{
    self = [super init];
    if (self) {
        _convasView = convasView;
        
        _aspectFit = YES;
    }
    
    return self;
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self dispose];
}

#pragma mark - Public

- (void)play:(NSString *)url
{
    if (_player == nil) {
        _player = [[UDPlayer alloc] initWithConvas:_convasView];
        [_player setAspectFit:_aspectFit];
        _player.delegate = self;
    }
    
    [_player play:url];
}

- (void)rePlay
{
    [_player rePlay];
}

- (void)dispose
{
    [_player dispose];
}

- (void)setOption:(NSString *)key stringValue:(NSString *)value
{
    [_player setOption:key stringValue:value];
}

- (void)setOption:(NSString *)key intValue:(int)value
{
    [_player setOption:key intValue:value];
}

- (double)getVideoWidth
{
    return _player.getVideoWidth;
}

- (double)getVideoHeight
{
    return _player.getVideoHeight;
}

- (int)getVideoFps
{
    return _player.getVideoFps;
}

- (void)setAspectFit:(BOOL)aspectFit
{
    _aspectFit = aspectFit;
    
    [_player setAspectFit:aspectFit];
}

- (BOOL)getAspectFit
{
    return _aspectFit;
}

#pragma mark - UDPlayerDelegate

- (void)player:(NSObject<IUDPlayer> *)player onShutdown:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(player:onShutdown:)]) {
        [self.delegate player:self onShutdown:error];
    }
}

- (void)player:(NSObject<IUDPlayer> *)player onPlayRusult:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(player:onPlayRusult:)]) {
        [self.delegate player:self onPlayRusult:error];
    }
}

@end
