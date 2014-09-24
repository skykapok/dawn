package com.android.gl2jni;

public class GL2JNILib {

	static {
		System.loadLibrary("ejoy2d");
	}

	public static native void init(String path);
	public static native void change(int width, int height);
	public static native void update(float dt);
}
