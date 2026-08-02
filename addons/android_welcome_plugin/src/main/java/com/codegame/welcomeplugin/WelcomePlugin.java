package com.codegame.welcomeplugin;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public class WelcomePlugin extends GodotPlugin {

    private Activity activity;

    public WelcomePlugin(Godot godot) {
        super(godot);
        this.activity = godot.getActivity();
    }

    @Override
    public String getPluginName() {
        return "WelcomePlugin";
    }

    @UsedByGodot
    public void showToast(final String message) {
        new Handler(Looper.getMainLooper()).post(() -> {
            Toast.makeText(activity, message, Toast.LENGTH_LONG).show();
        });
    }
}
