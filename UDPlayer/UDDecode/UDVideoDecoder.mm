//
//  UDVideoDecoder.m
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#import "UDVideoDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <pthread.h>
#import "UDMacro.h"
#import "UDDefines.h"
#import "UDConfigFrameExtra.h"

#define kModuleName "UDVideoDecoder"

@interface UDVideoDecoder ()
{
    VTDecompressionSessionRef   _decoderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;

    pthread_mutex_t             _decoder_lock;
    
    BOOL                        _isFirstFrame;
}

@property (nonatomic, strong) UDConfigFrameExtra *configExtra;

@end

@implementation UDVideoDecoder
@synthesize delegate = _delegate;

#pragma mark - Callback

static void onVideoDecoderCallback(void *decompressionOutputRefCon,
                                   void *sourceFrameRefCon,
                                   OSStatus status,
                                   VTDecodeInfoFlags infoFlags,
                                   CVImageBufferRef pixelBuffer,
                                   CMTime presentationTimeStamp,
                                   CMTime presentationDuration) {
    
    UDVideoDecoder *refCon = (__bridge UDVideoDecoder *)decompressionOutputRefCon;
    UDDecodeUserData *userData = (UDDecodeUserData *)sourceFrameRefCon;
    
    if (pixelBuffer == NULL || status != noErr) {
        udlog_error(kModuleName, "%s: decode error. pixelbuffer is NULL or status = %d",__func__,status);
        
        if (userData) {
            free(userData);
        }
        return;
    }
    
    if (!CMTIME_IS_VALID(presentationTimeStamp)) {
        udlog_error(kModuleName, "%s: not a valid pts for buffer.",__func__)
        
        if (userData) {
            free(userData);
        }
        return;
    }
    
    UDRenderFrame *frame =[[UDRenderFrame alloc] initWithFrame:pixelBuffer pts:presentationTimeStamp dts:userData->dts];
    
    if ([refCon.delegate respondsToSelector:@selector(onDecoded:isFirstFrame:)]) {
        [refCon.delegate onDecoded:frame isFirstFrame:refCon->_isFirstFrame];
        
        if (refCon->_isFirstFrame) {
            refCon->_isFirstFrame = NO;
        }
    }
    
    if (userData) {
        free(userData);
    }
}

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        _isFirstFrame = YES;
        pthread_mutex_init(&_decoder_lock, NULL);
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
    [self destoryDecoder];
}

#pragma mark - Public

- (void)startDecodeFrame:(UDDemuxerFrame *)frame {
    if (frame.configFrame || !_configExtra || !_configExtra.available) {
        [self getConfigFrameExtraFromFrame:frame];
        
        return;
    }
        
    // create decoder
    if (!_decoderSession) {
        _decoderSession = [self createDecoderWithFrame:frame
        videoDescRef:&_decoderFormatDescription
         videoFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                lock:_decoder_lock
            callback:onVideoDecoderCallback
         configExtra:_configExtra];
    }
    
    pthread_mutex_lock(&_decoder_lock);
    
    if (!_decoderSession) {
        pthread_mutex_unlock(&_decoder_lock);
        return;
    }
    
    /*  If open B frame, the code will not be used.
    if(_configExtra.lastDecodePts != 0 && frame.pts <= _configExtra.lastDecodePts){
        udlog_error(kModuleName, "decode timestamp error ! current:%d, last:%d",_configExtra.lastDecodePts != 0, _configExtra.lastDecodePts);
        pthread_mutex_unlock(&_decoder_lock);
        return;
    }
     */
    
    _configExtra.lastDecodePts = frame.pts;
    
    pthread_mutex_unlock(&_decoder_lock);
    
    // start decode
    [self startDecode:frame
              session:_decoderSession
                 lock:_decoder_lock];
}

- (void)stopDecode {
    [self destoryDecoder];
}

- (void)disponse
{
    [self destoryDecoder];
}

- (void)resetTimestamp {
    _configExtra.lastDecodePts = 0;
}

#pragma mark - Create / Destory decoder

