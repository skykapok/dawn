#include "../oal_decode.h"

#include <assert.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>


#ifdef SUPPORT_AUDIO_MP3
#include <mpg123.h>

static struct oal_info*
_get_info(mpg123_handle* handle, struct oal_info* out_info) {
  int channels = 0;
  int encoding = 0;
  long rate = 0;
  int err = mpg123_getformat(handle, &rate, &channels, &encoding);
  if (MPG123_OK != err) {
    ad_error("mpg123_getformat error status[%d]", err);
    return NULL;
  }
  ALsizei size = mpg123_length(handle);
  if (size == MPG123_ERR) {
    ad_error("mpg123_length error");
    return NULL;
  }
  ALsizei freq = rate;
  ALsizei format;
  if (encoding == MPG123_ENC_UNSIGNED_8) {
    format = (channels==1)?(AL_FORMAT_MONO8):(AL_FORMAT_STEREO8);
  } else {
    format = (channels==1)?(AL_FORMAT_MONO16):(AL_FORMAT_STEREO16);
  }

  out_info->size = size;
  out_info->format = format;
  out_info->freq =freq;
  return out_info;
}

static mpg123_handle*
_get_handle() {
  static mpg123_handle* handle = NULL;
  if(!handle) {
    mpg123_init();
    int err=0;
    handle = mpg123_new(NULL, &err);
    if(MPG123_OK != mpg123_format(handle, 44100, MPG123_MONO | MPG123_STEREO,
      MPG123_ENC_UNSIGNED_8 | MPG123_ENC_SIGNED_16)) {
      mpg123_delete(handle);
      handle = NULL;
    }
  }
  return handle;
}

static void*
_read(mpg123_handle* handle, size_t size, size_t *out_done) {
  unsigned char* head = malloc(size);
  unsigned char* buffer = head;
  size_t cap = size;
  *out_done = 0;

  do{
    size_t _read = 0;
    int err = mpg123_read(handle, buffer, cap, &_read);
    *out_done += _read;
    if(err != MPG123_OK) {
      if(err != MPG123_DONE) {
        free(buffer);
        return NULL;
      }
      break;
    }else {
      size_t new_size = size*2;
      head = realloc(head, new_size);
      buffer = head + size;
      cap = size;
      size = new_size;
    }
  }while(true);
  return head;
}

static bool
_decode_mp3(const char* filepath, struct oal_info* out) {
  bool ret = false;
  mpg123_handle* handle = _get_handle();
  if(!handle){
    ad_error("cannot set specified mpg123 format, file: %s", filepath);
    goto EXIT;
  }

  if(MPG123_OK != mpg123_open(handle, filepath)) {
    ad_error("open file: %s error.", filepath);
    goto EXIT;
  }

  if(!_get_info(handle, out)) {
    mpg123_close(handle);
    goto EXIT;
  }

  size_t size = out->size;
  if(out->format == AL_FORMAT_MONO16 || out->format == AL_FORMAT_STEREO16) {
    size *= 2;
  }

  size_t done = 0;
  unsigned char* buffer = _read(handle, size, &done);
  if(!buffer) {
    ad_error("mpg123_read error: %s", filepath);
    goto EXIT;
  }else {
    strcpy(out->type, "mp3");
    out->data = buffer;
    out->size = done;    
  }

  mpg123_close(handle);
  ret = true;
EXIT:
  return ret;
}

#else
static bool
_decode_mp3(const char* filepath, struct oal_info* out) {
  ad_error("mp3 not support");
  return false;
}
#endif


int
adl_decode_mp3(lua_State* L) {
  const char* file = lua_tostring(L, 1);
  struct oal_info out = {0};
  if(_decode_mp3(file, &out)){
    return ad_new_info(L, &out);
  } else {
    luaL_error(L, ad_last_error());
  }
  return 0;
}




