#import "MediaDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <objc/runtime.h>
#import "Util/TimeTicker.h"
#import "UDMacro.h"
#import "UDDefines.h"
#import "UDDemuxerFrame.h"
#import "UDConfigFrameExtra.h"

#define kModuleName "MediaDecoder"

using namespace toolkit;

@interface MediaDecoder ()
{
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}

@property (nonatomic, strong) UDConfigFrameExtra *configExtra;

@end

@implementation MediaDecoder
@synthesize delegate = _delegate;

#pragma mark - Callback

static void onVideoDecoderCallback(void *decompressionOutputRefCon,
                                   void *sourceFrameRefCon,
                                   OSStatus status,
                                   VTDecodeInfoFlags infoFlags,
                                   CVImageBufferRef pixelBuffer,
                                   CMTime presentationTimeStamp,
                                   CMTime presentationDuration ) {
    
    if (pixelBuffer == NULL || status != noErr || infoFlags & kVTDecodeInfo_FrameDropped) {
        udlog_error(kModuleName, "%s: decode error. pixelbuffer is NULL or status = %d",__func__,status);
        return;
    }
    
//    if (!CMTIME_IS_VALID(presentationTimeStamp)) {
//        udlog_error(kModuleName, "%s: not a valid pts for buffer.",__func__)
//        return;
//    }
    
    if (infoFlags & kVTDecodeInfo_FrameDropped) {
        udlog_error(kModuleName, "%s: decode info frame dropped",__func__);
        return;
    }
    
    MediaDecoder *refCon = (__bridge MediaDecoder *)decompressionOutputRefCon;
    
    UDRenderFrame *frame =[[UDRenderFrame alloc] initWithFrame:pixelBuffer pts:presentationTimeStamp dts:kCMTimeZero];
    
    if ([refCon.delegate respondsToSelector:@selector(onDecoded:isFirstFrame:)]) {
        [refCon.delegate onDecoded:frame isFirstFrame:NO];
    }
}

#pragma mark - Life Cycle

- (void) dealloc
{
    udlog_info([NSStringFromClass([self class]) UTF8String], "---dealloc---");
    
    [self disponse];
}

#pragma mark - Public

- (void)startDecodeFrame:(UDDemuxerFrame *)frame
{
    if (frame.configFrame || !_configExtra || !_configExtra.available) {
        if (!_configExtra || !_configExtra.available) {
            [self getConfigFrameExtraFromFrame:frame];
        }
        
        return;
    }
        
    // create decoder
    if (!_deocderSession) {
        [self setDecoderWithExtraData];
    }
    
    [self decodeOneVideoFrame2:frame userData:NULL];
}
- (void)stopDecode
{
    [self disponse];
}

- (void)disponse
{
    if (_configExtra) {
        [_configExtra dispose];
        _configExtra = nil;
    }
    
    if (_delegate) {
        _delegate = nil;
    }

    [self DestroyDecompressionSession];
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
}

- (bool)decodeOneVideoFrame2:(UDDemuxerFrame *)frame userData:(void *) userData
{
    // Add Frame Header
    uint32_t nalSize = ntohl((uint32_t)(frame.dataSize - 4));
    memcpy((uint8_t *)frame.data, &nalSize, 4);
    
    CMSampleTimingInfo timingInfo = {
        .presentationTimeStamp  = CMTimeMake(frame.pts, 1000),
        .decodeTimeStamp        = CMTimeMake(frame.dts, 1000),
    };
    
    switch (frame.naleType) {
        case 0x07:
        case 0x08:
            return false;
        default:
            return [self decode:frame.data withLen:frame.dataSize userData:userData time:timingInfo];
            break;
    }
}

#pragma mark - Create / Destory Decoder

- (CMSampleBufferRef)CreateSampleBufferFrom: (CMFormatDescriptionRef)fmt_desc demux_buff:(void *)demux_buff demux_size:(size_t)demux_size timingInfo: (CMSampleTimingInfo)timingInfo {
    
    OSStatus status;
    CMBlockBufferRef newBBufOut = NULL;
    CMSampleBufferRef sBufOut = NULL;
    
    status = CMBlockBufferCreateWithMemoryBlock(
                                                NULL,
                                                demux_buff,
                                                demux_size,
                                                kCFAllocatorNull,
                                                NULL,
                                                0,
                                                demux_size,
                                                FALSE,
                                                &newBBufOut);
    
    if (!status) {
        status = CMSampleBufferCreate(
                                      NULL,
                                      newBBufOut,
                                      TRUE,
                                      0,
                                      0,
                                      fmt_desc,
                                      1,
                                      0,
                                      &timingInfo,
                                      0,
                                      NULL,
                                      &sBufOut);
    }
    
    CFRelease(newBBufOut);
    if (status == 0) {
        return sBufOut;
    } else {
        return NULL;
    }
}

