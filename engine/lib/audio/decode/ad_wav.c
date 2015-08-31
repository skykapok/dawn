#include "../oal_decode.h"

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>

#define check(v, s) do { \
                      if(!(v)) { \
                        ad_error("decode wav: %s", (s)); \
                        goto EXIT; \
                      } \
                    }while(0)


struct riff_header {
  uint8_t chunk_id[4];
  uint32_t chunk_sz;
  uint8_t format[4];
};

struct wav_format {
  uint8_t subchunk_id[4];
  uint32_t subchunk_sz;
  uint16_t audio_format;
  uint16_t num_channels;
  uint32_t sample_rate;
  uint32_t byte_rate;
  uint16_t block_align;
  uint16_t bits_per_sample;
};


struct wav_data {
  uint8_t subchunk_id[4];
  uint32_t subchunk_sz;
};

static bool
_read_buffer(FILE* fp, uint8_t* out_buffer, size_t sz) {
  size_t ret = fread(out_buffer, 1, sz, fp);
  return ret==sz;
}


static bool
_read_short(FILE* fp, uint16_t* out_val) {
    uint8_t buff[2];
    size_t ret = fread(buff, 1, 2, fp);
    if(ret==2){
      *out_val = ((uint16_t)(buff[1]))<<8;
      *out_val |= ((uint16_t)(buff[0]));
      return true;
    }
    return false;
}

static bool
_read_int(FILE* fp, uint32_t* out_val) {
  uint8_t buff[4];
  size_t ret = fread(buff, 1, 4, fp);
  if(ret==4){
    *out_val = ((uint32_t)(buff[3]))<<24;
    *out_val |= ((uint32_t)(buff[2]))<<16;
    *out_val |= ((uint32_t)(buff[1]))<<8;
    *out_val |= ((uint32_t)(buff[0]));
    return true;
  }
  return false;
}

static bool
_read_riff(FILE* fp, struct riff_header* out_val) {
  if(_read_buffer(fp, out_val->chunk_id, 4)        &&
     _read_int(fp, &(out_val->chunk_sz))           &&
     _read_buffer(fp, out_val->format, 4)          &&
     0==memcmp(out_val->chunk_id, "RIFF", 4)       &&
     0==memcmp(out_val->format, "WAVE", 4)         ){
      return true;
  }
  return false;
}

static bool
_read_wave_foramt(FILE* fp, struct wav_format* out_val) {
    if(_read_buffer(fp, out_val->subchunk_id, 4)          &&
       _read_int(fp, &out_val->subchunk_sz)               &&
       _read_short(fp, &out_val->audio_format)            &&
       _read_short(fp, &out_val->num_channels)            &&
       _read_int(fp, &out_val->sample_rate)               &&
       _read_int(fp, &out_val->byte_rate)                 &&
       _read_short(fp, &out_val->block_align)             &&
       _read_short(fp, &out_val->bits_per_sample)         &&
       0==memcmp(out_val->subchunk_id, "fmt ", 4)         ){
        return true;
    }
  return false;
}

static bool
_read_wave_data(FILE* fp, struct wav_data* out_val) {
  if(_read_buffer(fp, out_val->subchunk_id, 4)   && 
     _read_int(fp, &out_val->subchunk_sz)        ){
      return true;
  }
  return false;
}


static struct oal_info* 
_decode_wav (const char* filepath, struct oal_info* out) {
  struct oal_info* ret = NULL;

  FILE* fp = NULL;
  filepath = (filepath)?(filepath):("");
  fp = fopen(filepath, "rb");
  if(!fp) {
    ad_error("open file : %s error", filepath);
  }

  uint8_t* buffer = NULL;
  // read riff header
  struct riff_header riff;
  check(_read_riff(fp, &riff), "read riff header error");

  // read wave format
  struct wav_format wav_fmt;
  _read_wave_foramt(fp, &wav_fmt);


  // read wave data
  struct wav_data data_fmt;
  for(;;) {
    check(_read_wave_data(fp, &data_fmt), "read wave data error");
    if(memcmp(data_fmt.subchunk_id, "data", 4)==0){
      break;
    }else {
      fseek(fp, data_fmt.subchunk_sz, SEEK_CUR); // jump not need chunk
    }
  }
  
  buffer = malloc(data_fmt.subchunk_sz);
  check(buffer, "malloc buffer error");

  check(_read_buffer(fp, buffer, data_fmt.subchunk_sz), "read buffer error");

  //
  strcpy(out->type, "wav");
  out->freq = wav_fmt.sample_rate;
  out->data = buffer;
  out->size = data_fmt.subchunk_sz;

  // set format
  if(wav_fmt.num_channels==1){
    if(wav_fmt.bits_per_sample==8)
      out->format = AL_FORMAT_MONO8;
    else if(wav_fmt.bits_per_sample==16)
      out->format = AL_FORMAT_MONO16;
    else {
      ad_error("not support format");
      goto EXIT;
    }
  }else if (wav_fmt.num_channels==2){
    if(wav_fmt.bits_per_sample==8)
      out->format=AL_FORMAT_STEREO8;
    else if(wav_fmt.bits_per_sample==16)
      out->format=AL_FORMAT_STEREO16;
    else{
     ad_error("not support format"); 
     goto EXIT;
    }
  }else {
     ad_error("not support format"); 
     goto EXIT;
  }
  ret = out;

EXIT:
  fclose(fp);
  if(buffer && !ret) free(buffer);
  return ret;
}


int
adl_decode_wav(lua_State* L) {
  const char* file = lua_tostring(L, 1);
  struct oal_info out = {0};
  if(_decode_wav(file, &out)){
    return ad_new_info(L, &out);
  } else {
    luaL_error(L, ad_last_error());
  }
  return 0;
}

