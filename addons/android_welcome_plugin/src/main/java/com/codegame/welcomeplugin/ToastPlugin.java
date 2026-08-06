package com.codegame.welcomeplugin;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.widget.Toast;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public class ToastPlugin extends GodotPlugin {

    private Activity activity;

    public ToastPlugin(Godot godot) {
        super(godot);
        this.activity = godot.getActivity();
    }

    @Override
    public String getPluginName() {
        return "ToastPlugin";
    }

    @UsedByGodot
    public void showToast(final String message) {
        showToast(message, 1);
    }

    @UsedByGodot
    public void showToast(final String message, final int duration) {
        new Handler(Looper.getMainLooper()).post(() -> {
            Toast toast = Toast.makeText(activity, message, duration);
            toast.setGravity(Gravity.TOP | Gravity.CENTER_HORIZONTAL, 0, 0);
            toast.show();
        });
    }
}
