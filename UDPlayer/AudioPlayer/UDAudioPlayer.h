#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol UDAudioPlayerDelegate <NSObject>

-(AudioFormatID)getAudioFormatID;
-(int)getAudioBufferSize;
-(int)getAudioSampleBit;
-(int)getAudioSampleRate;
-(int)getAudioChannel;
-(int)ReadData:(char *)buf Size:(int)bufsize;

@end

@interface UDAudioPlayer : NSObject

@property(nonatomic,assign) id<UDAudioPlayerDelegate> delegate;
@property(readonly, getter=isPlaying) BOOL playing; /* is it playing or not? */

-(BOOL)StartPlay;
-(void)Pause:(bool)pause;
-(void)StopPlay;

@end
