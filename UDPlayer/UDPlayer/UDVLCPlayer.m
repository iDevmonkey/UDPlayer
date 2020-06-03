//
//  UDVLCPlayer.m
//  UDPlayer
//
//  Created by CHEN on 2020/6/1.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDVLCPlayer.h"

#import "UDMacro.h"

//#import <MobileVLCKit/MobileVLCKit.h>

@interface UDVLCPlayer ()

@property (nonatomic, weak) UIView                      *convasView;

//@property (nonatomic, strong) VLCMediaPlayer            *player;
//
//@property (nonatomic, strong) NSString                  *videoUrl;

@end

@implementation UDVLCPlayer

@synthesize delegate = _delegate;

- (instancetype)initWithConvas:(UIView *)convasView
{
    self = [super init];
    if (self) {
        _convasView = convasView;
        
//        _player = [[VLCMediaPlayer alloc] init];
//        _player.delegate = self;
//        _player.drawable = self.convasView;
//
//#ifdef DEBUG
//        _player.libraryInstance.debugLogging = YES;
//        _player.libraryInstance.debugLoggingLevel = 4;
//#endif
    }
    
    return self;
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self dispose];
}

- (void)play:(NSString *)url
{
    if (!url || !url.length) return;
    
//    _videoUrl = url;
//
//    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:_videoUrl]];
//
//    [media addOptions:@{
//    @"network-caching": @(100),
//    @"live-caching": @(100),
//    @"avcodec-hw":@"any",
//    }];
//
//    _player.media = media;
//    [_player play];
}

- (void)rePlay
{
    
}

- (void)dispose
{
//    if (_player) {
//        [_player stop];
//        _player = nil;
//    }
}

/*
 Setter & Getter
 */
- (void)setOption:(NSString *)key stringValue:(NSString *)value
{
    
}

- (void)setOption:(NSString *)key intValue:(int)value
{
    
}

- (double)getVideoWidth
{
    return 0;
}

- (double)getVideoHeight
{
    return 0;
}

- (int)getVideoFps
{
    return 0;
}

- (void)setAspectFit:(BOOL)aspectFit
{
    
}

- (BOOL)getAspectFit
{
    return NO;
}

@end
