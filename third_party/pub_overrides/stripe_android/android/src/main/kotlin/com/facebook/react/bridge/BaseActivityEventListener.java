package com.facebook.react.bridge;

import android.app.Activity;
import android.content.Intent;

import java.lang.ref.WeakReference;

import io.flutter.plugin.common.PluginRegistry;

public class BaseActivityEventListener implements ActivityEventListener, PluginRegistry.ActivityResultListener {
    public WeakReference<Activity> activity;

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        Activity currentActivity = activity == null ? null : activity.get();
        if (currentActivity != null) {
            onActivityResult(currentActivity, requestCode, resultCode, data);
        }
        return false;
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {}
}
