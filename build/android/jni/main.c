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

static char data_path[1024];
static float t;

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_init(JNIEnv *env, jobject obj, jstring path) {
	const char *p = (*env)->GetStringUTFChars(env, path, 0);
	memset(data_path, 0, sizeof(data_path));
	strcpy(data_path, p);
	(*env)->ReleaseStringUTFChars(env, path, p);
	LOGI("APP_DATA_PATH %s", data_path);
}

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_change(JNIEnv *env, jobject obj, jint width, jint height) {
	LOGI("GL Version = %s", glGetString(GL_VERSION));
	LOGI("GL Vendor = %s", glGetString(GL_VENDOR));
	LOGI("GL Renderer = %s", glGetString(GL_RENDERER));
	LOGI("GL Extensions = %s", glGetString(GL_EXTENSIONS));
	LOGI("InitGL(%d, %d)", width, height);

	t = 0;
	ejoy2d_win_init(0, 0, width, height, 1.0f, data_path);
}

JNIEXPORT void JNICALL
Java_com_android_gl2jni_GL2JNILib_update(JNIEnv *env, jobject obj, jfloat dt) {
	t += dt;
	while (t > FRAME_TIME) {
		t -= FRAME_TIME;
		ejoy2d_win_update(FRAME_TIME);
		ejoy2d_win_frame();
	}
}
