package com.facebook.react.uimanager;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;

import io.flutter.plugin.common.MethodChannel;
import kotlin.jvm.functions.Function0;

public class ThemedReactContext extends ReactContext {
    private final int surfaceId = 0;

    public ThemedReactContext(ReactApplicationContext context, MethodChannel channel, Function0<?> sdkAccessor) {
        super(context.getCurrentActivity(), channel, sdkAccessor);
    }

    public int getSurfaceId() {
        return surfaceId;
    }
}
