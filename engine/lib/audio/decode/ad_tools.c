#include "../oal_decode.h"

#include <string.h>
#include <stdlib.h>


#ifdef SUPPORT_AUDIO_TOOLS
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>

static struct oal_info* 
_decode_tools (const char* filepath, struct oal_info* out) {
  struct oal_info* ret = NULL;
  OSStatus status = noErr;
  ExtAudioFileRef extRef = NULL;
  SInt64 file_length_in_frame = 0;
  AudioStreamBasicDescription file_format;
  AudioStreamBasicDescription   output_format;
  UInt32 property_size = sizeof(file_format);

  CFURLRef url = CFURLCreateWithBytes(kCFAllocatorDefault, 
    (const UInt8*)filepath, strlen(filepath), kCFStringEncodingUTF8, NULL); 

  status = ExtAudioFileOpenURL(url, &extRef);
  if(status != noErr) {
    ad_error("cannot openurl %s from ExtAudioFileOpenURL status: [%ld]", filepath, status);
    goto EXIT;
  }

  // get the audio data format
  status = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &property_size, &file_format);
  if(status != noErr) {
    ad_error("ExtAudioFileGetProperty get error status: [%ld]", status);
    goto EXIT;
  }

  if(file_format.mChannelsPerFrame > 2) {
    ad_error("Unsupported Format, channel count is greater than stereo");
    goto EXIT;
  }

  // Set the client format to 16 bit signed integer (native-endian) data
  // Maintain the channel count and sample rate of the original source format
  output_format.mSampleRate = file_format.mSampleRate;
  output_format.mChannelsPerFrame = file_format.mChannelsPerFrame;

  output_format.mFormatID = kAudioFormatLinearPCM;
  output_format.mBytesPerPacket = 2 * output_format.mChannelsPerFrame;
  output_format.mFramesPerPacket = 1;
  output_format.mBytesPerFrame = 2 * output_format.mChannelsPerFrame;
  output_format.mBitsPerChannel = 16;
  output_format.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;

  // Set the desired client (output) data format
  status = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(output_format), &output_format);
  if(status != noErr) {
    ad_error("ExtAudioFileSetProperty error status: [%ld]", status);
    goto EXIT;
  }

  // get the total frame count
  property_size = sizeof(file_length_in_frame);
  status = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &property_size, &file_length_in_frame);
  if(status != noErr) {
    ad_error("ExtAudioFileGetProperty error status: [%ld]", status);
    goto EXIT;
  }

  // Read all the data into memory
  UInt32 data_size = (UInt32) file_length_in_frame * output_format.mBytesPerFrame;
  void*  data = malloc(data_size);
  if(!data) {
    ad_error("malloc error size: %ld", data_size);
    goto EXIT;
  }

  memset(data, 0, data_size);
  AudioBufferList   theDataBuffer;
  theDataBuffer.mNumberBuffers = 1;
  theDataBuffer.mBuffers[0].mDataByteSize = data_size;
  theDataBuffer.mBuffers[0].mNumberChannels = output_format.mChannelsPerFrame;
  theDataBuffer.mBuffers[0].mData = data;

  // Read the data into an AudioBufferList
  status = ExtAudioFileRead(extRef, (UInt32*)&file_length_in_frame, &theDataBuffer);
  if(status == noErr) {
    // success
    out->data = data;
    out->size = (ALsizei)data_size;
    out->format = (output_format.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
    out->freq = (ALsizei)output_format.mSampleRate;
  } else {
    // failure
    free(data);
    ad_error("ExtAudioFileRead error status: [%ld]", status);
    goto EXIT;
  }

  ret = out;
EXIT:
  CFRelease(url);
  if (extRef) ExtAudioFileDispose(extRef);
  return ret; 
}
#else

static struct oal_info* 
_decode_tools (const char* filepath, struct oal_info* out) {
  ad_error("no support audio tools");
  return NULL;
}
#endif


int
adl_decode_tools(lua_State* L) {
  const char* file = lua_tostring(L, 1);
  const char* type = lua_tostring(L, 2);
  struct oal_info out = {0};
  if(_decode_tools(file, &out)){
    strncpy(out.type, type, sizeof(out.type)-1);
    return ad_new_info(L, &out);
  } else {
    luaL_error(L, ad_last_error());
  }
  return 0;
}
