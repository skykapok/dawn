package com.android.gl2jni;

public class GL2JNILib {

	static {
		System.loadLibrary("ejoy2d");
	}

	public static native void oncreate(String path);
	public static native void ondestroy();
	public static native void onsurfacechanged(int width, int height);
	public static native void ondrawframe(float dt);
	public static native void ontouchevent(int x, int y, int touch);
}
