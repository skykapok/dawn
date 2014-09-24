LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := ejoy2d

LOCAL_SRC_FILES := main.c font.c

LOCAL_SRC_FILES += \
                   ../../../engine/lib/dfont.c \
                   ../../../engine/lib/ejoy2dgame.c \
                   ../../../engine/lib/fault.c \
                   ../../../engine/lib/label.c \
                   ../../../engine/lib/lmatrix.c \
                   ../../../engine/lib/lparticle.c \
                   ../../../engine/lib/lshader.c \
                   ../../../engine/lib/lsprite.c \
                   ../../../engine/lib/matrix.c \
                   ../../../engine/lib/particle.c \
                   ../../../engine/lib/ppm.c \
                   ../../../engine/lib/scissor.c \
                   ../../../engine/lib/screen.c \
                   ../../../engine/lib/shader.c \
                   ../../../engine/lib/sprite.c \
                   ../../../engine/lib/spritepack.c \
                   ../../../engine/lib/texture.c \
                   ../../../engine/platform/winfw.c

LOCAL_SRC_FILES += \
                   ../../../engine/lua/lapi.c \
                   ../../../engine/lua/lauxlib.c \
                   ../../../engine/lua/lbaselib.c \
                   ../../../engine/lua/lbitlib.c \
                   ../../../engine/lua/lcode.c \
                   ../../../engine/lua/lcorolib.c \
                   ../../../engine/lua/lctype.c \
                   ../../../engine/lua/ldblib.c \
                   ../../../engine/lua/ldebug.c \
                   ../../../engine/lua/ldo.c \
                   ../../../engine/lua/ldump.c \
                   ../../../engine/lua/lfunc.c \
                   ../../../engine/lua/lgc.c \
                   ../../../engine/lua/linit.c \
                   ../../../engine/lua/liolib.c \
                   ../../../engine/lua/llex.c \
                   ../../../engine/lua/lmathlib.c \
                   ../../../engine/lua/lmem.c \
                   ../../../engine/lua/loadlib.c \
                   ../../../engine/lua/lobject.c \
                   ../../../engine/lua/lopcodes.c \
                   ../../../engine/lua/loslib.c \
                   ../../../engine/lua/lparser.c \
                   ../../../engine/lua/lstate.c \
                   ../../../engine/lua/lstring.c \
                   ../../../engine/lua/lstrlib.c \
                   ../../../engine/lua/ltable.c \
                   ../../../engine/lua/ltablib.c \
                   ../../../engine/lua/ltm.c \
                   ../../../engine/lua/lundump.c \
                   ../../../engine/lua/lvm.c \
                   ../../../engine/lua/lzio.c

LOCAL_C_INCLUDES := $(LOCAL_PATH) \
                    $(LOCAL_PATH)/../../../engine/lib \
                    $(LOCAL_PATH)/../../../engine/platform \
                    $(LOCAL_PATH)/../../../engine/lua

LOCAL_CFLAGS += -std=c99
LOCAL_LDLIBS := -llog -lGLESv2

include $(BUILD_SHARED_LIBRARY)
