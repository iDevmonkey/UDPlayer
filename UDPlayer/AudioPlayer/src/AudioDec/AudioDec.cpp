/*
 * AudioDec.cpp
 *
 *  Created on: 2014-7-1
 *      Author: root
 */

#include "AudioDec.h"

AudioDec::AudioDec() {
	// TODO Auto-generated constructor stub
	handle=NULL;
	samplebit=16;
}

AudioDec::~AudioDec() {
	// TODO Auto-generated destructor stub
	if(handle!=NULL){
		NeAACDecClose(handle);
		handle=NULL;
	}
}

bool AudioDec::Init(const void *adtshed,int hedlen) {
    if (handle == NULL) {
        handle= NeAACDecOpen();
    }
    
	if(handle==NULL){
		return false;
	}
    
	char err = NeAACDecInit(handle, ( unsigned char *)adtshed, hedlen, &samplerate, &channels);
	if (err != 0)
	{
		return false;
	}
	return true;
}


int AudioDec::InputData(const void *data, int len, unsigned char** pOutBuffer) {
    //输入1024次采样对应的aac，有adts头
	* pOutBuffer=(unsigned char*)NeAACDecDecode(handle, &hInfo, (unsigned char*)data,len);
	if (!((hInfo.error == 0) && (hInfo.samples > 0))){
		return 0;
	}
	return (int)(hInfo.samples * hInfo.channels);
}

