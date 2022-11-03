//
//  UDRenderView.m
//  UDRenderView
//
//  Created by CHEN on 2020/4/18.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDRenderView.h"

#import <AVFoundation/AVUtilities.h>
#import <OpenGLES/ES2/glext.h>
#import "UDMacro.h"
#import "UDRenderFrame.h"
#import "UDRenderShader.h"

#define kModuleName "UDRenderView"

typedef NS_ENUM(NSUInteger, UDPixelBufferType) {
    UDPixelBufferTypeNone = 0,
    UDPixelBufferTypeNV12,
    UDPixelBufferTypeRGB,
};

enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    UNIFORM_SCREEN_WIDTH,
    UNIFORM_RENDER_MODE,
    NUM_UNIFORMS,
};
GLint uniforms[NUM_UNIFORMS];

enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

GLfloat kUDRenderColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

GLfloat quadTextureData[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,
};

//GLfloat quadVertexData[] = {
//    -1.0f, -1.0f,
//    1.0f, -1.0f,
//    -1.0f, 1.0f,
//    1.0f, 1.0f,
//};


@interface UDRenderView ()
{
    GLint _backingWidth;
    GLint _backingHeight;
    
    EAGLContext *_context;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    
    // NV12
    GLuint               _nv12Program;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    const GLfloat        *_preferredConversion;
    
    // RGB
    GLuint                  _rgbProgram;
    CVOpenGLESTextureRef    _renderTexture;
    GLint                   _displayInputTextureUniform;
}

@property (nonatomic, assign) CGFloat   pixelbufferWidth;
@property (nonatomic, assign) CGFloat   pixelbufferHeight;
@property (nonatomic, assign) CGSize    screenResolutionSize;
@property (nonatomic, assign) UDPixelBufferType bufferType;
@property (nonatomic, assign) UDPixelBufferType lastBufferType;

@property (nonatomic, strong) UDRenderFrame *pixelBuffer;

@end

@implementation UDRenderView
@synthesize aspectFit = _aspectFit;
@synthesize renderMode = _renderMode;

#pragma mark - Life Cycle

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self initRenderView: UDRenderModeNormal];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initRenderView: UDRenderModeNormal];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame renderMode:(UDRenderMode)renderMode {
    if (self = [super initWithFrame:frame]) {
        [self initRenderView: renderMode];
    }
    return self;
}

- (void)layoutSubviews
{
    @synchronized (self) {
        [super layoutSubviews];

        if (!_context || ![EAGLContext setCurrentContext:_context]) {
            return;
        }

        [self releaseBuffers];
        [self createBuffers];
        if(_pixelBuffer){
            [self _drawFrame:_pixelBuffer];
        }
    }
}

- (void)dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self disponse];
}

#pragma mark - Public

- (void)drawFrame:(UDRenderFrame *)frame
{
    _pixelBuffer = frame;
    
    [self _drawFrame:_pixelBuffer];
}

- (void)disponse
{
    [self cleanUpTextures];
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
}

#pragma mark - Private

- (void)initRenderView:(UDRenderMode)mode {
    self.userInteractionEnabled = NO;
    self.aspectFit = YES;
    self.renderMode = mode;
    self.pixelbufferWidth = 0;
    self.pixelbufferHeight = 0;
    self.bufferType = UDPixelBufferTypeNV12;
    self.lastBufferType = UDPixelBufferTypeNone;
    _preferredConversion = kUDRenderColorConversion601FullRange;
    
    _context = [self createOpenGLContextWithWidth:&_backingWidth
                                           height:&_backingHeight
                                videoTextureCache:&_videoTextureCache
                                colorBufferHandle:&_colorBufferHandle
                                frameBufferHandle:&_frameBufferHandle];
}

- (void)_drawFrame:(UDRenderFrame *)frame
{
    [self displayPixelBuffer:frame.frame
             videoTextureCache:_videoTextureCache
                       context:_context
                  backingWidth:_backingWidth
                 backingHeight:_backingHeight
             frameBufferHandle:_frameBufferHandle
                   nv12Program:_nv12Program
                    rgbProgram:_rgbProgram
           preferredConversion:_preferredConversion
    displayInputTextureUniform:_displayInputTextureUniform
             colorBufferHandle:_colorBufferHandle];
}

