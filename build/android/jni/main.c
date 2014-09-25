#include "winfw.h"

#include <jni.h>
#include <android/log.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <stdio.h>
#include <string.h>

#define LOG_TAG "EJOY2D"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#define FRAME_TIME (1.0f/30)

int font_module_init();
void font_module_destroy();

static char data_path[1024];
static int inited;
static float t;

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_oncreate(JNIEnv *env, jobject obj, jstring path) {
	const char *p = (*env)->GetStringUTFChars(env, path, 0);
	memset(data_path, 0, sizeof(data_path));
	strcpy(data_path, p);
	(*env)->ReleaseStringUTFChars(env, path, p);
	LOGI("APP_DATA_PATH %s", data_path);

	font_module_init();

	inited = 0;
}

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_ondestroy(JNIEnv *env, jobject obj) {
	ejoy2d_win_release();
	font_module_destroy();
}

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_onsurfacechanged(JNIEnv *env, jobject obj, jint width, jint height) {
	if (inited) {
		ejoy2d_win_release();
	}

	LOGI("GL Version = %s", glGetString(GL_VERSION));
	LOGI("GL Vendor = %s", glGetString(GL_VENDOR));
	LOGI("GL Renderer = %s", glGetString(GL_RENDERER));
	LOGI("GL Extensions = %s", glGetString(GL_EXTENSIONS));
	LOGI("InitGL(%d, %d)", width, height);

	ejoy2d_win_init(0, 0, width, height, 1.0f, data_path);

	t = 0;
	inited = 1;
}

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_ondrawframe(JNIEnv *env, jobject obj, jfloat dt) {
	t += dt;
	while (t > FRAME_TIME) {
		t -= FRAME_TIME;
		ejoy2d_win_update(FRAME_TIME);
		ejoy2d_win_frame();
	}
}
