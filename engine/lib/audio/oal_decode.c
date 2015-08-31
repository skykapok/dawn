#include "oal_decode.h"
#include <stdlib.h>


int adl_decode_caf(lua_State* L);
int adl_decode_mp3(lua_State* L);
int adl_decode_hardware_ios(lua_State* L);
int adl_decode_wav(lua_State* L);
int adl_decode_tools(lua_State* L);



static char _last_error[512] = {0};
void
ad_error(const char* f, ...) {
  va_list args;
  va_start(args, f);
  vsnprintf(_last_error, sizeof(_last_error)-1, f, args);
  va_end(args);
}

void od_free_info(struct oal_info* info) {
  free(info->data);
  info->data = NULL;
}


const char* 
ad_last_error() {
  return _last_error;
}

static int
_info_gc(lua_State* L) {
  struct oal_info* p = (struct oal_info*)lua_touserdata(L, 1);
  od_free_info(p);
  return 0;
}

static int
_info_tostring(lua_State* L) {
  struct oal_info* p = (struct oal_info*)lua_touserdata(L, 1);
  char buffer[128] = {0};
  sprintf(buffer, "type:%s format: %d freq: %d size:%d", p->type, p->format, p->freq, p->size);
  lua_pushstring(L, buffer);
  return 1;
}


int
ad_new_info(lua_State* L, struct oal_info* info) {
  struct oal_info* p = (struct oal_info*)lua_newuserdata(L, sizeof(*info));
  *p = *info;
  if(luaL_newmetatable(L, "oal_info")) {
    lua_pushcfunction(L, _info_gc);
    lua_setfield(L, -2, "__gc");
    lua_pushcfunction(L, _info_tostring);
    lua_setfield(L, -2, "__tostring");
  }

  lua_setmetatable(L, -2);
  return 1;
}



int
luaopen_oal_decode(lua_State* L) {
  luaL_checkversion(L);
  luaL_Reg l[] = {
    {"decode_tools", adl_decode_tools},
    {"decode_mp3", adl_decode_mp3},
    {"decode_wav", adl_decode_wav},
    {NULL, NULL},
  };

  luaL_newlib(L, l);
  adl_decode_hardware_ios(L);
  lua_setfield(L, -2, "decode_hardware_ios");
  return 1;
}


