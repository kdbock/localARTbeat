package com.facebook.react.bridge;

public class DynamicFromObject extends Dynamic {
    public final Object value;

    public DynamicFromObject(Object value) {
        this.value = value;
    }

    public void recycle() {}

    public boolean isNull() {
        return value == null;
    }

    public boolean asBoolean() {
        return (Boolean) value;
    }

    public double asDouble() {
        return ((Number) value).doubleValue();
    }

    public int asInt() {
        return ((Number) value).intValue();
    }

    public String asString() {
        return (String) value;
    }

    public ReadableArray asArray() {
        return (ReadableArray) value;
    }

    @Override
    public ReadableMap asMap() {
        return (ReadableMap) value;
    }

    public ReadableType getType() {
        if (value == null) return ReadableType.Null;
        if (value instanceof Boolean) return ReadableType.Boolean;
        if (value instanceof Number) return ReadableType.Number;
        if (value instanceof String) return ReadableType.String;
        if (value instanceof ReadableMap) return ReadableType.Map;
        if (value instanceof ReadableArray) return ReadableType.Array;
        return ReadableType.Null;
    }
}
