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
    if (frame.codecId == UDCodecH264) {
        
    }
    else if (frame.codecId == UDCodecH265){
        if (frame.naleType == UDH265Nal_SEI_PREFIX ||
            frame.naleType == UDH265Nal_SEI_SUFFIX) {
            return;
        }
    }
    
    if (frame.configFrame) {
        [self getConfigFrameExtraFromFrame:frame];
        
        return;
    }
    
    if (!_configExtra || !_configExtra.available) {
        return;
    }
        
    // create decoder
    if (!_deocderSession)
    {
        [self setDecoderWithExtraData:frame];
    }
    
    [self decodeOneVideoFrame:frame userData:NULL];
}
- (void)stopDecode
{
    [self disponse];
}

- (void)disponse
{
    if (_delegate) {
        _delegate = nil;
    }

    [self DestroyConfigExtra];
    [self DestroyDecompressionSession];
    [self DestroyFormatDescription];
}

- (bool)decodeOneVideoFrame:(UDDemuxerFrame *)frame userData:(void *) userData
{
    // Add Frame Header
    uint32_t nalSize = ntohl((uint32_t)(frame.dataSize - 4));
    memcpy((uint8_t *)frame.data, &nalSize, 4);
    
    CMSampleTimingInfo timingInfo = {
        .presentationTimeStamp  = CMTimeMake(frame.pts, 1000),
        .decodeTimeStamp        = CMTimeMake(frame.dts, 1000),
    };
    
    return [self decode:frame.data withLen:frame.dataSize userData:userData time:timingInfo];
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

- (void)setDecoderWithExtraData:(UDDemuxerFrame *)frame {
    OSStatus status;
    if (frame.codecId == UDCodecH264) {
        const uint8_t *const parameterSetPointers[2] = {[_configExtra getSps], [_configExtra getFpps]};
        const size_t parameterSetSizes[2] = {static_cast<size_t>([_configExtra spsSize]), static_cast<size_t>([_configExtra fppsSize])};
        status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                     2,
                                                                     parameterSetPointers,
                                                                     parameterSetSizes,
                                                                     4,
                                                                     &_decoderFormatDescription);
    }else if (frame.codecId == UDCodecH265) {
        if (_configExtra.rppsSize == 0) {
            const uint8_t *const parameterSetPointers[3] = {[_configExtra getVps], [_configExtra getSps], [_configExtra getFpps]};
            const size_t parameterSetSizes[3] = {static_cast<size_t>([_configExtra vpsSize]), static_cast<size_t>([_configExtra spsSize]), static_cast<size_t>([_configExtra fppsSize])};
            if (@available(iOS 11.0, *)) {
                status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,
                                                                             3,
                                                                             parameterSetPointers,
                                                                             parameterSetSizes,
                                                                             4,
                                                                             NULL,
                                                                             &_decoderFormatDescription);
            } else {
                status = -1;
                udlog_error(kModuleName, "%s: System version is too low!",__func__);
            }
        } else {
            const uint8_t *const parameterSetPointers[4] = {[_configExtra getVps], [_configExtra getSps], [_configExtra getFpps], [_configExtra getRpps]};
            const size_t parameterSetSizes[4] = {static_cast<size_t>([_configExtra vpsSize]), static_cast<size_t>([_configExtra spsSize]), static_cast<size_t>([_configExtra fppsSize]), static_cast<size_t>([_configExtra rppsSize])};
            if (@available(iOS 11.0, *)) {
                status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,
                                                                             4,
                                                                             parameterSetPointers,
                                                                             parameterSetSizes,
                                                                             4,
                                                                             NULL,
                                                                             &_decoderFormatDescription);
            } else {
                status = -1;
                udlog_error(kModuleName, "%s: System version is too low!",__func__);
            }
        }
    }else {
        status = -1;
    }
    
    if(status != noErr) {
        udlog_error(kModuleName,"CMVideoFormatDescriptionCreateFromH264ParameterSets failed status=%d",(int)status);
    }
    
    if(![self ResetDecompressionSession]){
        udlog_error(kModuleName,"setDecoderWithSPS ResetDecompressionSession failed.");
    }
}

- (void)DestroyDecompressionSession
{
    if (_deocderSession) {
        VTDecompressionSessionWaitForAsynchronousFrames(_deocderSession);
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
}

- (void)DestroyFormatDescription
{
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
}

- (void)DestroyConfigExtra
{
    if (_configExtra) {
        [_configExtra dispose];
        _configExtra = nil;
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
        udlog_error(kModuleName,"VTDecompressionSessionDecodeFrame err:%d", status);
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
    if (_configExtra && [_configExtra unavailableForFrame:frame]) {
        udlog_info(kModuleName, "ConfigFrameExtra to Destroy Decoder");
        [self DestroyConfigExtra];
        [self DestroyDecompressionSession];
        [self DestroyFormatDescription];
    }
        
    if (!_configExtra) {
        _configExtra = [[UDConfigFrameExtra alloc] initWithCodecId:frame.codecId];
    }
    
    if (_configExtra.available) {
        return;
    }
    
    [_configExtra updateWithFrame:frame];
}

@end