- (VTDecompressionSessionRef)createDecoderWithFrame:(UDDemuxerFrame *)frame videoDescRef:(CMVideoFormatDescriptionRef *)videoDescRef videoFormat:(OSType)videoFormat lock:(pthread_mutex_t)lock callback:(VTDecompressionOutputCallback)callback configExtra:(UDConfigFrameExtra *)configExtra {
    pthread_mutex_lock(&lock);
    
    OSStatus status;
    if (frame.codecId == UDCodecH264) {
        const uint8_t *const parameterSetPointers[2] = {(uint8_t *)configExtra.sps.bytes, (uint8_t *)configExtra.f_pps.bytes};
        const size_t parameterSetSizes[2] = {static_cast<size_t>(configExtra.sps.length), static_cast<size_t>(configExtra.f_pps.length)};
        status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                     2,
                                                                     parameterSetPointers,
                                                                     parameterSetSizes,
                                                                     4,
                                                                     videoDescRef);
    }else if (frame.codecId == UDCodecH265) {
        if (configExtra.r_pps.length == 0) {
            const uint8_t *const parameterSetPointers[3] = {(uint8_t *)configExtra.vps.bytes, (uint8_t *)configExtra.sps.bytes, (uint8_t *)configExtra.f_pps.bytes};
            const size_t parameterSetSizes[3] = {static_cast<size_t>(configExtra.vps.length), static_cast<size_t>(configExtra.sps.length), static_cast<size_t>(configExtra.f_pps.length)};
            if (@available(iOS 11.0, *)) {
                status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,
                                                                             3,
                                                                             parameterSetPointers,
                                                                             parameterSetSizes,
                                                                             4,
                                                                             NULL,
                                                                             videoDescRef);
            } else {
                status = -1;
                udlog_error(kModuleName, "%s: System version is too low!",__func__);
            }
        } else {
            const uint8_t *const parameterSetPointers[4] = {(uint8_t *)configExtra.vps.bytes, (uint8_t *)configExtra.sps.bytes, (uint8_t *)configExtra.f_pps.bytes, (uint8_t *)configExtra.r_pps.bytes};
            const size_t parameterSetSizes[4] = {static_cast<size_t>(configExtra.vps.length), static_cast<size_t>(configExtra.sps.length), static_cast<size_t>(configExtra.f_pps.length), static_cast<size_t>(configExtra.r_pps.length)};
            if (@available(iOS 11.0, *)) {
                status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,
                                                                             4,
                                                                             parameterSetPointers,
                                                                             parameterSetSizes,
                                                                             4,
                                                                             NULL,
                                                                             videoDescRef);
            } else {
                status = -1;
                udlog_error(kModuleName, "%s: System version is too low!",__func__);
            }
        }
    }else {
        status = -1;
    }
    
    if (status != noErr) {
        udlog_error(kModuleName, "%s: NALU header error !",__func__);
        pthread_mutex_unlock(&lock);
        [self destoryDecoder];
        return NULL;
    }
    
    uint32_t pixelFormatType = videoFormat;
    const void *keys[]       = {kCVPixelBufferPixelFormatTypeKey};
    const void *values[]     = {CFNumberCreate(NULL, kCFNumberSInt32Type, &pixelFormatType)};
    CFDictionaryRef attrs    = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = callback;
    callBackRecord.decompressionOutputRefCon   = (__bridge void *)self;
    
    VTDecompressionSessionRef session;
    status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                          *videoDescRef,
                                          NULL,
                                          attrs,
                                          &callBackRecord,
                                          &session);
    
    CFRelease(attrs);
    pthread_mutex_unlock(&lock);
    if (status != noErr) {
        udlog_error(kModuleName, "%s: Create decoder failed",__func__);
        [self destoryDecoder];
        return NULL;
    }
    
    return session;
}

