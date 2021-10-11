/*
 * AudioDec.h
 *
 *  Created on: 2014-7-1
 *      Author: root
 */

#ifndef AUDIODEC_H_
#define AUDIODEC_H_
#include "faad.h"
#include "neaacdec.h"
#include <stddef.h>

//使用faad实现的aac解码类
class AudioDec {

public:
	AudioDec(void);
	virtual ~AudioDec(void);
    //输入adts头，解析出音频参数,adts头7个字节
	bool Init(const void *adtshed, int hedlen = 7);
    //输入aac数据得到pcm数据，注意：aac数据包括adts头，aac一帧为1024次pcm采样
	int InputData(const void *data, int len, unsigned char **pOutBuffer);
    //通道个数
	unsigned char getChannels() const {
		return channels;
	}
    //采样率
	unsigned long getSamplerate() const {
		return samplerate;
	}
    //采样位数
	unsigned char getSamplebit() const {
		return samplebit;
	}

private:
	NeAACDecHandle handle;
	unsigned long samplerate;
	unsigned char channels;
	unsigned char samplebit;
	NeAACDecFrameInfo hInfo;
};

#endif /* AUDIODEC_H_ */
