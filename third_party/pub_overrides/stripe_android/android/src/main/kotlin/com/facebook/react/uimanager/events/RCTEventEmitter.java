package com.facebook.react.uimanager.events;

import com.facebook.react.bridge.ReadableMap;

import io.flutter.plugin.common.MethodChannel;

public class RCTEventEmitter {
    private final MethodChannel channel;

    public RCTEventEmitter(MethodChannel channel) {
        this.channel = channel;
    }

    public void receiveEvent(Object viewTag, String eventName, ReadableMap serializeEventData) {
        channel.invokeMethod(eventName, serializeEventData);
    }
}
