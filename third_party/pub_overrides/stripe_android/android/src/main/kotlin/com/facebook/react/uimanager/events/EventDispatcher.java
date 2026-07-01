package com.facebook.react.uimanager.events;

import com.facebook.react.bridge.ReadableMap;

public interface EventDispatcher {
    void dispatchEvent(Event<?> event);

    void invoke(String name, ReadableMap value);

    void invoke(String name);
}
