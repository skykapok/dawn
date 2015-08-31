#ifndef _OAL_H_
#define _OAL_H_

#include <lua.h>

// call after interruption starts
void oal_interrupted();

// call after interruption ends
void oal_resumed();

int luaopen_oal(lua_State* L);

#endif