#import "VC_player.h"
#import <objc/runtime.h>
//#import "UDRenderView.h"
//#import "WaitingHUD.h"
//#import "UDRenderFrame.h"
//#import "UDMacro.h"
//#import "GLView.h"

#import <AVFoundation/AVFoundation.h>

@interface VC_player ()

@property (nonatomic, strong) UDLivePlayer *player;
@property (nonatomic, strong) UDLivePlayer *player2;
@property (nonatomic, strong) UDLivePlayer *player3;
@property (nonatomic, strong) UDLivePlayer *player4;



@end

@implementation VC_player
{
    __weak IBOutlet UIView *screen;
    __weak IBOutlet UIView *screen2;
    __weak IBOutlet UIView *screen3;
    __weak IBOutlet UIView *screen4;
    
    __weak IBOutlet UITextField *txt_url;
}

-(void)dealloc{
//    [[MediaPlayerHelper Instance] removeDelegate:self withUrl:_player.url];
    
//    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [userDefaults objectForKey:@"RTSP_URL"];
    if (str == nil || str.length <= 0) {
        str = @"rtsp://192.168.1.168/0";
    }
    
    
    txt_url.text = str;
    
    _player = [[UDLivePlayer alloc] initWithConvas:screen4];
    _player.delegate = self;
    [_player setOption:@"rtp_type" intValue:1];//udp
    [_player setOption:@"render_mode" intValue:1];
//    [_player setOption:@"rtp_type" intValue:0];//tcp

//    _player2 = [[UDLivePlayer alloc] initWithConvas:screen2];
//    _player2.delegate = self;
//
//    _player3 = [[UDLivePlayer alloc] initWithConvas:screen3];
//    _player3.delegate = self;
//
//    _player4 = [[UDLivePlayer alloc] initWithConvas:screen4];
//    [_player4 setAspectFit:NO];
//    _player4.delegate = self;

    [_player play:txt_url.text];
//    [_player2 play:txt_url.text];
//    [_player3 play:txt_url.text];
//    [_player4 play:txt_url.text];
    
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_player) {
        [_player dispose];
        _player =  nil;
    }

    if (_player2) {
        [_player2 dispose];
        _player2 =  nil;
    }

    if (_player3) {
        [_player3 dispose];
        _player3 =  nil;
    }

    if (_player4) {
        [_player4 dispose];
        _player4 =  nil;
    }
}

#pragma mark - Delegate

- (void)player:(UDLivePlayer *)player onShutdown:(NSError *)error
{
//    [UIView showToastInfo:[NSString stringWithFormat:@"停止播放:%@",error]];
}

- (void)player:(UDLivePlayer *)player onPlayRusult:(NSError *)error
{
//    if (!error)  {
//        [UIView showToastSuccess:@"播放成功"];
//    }else{
//        [UIView showToastInfo:[NSString stringWithFormat:@"%@",error]];
//    }
}
- (IBAction)onSave:(id)sender {
    NSString *curUrl = txt_url.text;
    curUrl = [curUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (curUrl == nil || curUrl.length <= 0) {
        return;
    }
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:curUrl forKey:@"RTSP_URL"];
    [userDefaults synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
