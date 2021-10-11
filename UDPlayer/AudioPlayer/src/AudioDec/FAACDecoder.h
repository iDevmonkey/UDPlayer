//
//  FAACDecoder.h
//  UDPlayer
//
//  Created by CHEN on 2021/10/11.
//  Copyright © 2021 com.hzhihui. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "faad.h"
#include "neaacdec.h"
#include <stddef.h>

typedef struct {
    NeAACDecHandle handle;
    int sample_rate;
    int channels;
    int bit_rate;
}FAADContext;

FAADContext* faad_decoder_create(int sample_rate, int channels, int bit_rate);
int faad_decode_frame(FAADContext *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen);
void faad_decode_close(FAADContext *pParam);
