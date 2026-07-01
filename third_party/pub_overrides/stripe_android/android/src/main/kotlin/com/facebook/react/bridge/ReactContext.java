package com.facebook.react.bridge;

import androidx.appcompat.view.ContextThemeWrapper;
import androidx.fragment.app.FragmentActivity;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.UIManagerModule;

import io.flutter.plugin.common.MethodChannel;
import kotlin.jvm.functions.Function0;

public class ReactContext extends ContextThemeWrapper {
    private final FragmentActivity currentActivity;
    private final MethodChannel channel;
    private final Function0<?> sdkAccessor;

    public ReactContext(FragmentActivity currentActivity, MethodChannel channel, Function0<?> sdkAccessor) {
        super(currentActivity, androidx.appcompat.R.style.Theme_AppCompat_Light_NoActionBar);
        this.currentActivity = currentActivity;
        this.channel = channel;
        this.sdkAccessor = sdkAccessor;
    }

    public FragmentActivity getCurrentActivity() {
        return currentActivity;
    }

    public ReactApplicationContext getReactApplicationContext() {
        Object sdk = sdkAccessor.invoke();
        try {
            Object value = sdk.getClass().getMethod("getReactApplicationContext").invoke(sdk);
            return (ReactApplicationContext) value;
        } catch (Exception error) {
            throw new IllegalStateException("Unable to resolve ReactApplicationContext", error);
        }
    }

    @SuppressWarnings("unchecked")
    public <T> T getNativeModule(Class<T> clazz) {
        if (clazz == UIManagerModule.class) {
            return (T) new UIManagerModule(channel);
        }
        return (T) sdkAccessor.invoke();
    }

    @SuppressWarnings("unchecked")
    public <T> T getJSModule(Class<T> clazz) {
        return (T) new DeviceEventManagerModule.RCTDeviceEventEmitter(channel);
    }
}
