package com.facebook.react.uimanager;

import android.view.View;

public class BaseViewManager<T extends View, U> {
    public boolean needsCustomLayoutForChildren() {
        return false;
    }
}