#pragma mark - Render

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer videoTextureCache:(CVOpenGLESTextureCacheRef)videoTextureCache context:(EAGLContext *)context backingWidth:(GLint)backingWidth backingHeight:(GLint)backingHeight frameBufferHandle:(GLuint)frameBufferHandle nv12Program:(GLuint)nv12Program rgbProgram:(GLuint)rgbProgram preferredConversion:(const GLfloat *)preferredConversion displayInputTextureUniform:(GLuint)displayInputTextureUniform colorBufferHandle:(GLuint)colorBufferHandle{
    
    if (pixelBuffer == NULL) {
        return;
    }
    
    CVReturn error;
    
    int frameWidth  = (int)CVPixelBufferGetWidth(pixelBuffer);
    int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    if (!videoTextureCache) {
        udlog_error(kModuleName, "No video texture cache");
        return;
    }
    if ([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
    
    [self cleanUpTextures];
    
    UDPixelBufferType bufferType;
    if (CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange || CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        bufferType = UDPixelBufferTypeNV12;
    } else if (CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA) {
        bufferType = UDPixelBufferTypeRGB;
    }else {
        udlog_error(kModuleName, "Not support current format.");
        return;
    }
    
    CVOpenGLESTextureRef lumaTexture,chromaTexture,renderTexture;
    if (bufferType == UDPixelBufferTypeNV12) {
        // Y
        glActiveTexture(GL_TEXTURE0);
        
        error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             videoTextureCache,
                                                             pixelBuffer,
                                                             NULL,
                                                             GL_TEXTURE_2D,
                                                             GL_LUMINANCE,
                                                             frameWidth,
                                                             frameHeight,
                                                             GL_LUMINANCE,
                                                             GL_UNSIGNED_BYTE,
                                                             0,
                                                             &lumaTexture);
        if (error) {
            udlog_error(kModuleName, "Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
        }else {
            _lumaTexture = lumaTexture;
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(lumaTexture), CVOpenGLESTextureGetName(lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV
        glActiveTexture(GL_TEXTURE1);
        error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             videoTextureCache,
                                                             pixelBuffer,
                                                             NULL,
                                                             GL_TEXTURE_2D,
                                                             GL_LUMINANCE_ALPHA,
                                                             frameWidth / 2,
                                                             frameHeight / 2,
                                                             GL_LUMINANCE_ALPHA,
                                                             GL_UNSIGNED_BYTE,
                                                             1,
                                                             &chromaTexture);
        if (error) {
            udlog_error(kModuleName, "Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
        }else {
            _chromaTexture = chromaTexture;
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(chromaTexture), CVOpenGLESTextureGetName(chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    } else if (bufferType == UDPixelBufferTypeRGB) {
        // RGB
        glActiveTexture(GL_TEXTURE0);
        error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             videoTextureCache,
                                                             pixelBuffer,
                                                             NULL,
                                                             GL_TEXTURE_2D,
                                                             GL_RGBA,
                                                             frameWidth,
                                                             frameHeight,
                                                             GL_BGRA,
                                                             GL_UNSIGNED_BYTE,
                                                             0,
                                                             &renderTexture);
        if (error) {
            udlog_error(kModuleName, "Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
        }else {
            _renderTexture = renderTexture;
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    glViewport(0, 0, backingWidth, backingHeight);
    
    glClearColor(0.1f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (bufferType == UDPixelBufferTypeNV12) {
        if (self.lastBufferType != bufferType) {
            CGFloat eWidth = self.bounds.size.width * [UIScreen mainScreen].scale;
            
            glUseProgram(nv12Program);
            glUniform1i(uniforms[UNIFORM_Y], 0);
            glUniform1i(uniforms[UNIFORM_UV], 1);
            glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, preferredConversion);
            glUniform1f(uniforms[UNIFORM_SCREEN_WIDTH], (GLfloat)eWidth);
//            glUniform1i(uniforms[UNIFORM_RENDER_MODE], (GLint)(self.renderMode));
        }
    } else if (bufferType == UDPixelBufferTypeRGB) {
        if (self.lastBufferType != bufferType) {
            CGFloat eWidth = self.bounds.size.width * [UIScreen mainScreen].scale;
            
            glUseProgram(rgbProgram);
            glUniform1i(displayInputTextureUniform, 0);
            glUniform1f(uniforms[UNIFORM_SCREEN_WIDTH], (GLfloat)eWidth);
            glUniform1i(uniforms[UNIFORM_RENDER_MODE], (GLint)(self.renderMode));
        }
    }
    
    CGSize normalizedSamplingSize = [self getNormalizedSamplingSize:CGSizeMake(frameWidth, frameHeight)];
    
    self.pixelbufferWidth = frameWidth;
    self.pixelbufferHeight = frameHeight;
    
    GLfloat quadVertexData [] = {
        -1 * (GLfloat)normalizedSamplingSize.width, -1 * (GLfloat)normalizedSamplingSize.height,
        (GLfloat)normalizedSamplingSize.width, -1 * (GLfloat)normalizedSamplingSize.height,
        -1 * (GLfloat)normalizedSamplingSize.width, (GLfloat)normalizedSamplingSize.height,
        (GLfloat)normalizedSamplingSize.width, (GLfloat)normalizedSamplingSize.height,
    };

    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, colorBufferHandle);
    
    if ([EAGLContext currentContext] == context) {
        [context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    self.lastBufferType = self.bufferType;
}

- (EAGLContext *)createOpenGLContextWithWidth:(int *)width height:(int *)height videoTextureCache:(CVOpenGLESTextureCacheRef *)videoTextureCache colorBufferHandle:(GLuint *)colorBufferHandle frameBufferHandle:(GLuint *)frameBufferHandle {
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    CAEAGLLayer *eaglLayer       = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking   : [NSNumber numberWithBool:NO],
                                     kEAGLDrawablePropertyColorFormat       : kEAGLColorFormatRGBA8};
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
    
    [self setupBuffersWithContext:context
                            width:width
                           height:height
                colorBufferHandle:colorBufferHandle
                frameBufferHandle:frameBufferHandle];
    
    [self loadShaderWithBufferType:UDPixelBufferTypeNV12];
    [self loadShaderWithBufferType:UDPixelBufferTypeRGB];
    
    if (!*videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, videoTextureCache);
        if (err != noErr)
            udlog_error(kModuleName, "Error at CVOpenGLESTextureCacheCreate %d",err);
    }
    
    return context;
}

- (void)setupBuffersWithContext:(EAGLContext *)context width:(int *)width height:(int *)height colorBufferHandle:(GLuint *)colorBufferHandle frameBufferHandle:(GLuint *)frameBufferHandle {
    glDisable(GL_DEPTH_TEST);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    [self createBuffers];
}

- (void)createBuffers
{
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}



#pragma mark - Shader

- (void)loadShaderWithBufferType:(UDPixelBufferType)type {
    GLuint vertShader, fragShader;
//    NSURL  *vertShaderURL, *fragShaderURL;
    
//    NSString *shaderName;
    GLuint   program;
    program = glCreateProgram();
    
    const GLchar *fsh = NULL;
    const GLchar *vsh = NULL;
    
    if (type == UDPixelBufferTypeNV12) {
        if (_renderMode == UDRenderMode3D) {
            fsh = (GLchar *)[NV12_fsh_3d UTF8String];
            vsh = (GLchar *)[NV12_vsh_3d UTF8String];
        } else {
            fsh = NV12_fsh_0;
            vsh = NV12_vsh_0;
        }

        _nv12Program = program;
        
    } else if (type == UDPixelBufferTypeRGB) {
        if (_renderMode == UDRenderMode3D) {
            fsh = (GLchar *)[RGB_fsh_3d UTF8String];
            vsh = (GLchar *)[RGB_vsh_3d UTF8String];
        } else {
            fsh = RGB_fsh_0;
            vsh = RGB_vsh_0;
        }
        
        _rgbProgram = program;
    }
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER shaderString:vsh]) {
        udlog_error(kModuleName, "Failed to compile vertex shader");
        return;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER shaderString:fsh]) {
        udlog_error(kModuleName, "Failed to compile fragment shader");
        return;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glBindAttribLocation(program, ATTRIB_VERTEX  , "position");
    glBindAttribLocation(program, ATTRIB_TEXCOORD, "inputTextureCoordinate");
    
    if (![self linkProgram:program]) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        return;
    }
    
    if (type == UDPixelBufferTypeNV12) {
        uniforms[UNIFORM_Y] = glGetUniformLocation(program , "luminanceTexture");
        uniforms[UNIFORM_UV] = glGetUniformLocation(program, "chrominanceTexture");
        uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(program, "colorConversionMatrix");
        uniforms[UNIFORM_SCREEN_WIDTH] = glGetUniformLocation(program , "screenWidth");
        uniforms[UNIFORM_RENDER_MODE] = glGetUniformLocation(program , "renderMode");
    } else if (type == UDPixelBufferTypeRGB) {
        _displayInputTextureUniform = glGetUniformLocation(program, "inputImageTexture");
        uniforms[UNIFORM_SCREEN_WIDTH] = glGetUniformLocation(program , "screenWidth");
        uniforms[UNIFORM_RENDER_MODE] = glGetUniformLocation(program , "renderMode");
    }
    
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type shaderString:(const GLchar*)shaderString {
//    NSError *error;
//    NSString *sourceString = [[NSString alloc] initWithContentsOfURL:URL
//                                                            encoding:NSUTF8StringEncoding
//                                                               error:&error];
//    if (sourceString == nil) {
//        udlog_error(kModuleName, "Failed to load vertex shader: %s", [error localizedDescription].UTF8String);
//        return NO;
//    }
    if (shaderString == NULL) {
        udlog_error(kModuleName, "Failed to load vertex shader:");
        return NO;
    }
    
    GLint status;
//    const GLchar *source;
//    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &shaderString, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog {
    GLint status;
    glLinkProgram(prog);
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}

#pragma mark Clean

- (void) releaseBuffers
{
    if(_frameBufferHandle) {
        glDeleteFramebuffers(1, &_frameBufferHandle);
        _frameBufferHandle = 0;
    }
    
    if(_colorBufferHandle) {
        glDeleteRenderbuffers(1, &_colorBufferHandle);
        _colorBufferHandle = 0;
    }
}

- (void)cleanUpTextures {
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    if (_renderTexture) {
        CFRelease(_renderTexture);
        _renderTexture = NULL;
    }
    
    if (_videoTextureCache) {
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    }
}

#pragma mark - Other

- (CGSize)getNormalizedSamplingSize:(CGSize)frameSize {
    // Set up the quad vertices with respect to the orientation and aspect ratio of the video.
    CGRect viewBounds = self.bounds;
    CGSize contentSize = self.bounds.size;
    //等比例渲染
    if(self.isAspectFit){
        contentSize = CGSizeMake(frameSize.width, frameSize.height);
    }
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(contentSize, viewBounds);
    
    // Compute normalized quad coordinates to draw the frame into.
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/viewBounds.size.width,
                                        vertexSamplingRect.size.height/viewBounds.size.height);
    
    // Normalize the quad vertices.
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = cropScaleAmount.width/cropScaleAmount.height;
        normalizedSamplingSize.height = 1.0;;
    }
    
//    udlog_error(kModuleName, "viewBounds:%f,%f,contentSize:%f,%f,normalizedSamplingSize:%f,%f", viewBounds.size.width, viewBounds.size.height, contentSize.width, contentSize.height, normalizedSamplingSize.width, normalizedSamplingSize.height);
    
    return normalizedSamplingSize;
}

#pragma mark -  OpenGL ES 2 shader compilation

const GLchar *NV12_fsh = (const GLchar*)"varying highp vec2 textureCoordinate;\
\
precision mediump float;\
\
uniform sampler2D luminanceTexture;\
uniform sampler2D chrominanceTexture;\
uniform mediump mat3 colorConversionMatrix;\
uniform highp float screenWidth;\
uniform highp int renderMode;\
\
void main()\
{\
    mediump vec3 yuv;\
    lowp vec3 rgb;\
    \
    lowp vec2 tc=textureCoordinate;\
        lowp vec2 cl=textureCoordinate.xy;\
        int column=int(mod(floor(screenWidth*cl.x),4.0));\
        if(column == 1 || column == 3){\
            gl_FragColor = vec4(0.0,0.0,0.0, 1.0);\
            return; \
        }\
        else if(column == 2){\
            tc=vec2(textureCoordinate.x/2.0,textureCoordinate.y);\
        } \
        else if(column == 0){ \
            tc=vec2(textureCoordinate.x/2.0+0.5,textureCoordinate.y); \
        } \
    \
    yuv.x = texture2D(luminanceTexture, tc).r;\
    yuv.yz = texture2D(chrominanceTexture, tc).ra - vec2(0.5, 0.5);\
    rgb = colorConversionMatrix * yuv;\
    \
    gl_FragColor = vec4(rgb, 1);\
}";

const GLchar *NV12_vsh = (const GLchar*)"attribute vec4 position;\
attribute vec2 inputTextureCoordinate;\
\
varying vec2 textureCoordinate;\
\
void main()\
{\
    gl_Position = position;\
    textureCoordinate = inputTextureCoordinate;\
}";

const GLchar *RGB_fsh = (const GLchar*)"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
\
void main()\
{\
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\
}";

const GLchar *RGB_vsh = (const GLchar*)"attribute vec4 position;\
attribute vec4 inputTextureCoordinate;\
\
varying vec2 textureCoordinate;\
\
void main()\
{\
    gl_Position = position;\
    textureCoordinate = inputTextureCoordinate.xy;\
}";

@end
