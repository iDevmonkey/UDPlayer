//
//  UDRenderShader.h
//  UDPlayer
//
//  Created by Devin on 2022/11/3.
//  Copyright © 2022 com.hzhihui. All rights reserved.
//

#ifndef UDRenderShader_h
#define UDRenderShader_h

const GLchar *NV12_fsh_0 = (const GLchar*)"varying highp vec2 textureCoordinate;\
\
precision mediump float;\
\
uniform sampler2D luminanceTexture;\
uniform sampler2D chrominanceTexture;\
uniform mediump mat3 colorConversionMatrix;\
\
void main()\
{\
    mediump vec3 yuv;\
    lowp vec3 rgb;\
    \
    yuv.x = texture2D(luminanceTexture, textureCoordinate).r;\
    yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);\
    rgb = colorConversionMatrix * yuv;\
    \
    gl_FragColor = vec4(rgb, 1);\
}";

const GLchar *NV12_vsh_0 = (const GLchar*)"attribute vec4 position;\
attribute vec2 inputTextureCoordinate;\
\
varying vec2 textureCoordinate;\
\
void main()\
{\
    gl_Position = position;\
    textureCoordinate = inputTextureCoordinate;\
}";

const GLchar *RGB_fsh_0 = (const GLchar*)"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
\
void main()\
{\
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\
}";

const GLchar *RGB_vsh_0 = (const GLchar*)"attribute vec4 position;\
attribute vec4 inputTextureCoordinate;\
\
varying vec2 textureCoordinate;\
\
void main()\
{\
    gl_Position = position;\
    textureCoordinate = inputTextureCoordinate.xy;\
}";

///

NSString *const NV12_vsh_3d = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
 }
 );

NSString *const NV12_fsh_3d = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 precision mediump float;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 uniform highp float screenWidth;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     lowp vec2 tc=textureCoordinate;
     lowp vec2 cl=textureCoordinate.xy;
     int column=int(mod(floor(screenWidth*cl.x),4.0));
     if(column == 1 || column == 3){
         gl_FragColor = vec4(0.0,0.0,0.0, 1.0);
         return;
     }
     else if(column == 2){
         tc=vec2(textureCoordinate.x/2.0,textureCoordinate.y);
     }
     else if(column == 0){
         tc=vec2(textureCoordinate.x/2.0+0.5,textureCoordinate.y);
     }
     
     yuv.x = texture2D(luminanceTexture, tc).r;
     yuv.yz = texture2D(chrominanceTexture, tc).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );


NSString *const RGB_vsh_3d = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 uniform highp int renderMode;
 varying vec2 textureCoordinate;
 uniform highp vec2 offset;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const RGB_fsh_3d = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform highp float screenWidth;
 uniform highp int renderMode;
 void main()
 {
     lowp vec2 cl=textureCoordinate.xy;
     if(renderMode == 1){
         int column=int(mod(floor(screenWidth*cl.x),4.0));
         if(column == 1 || column == 3){
             gl_FragColor = vec4(0.0,0.0,0.0, 1.0);
         }
         else if(column == 2){
             lowp vec2 cl=vec2(textureCoordinate.x/2.0,textureCoordinate.y);
             gl_FragColor= vec4(texture2D(inputImageTexture, cl).rgb, 1.0);
         }
         else if(column == 0){
             cl=vec2(textureCoordinate.x/2.0+0.5,textureCoordinate.y);
             gl_FragColor= vec4(texture2D(inputImageTexture, cl).rgb, 1.0);
         }
     }else{
         gl_FragColor= vec4(texture2D(inputImageTexture, cl).rgb, 1.0);
     }
 }
 );


#endif /* UDRenderShader_h */