- (void)destoryDecoder {
    pthread_mutex_lock(&_decoder_lock);
    
    if (_configExtra) {
        _configExtra = nil;
    }
    
    if (_decoderSession) {
        VTDecompressionSessionWaitForAsynchronousFrames(_decoderSession);
        VTDecompressionSessionInvalidate(_decoderSession);
        CFRelease(_decoderSession);
        _decoderSession = NULL;
    }
    
    if (_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    pthread_mutex_unlock(&_decoder_lock);
}

/*

- (BOOL)isNeedUpdateExtraDataWithNewExtraData:(uint8_t *)newData newSize:(int)newSize lastData:(uint8_t **)lastData lastSize:(int *)lastSize {
    BOOL isNeedUpdate = NO;
    if (*lastSize == 0) {
        isNeedUpdate = YES;
    }else {
        if (*lastSize != newSize) {
            isNeedUpdate = YES;
        }else {
            if (memcmp(newData, *lastData, newSize) != 0) {
                isNeedUpdate = YES;
            }
        }
    }
    
    if (isNeedUpdate) {
        [self destoryDecoder];
        
        *lastData = (uint8_t *)malloc(newSize);
        memcpy(*lastData, newData, newSize);
        *lastSize = newSize;
    }
    
    return isNeedUpdate;
}

#pragma mark Parse NALU Header

- (void)copyDataWithOriginDataRef:(uint8_t **)originDataRef newData:(uint8_t *)newData size:(int)size {
    if (*originDataRef) {
        free(*originDataRef);
        *originDataRef = NULL;
    }
    *originDataRef = (uint8_t *)malloc(size);
    memcpy(*originDataRef, newData, size);
}

- (void)getNALUInfoWithVideoFormat:(UDCodecId)videoFormat extraData:(uint8_t *)extraData extraDataSize:(int)extraDataSize decoderInfo:(XDXDecoderInfo *)decoderInfo {

    uint8_t *data = extraData;
    int      size = extraDataSize;
    
    int startCodeVPSIndex  = 0;
    int startCodeSPSIndex  = 0;
    int startCodeFPPSIndex = 0;
    int startCodeRPPSIndex = 0;
    int nalu_type = 0;
    
    for (int i = 0; i < size; i ++) {
        if (i >= 3) {
            if (data[i] == 0x01 && data[i - 1] == 0x00 && data[i - 2] == 0x00 && data[i - 3] == 0x00) {
                if (videoFormat == UDCodecH264) {
                    if (startCodeSPSIndex == 0) {
                        startCodeSPSIndex = i;
                    }
                    if (i > startCodeSPSIndex) {
                        startCodeFPPSIndex = i;
                    }
                }else if (videoFormat == UDCodecH265) {
                    if (startCodeVPSIndex == 0) {
                        startCodeVPSIndex = i;
                        continue;
                    }
                    if (i > startCodeVPSIndex && startCodeSPSIndex == 0) {
                        startCodeSPSIndex = i;
                        continue;
                    }
                    if (i > startCodeSPSIndex && startCodeFPPSIndex == 0) {
                        startCodeFPPSIndex = i;
                        continue;
                    }
                    if (i > startCodeFPPSIndex && startCodeRPPSIndex == 0) {
                        startCodeRPPSIndex = i;
                    }
                }
            }
        }
    }
    
    int spsSize = startCodeFPPSIndex - startCodeSPSIndex - 4;
    decoderInfo->sps_size = spsSize;
    
    if (videoFormat == UDCodecH264) {
        int f_ppsSize = size - (startCodeFPPSIndex + 1);
        decoderInfo->f_pps_size = f_ppsSize;
        
        nalu_type = ((uint8_t)data[startCodeSPSIndex + 1] & 0x1F);
        if (nalu_type == 0x07) {
            uint8_t *sps = &data[startCodeSPSIndex + 1];
            [self copyDataWithOriginDataRef:&decoderInfo->sps newData:sps size:spsSize];
        }
        
        nalu_type = ((uint8_t)data[startCodeFPPSIndex + 1] & 0x1F);
        if (nalu_type == 0x08) {
            uint8_t *pps = &data[startCodeFPPSIndex + 1];
            [self copyDataWithOriginDataRef:&decoderInfo->f_pps newData:pps size:f_ppsSize];
        }
    } else {
        int vpsSize = startCodeSPSIndex - startCodeVPSIndex - 4;
        decoderInfo->vps_size = vpsSize;
        
        int f_ppsSize = startCodeRPPSIndex - startCodeFPPSIndex - 4;
        decoderInfo->f_pps_size = f_ppsSize;
        
        nalu_type = ((uint8_t) data[startCodeVPSIndex + 1] & 0x4F);
        if (nalu_type == 0x40) {
            uint8_t *vps = &data[startCodeVPSIndex + 1];
            [self copyDataWithOriginDataRef:&decoderInfo->vps newData:vps size:vpsSize];
        }
        
        nalu_type = ((uint8_t) data[startCodeSPSIndex + 1] & 0x4F);
        if (nalu_type == 0x42) {
            uint8_t *sps = &data[startCodeSPSIndex + 1];
            [self copyDataWithOriginDataRef:&decoderInfo->sps newData:sps size:spsSize];
        }
        
        nalu_type = ((uint8_t) data[startCodeFPPSIndex + 1] & 0x4F);
        if (nalu_type == 0x44) {
            uint8_t *pps = &data[startCodeFPPSIndex + 1];
            [self copyDataWithOriginDataRef:&decoderInfo->f_pps newData:pps size:f_ppsSize];
        }
        
        if (startCodeRPPSIndex == 0) {
            return;
        }
        
        int r_ppsSize = size - (startCodeRPPSIndex + 1);
        decoderInfo->r_pps_size = r_ppsSize;
        
        nalu_type = ((uint8_t) data[startCodeRPPSIndex + 1] & 0x4F);
        if (nalu_type == 0x44) {
            uint8_t *pps = &data[startCodeRPPSIndex + 1];
            [self copyDataWithOriginDataRef:&decoderInfo->r_pps newData:pps size:r_ppsSize];
        }
    }
}
 
 */

#pragma mark - Decode

- (void)startDecode:(UDDemuxerFrame *)frame session:(VTDecompressionSessionRef)session lock:(pthread_mutex_t)lock {
    
    pthread_mutex_lock(&lock);
    
    uint32_t nalSize = ntohl((uint32_t)(frame.dataSize - 4));
    memcpy((uint8_t *)frame.data, &nalSize, 4);
    
    uint8_t *data  = frame.data;
    int     size   = frame.dataSize;
    
    uint8_t *tempData = (uint8_t *)malloc(size);
    memcpy(tempData, data, size);
    
    UDDecodeUserData *userData = (UDDecodeUserData *)malloc(sizeof(UDDecodeUserData));
    userData->pts = CMTimeMake(frame.pts, 1000);
    userData->dts = CMTimeMake(frame.dts, 1000);
    
    CMBlockBufferRef blockBuffer;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         (void *)tempData,
                                                         size,
                                                         kCFAllocatorNull,
                                                         NULL,
                                                         0,
                                                         size,
                                                         0,
                                                         &blockBuffer);
    
    if (status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = { static_cast<size_t>(size) };
        
        CMSampleTimingInfo timingInfo = {
            .presentationTimeStamp  = userData->pts,
            .decodeTimeStamp        = kCMTimeInvalid,//userData->dts
        };
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription,
                                           1,
                                           1,
                                           &timingInfo,
                                           1,
                                           sampleSizeArray,
                                           &sampleBuffer);
        
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags   = kVTDecodeFrame_EnableAsynchronousDecompression;
            VTDecodeInfoFlags  flagOut = 0;
            OSStatus decodeStatus      = VTDecompressionSessionDecodeFrame(session,
                                                                           sampleBuffer,
                                                                           flags,
                                                                           userData,
                                                                           &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                pthread_mutex_unlock(&lock);
                [self destoryDecoder];
                if (blockBuffer)
                    CFRelease(blockBuffer);
                free(tempData);
                tempData = NULL;
                CFRelease(sampleBuffer);
                return;
            }
            CFRelease(sampleBuffer);
        }
    }
    
    if (blockBuffer) {
        CFRelease(blockBuffer);
    }
    
    free(tempData);
    tempData = NULL;
    
    pthread_mutex_unlock(&lock);
}