- (BOOL)ResetDecompressionSession
{
    TimeTicker1(0);
    static size_t const attributes_size = 3;
    CFTypeRef keys[attributes_size] = {
        kCVPixelBufferOpenGLESCompatibilityKey,
        kCVPixelBufferIOSurfacePropertiesKey,
        kCVPixelBufferPixelFormatTypeKey
    };
    
    CFDictionaryRef io_surface_value = CreateCFDictionary(nullptr, nullptr, 0);
    int64_t nv12type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef pixel_format = CFNumberCreate(nullptr, kCFNumberLongType, &nv12type);
    CFTypeRef values[attributes_size] = {kCFBooleanTrue, io_surface_value, pixel_format};
    CFDictionaryRef attributes = CreateCFDictionary(keys, values, attributes_size);
    
    if (io_surface_value)
    {
        CFRelease(io_surface_value);
        io_surface_value = nullptr;
    }
    
    if (pixel_format)
    {
        CFRelease(pixel_format);
        pixel_format = nullptr;
    }
    
    VTDecompressionOutputCallbackRecord record = {onVideoDecoderCallback, (__bridge void *)self};
    OSStatus status = VTDecompressionSessionCreate(nullptr,
                                                   _decoderFormatDescription,
                                                   nullptr,
                                                   attributes,
                                                   &record,
                                                   &_deocderSession);
    CFRelease(attributes);
    if (status != noErr)
    {
        [self DestroyDecompressionSession];
        return false;
    }
#if defined(WEBRTC_IOS)
    VTSessionSetProperty(_deocderSession,
                         kVTDecompressionPropertyKey_RealTime,
                         kCFBooleanTrue);
#endif
    return true;
}

- (void)setDecoderWithExtraData {
    const uint8_t* const parameterSetPointers[2] = { [_configExtra getSps], [_configExtra getFpps] };
    const size_t parameterSetSizes[2] = { static_cast<size_t>([_configExtra spsSize]), static_cast<size_t>([_configExtra fppsSize]) };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    if(status != noErr) {
        udlog_error("MeidaDecoder","CMVideoFormatDescriptionCreateFromH264ParameterSets failed status=%d",(int)status);
    }
    
    if(![self ResetDecompressionSession]){
        udlog_error("MeidaDecoder","setDecoderWithSPS ResetDecompressionSession failed.");
    }
}

-(void)DestroyDecompressionSession
{
    if (_deocderSession) {
        VTDecompressionSessionWaitForAsynchronousFrames(_deocderSession);
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
}

#pragma mark - Decode

- (bool)decode:(const uint8_t *) data withLen:(int )dataLen userData:(void *) userData time:(CMSampleTimingInfo)timingInfo
{
    CMSampleBufferRef sample_buffer = [self CreateSampleBufferFrom:_decoderFormatDescription demux_buff:(void *)data demux_size:dataLen timingInfo:timingInfo];
    
    VTDecodeInfoFlags flags_out;
    VTDecodeFrameFlags decode_flags = kVTDecodeFrame_EnableAsynchronousDecompression | kVTDecodeFrame_1xRealTimePlayback;
    OSStatus status = VTDecompressionSessionDecodeFrame( _deocderSession,
                                                        sample_buffer,
                                                        decode_flags,
                                                        userData,
                                                        &flags_out);
    if(status == kVTInvalidSessionErr) {
        if([self ResetDecompressionSession] == 0) {
            status = VTDecompressionSessionDecodeFrame( _deocderSession,
                                                       sample_buffer,
                                                       decode_flags,
                                                       userData,
                                                       &flags_out);
        }
    }
    CFRelease(sample_buffer);
    if (status != noErr) {
        udlog_error("MeidaDecoder","VTDecompressionSessionDecodeFrame err:%d", status);
        return false;
    }
    return true;
}

#pragma mark - Function


inline CFDictionaryRef CreateCFDictionary(CFTypeRef* keys,
                                          CFTypeRef* values,
                                          size_t size)
{
    return CFDictionaryCreate(nullptr, keys, values, size,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);
}

#pragma mark - Other

- (void)getConfigFrameExtraFromFrame:(UDDemuxerFrame *)frame
{
    if (!_configExtra) {
        _configExtra = [[UDConfigFrameExtra alloc] init];
    }
    
    uint8_t *_data = frame.data + frame.prefixSize;
    uint32_t size = frame.dataSize - frame.prefixSize;
    
    uint8_t *data = (uint8_t *)malloc(size);
    memcpy(data, _data, size);

    if (frame.codecId == UDCodecH264) {
        if (frame.naleType == UDH264Nal_SPS) {
            [_configExtra setSps:data];
            [_configExtra setSpsSize:size];
        }
        else if (frame.naleType == UDH264Nal_PPS) {
            [_configExtra setFpps:data];
            [_configExtra setFppsSize:size];
        }
    }
    else if (frame.codecId == UDCodecH265) {
        if (frame.naleType == UDH265Nal_VPS) {
            [_configExtra setVps:data];
            [_configExtra setVpsSize:size];
        }
        else if (frame.naleType == UDH264Nal_SPS) {
            [_configExtra setSps:data];
            [_configExtra setSpsSize:size];
        }
        else if (frame.naleType == UDH264Nal_PPS) {
            if ([_configExtra getFpps] == NULL || _configExtra.fppsSize <= 0) {
               [_configExtra setFpps:data];
                [_configExtra setFppsSize:size];
            }
            else if ([_configExtra getRpps] == NULL || _configExtra.rppsSize <= 0) {
                [_configExtra setRpps:data];
                [_configExtra setRppsSize:size];
            }
        }
    }
}

@end

