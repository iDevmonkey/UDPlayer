//
//  IUDRenderView.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/5/6.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UDRenderFrame.h"
#import "UDDefines.h"

#ifndef IUDRenderView_h
#define IUDRenderView_h

@protocol IUDRenderView <NSObject>

@property (nonatomic, assign, getter=isAspectFit) BOOL aspectFit;

@property (nonatomic, assign) UDRenderMode renderMode;

- (instancetype)initWithFrame:(CGRect)frame renderMode:(UDRenderMode)renderMode;

- (void)drawFrame:(UDRenderFrame *)frame;

- (void)disponse;

@end

#endif /* IUDRenderView_h */