#pragma mark - Other

- (void)getConfigFrameExtraFromFrame:(UDDemuxerFrame *)frame {
    if (!_configExtra) {
        _configExtra = [[UDConfigFrameExtra alloc] init];
    }
    
    uint8_t *data = frame.data + frame.prefixSize;
    uint32_t size = frame.dataSize - frame.prefixSize;
    NSData *frameData = [NSData dataWithBytes:data length:size];
    
    if (frame.codecId == UDCodecH264) {
        if (frame.naleType == UDH264Nal_SPS) {
            _configExtra.sps = frameData;
        }
        else if (frame.naleType == UDH264Nal_PPS) {
            _configExtra.f_pps = frameData;
        }
    }
    else if (frame.codecId == UDCodecH265) {
        if (frame.naleType == UDH265Nal_VPS) {
            _configExtra.vps = frameData;
        }
        else if (frame.naleType == UDH264Nal_SPS) {
            _configExtra.sps = frameData;
        }
        else if (frame.naleType == UDH264Nal_PPS) {
            if (_configExtra.f_pps == nil || _configExtra.f_pps.length <= 0) {
                _configExtra.f_pps = frameData;
            }
            else if (_configExtra.r_pps == nil || _configExtra.r_pps.length <= 0) {
                _configExtra.r_pps = frameData;
            }
        }
    }
}

/*

- (CMSampleBufferRef)createSampleBufferFromPixelbuffer:(CVImageBufferRef)pixelBuffer videoRotate:(int)videoRotate timingInfo:(CMSampleTimingInfo)timingInfo {
    if (!pixelBuffer) {
        return NULL;
    }
    
    CVPixelBufferRef final_pixelbuffer = pixelBuffer;
    CMSampleBufferRef samplebuffer = NULL;
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus status = CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, final_pixelbuffer, &videoInfo);
    status = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, final_pixelbuffer, true, NULL, NULL, videoInfo, &timingInfo, &samplebuffer);
    
    if (videoInfo != NULL) {
        CFRelease(videoInfo);
    }
    
    if (samplebuffer == NULL || status != noErr) {
        return NULL;
    }
    
    return samplebuffer;
}
 
 */

@end
