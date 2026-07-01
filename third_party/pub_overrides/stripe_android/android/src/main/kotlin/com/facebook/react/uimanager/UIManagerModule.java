package com.facebook.react.uimanager;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.events.Event;
import com.facebook.react.uimanager.events.EventDispatcher;
import com.facebook.react.uimanager.events.RCTEventEmitter;

import io.flutter.plugin.common.MethodChannel;

public class UIManagerModule {
    private final RCTEventEmitter rctInstance;
    private final EventDispatcher eventDispatcher;

    public UIManagerModule(MethodChannel channel) {
        rctInstance = new RCTEventEmitter(channel);
        eventDispatcher = new EventDispatcher() {
            @Override
            public void dispatchEvent(Event<?> event) {
                event.dispatch(rctInstance);
            }

            @Override
            public void invoke(String name, ReadableMap value) {
                rctInstance.receiveEvent(name, name, value);
            }

            @Override
            public void invoke(String name) {
                rctInstance.receiveEvent(name, name, null);
            }
        };
    }

    public EventDispatcher getEventDispatcher() {
        return eventDispatcher;
    }
}
