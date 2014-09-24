package com.android.gl2jni;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.app.Application;
import android.content.Context;
import android.content.res.AssetManager;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public class GL2JNIActivity extends Activity {
	private static String TAG = "EJOY2D";
	GL2JNIView mView;

	@Override protected void onCreate(Bundle icicle) {
		super.onCreate(icicle);

		String path = getFilesDir().getAbsolutePath();
		GL2JNILib.init(path);

		SharedPreferences preference = PreferenceManager.getDefaultSharedPreferences(this);
		if (!preference.getBoolean("installed", false)) {
			preference.edit().putBoolean("installed", true).commit();
			Log.e(TAG, "copying assets to data path");
			copyAssetFolder(getAssets(), "files", path);
		}

		mView = new GL2JNIView(getApplication());
		setContentView(mView);
	}

	@Override protected void onPause() {
		super.onPause();
		mView.onPause();
	}

	@Override protected void onResume() {
		super.onResume();
		mView.onResume();
	}

	private boolean copyAssetFolder(AssetManager assetManager, String fromAssetPath, String toPath) {
		try {
			String[] files = assetManager.list(fromAssetPath);
			new File(toPath).mkdirs();
			boolean res = true;
			for (String file : files) {
				if (file.contains("."))
					res &= copyAsset(assetManager, fromAssetPath + "/" + file, toPath + "/" + file);
				else
					res &= copyAssetFolder(assetManager, fromAssetPath + "/" + file, toPath + "/" + file);
			}
			return res;
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	private boolean copyAsset(AssetManager assetManager, String fromAssetPath, String toPath) {
		InputStream in = null;
		OutputStream out = null;
		try {
			in = assetManager.open(fromAssetPath);
			new File(toPath).createNewFile();
			out = new FileOutputStream(toPath);
			copyFile(in, out);
			in.close();
			in = null;
			out.flush();
			out.close();
			out = null;
			Log.e(TAG, toPath + " copied");
			return true;
		} catch(Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	private void copyFile(InputStream in, OutputStream out) throws IOException {
		byte[] buffer = new byte[1024];
		int read;
		while ((read = in.read(buffer)) != -1){
			out.write(buffer, 0, read);
		}
	}
}
