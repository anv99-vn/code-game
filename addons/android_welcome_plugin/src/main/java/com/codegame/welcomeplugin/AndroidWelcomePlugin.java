package com.codegame.welcomeplugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.widget.Toast;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public final class AndroidWelcomePlugin extends GodotPlugin {

    private static final String PLUGIN_NAME = "AndroidWelcomePlugin";
    private static final int DEFAULT_TOAST_DURATION = Toast.LENGTH_LONG;

    private final Activity activity;
    private final Handler mainThreadHandler = new Handler(Looper.getMainLooper());

    public AndroidWelcomePlugin(Godot godot) {
        super(godot);
        activity = godot.getActivity();
    }

    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }

    @UsedByGodot
    public void showToast(String message) {
        showToast(message, DEFAULT_TOAST_DURATION);
    }

    @UsedByGodot
    public void showToast(String message, int duration) {
        mainThreadHandler.post(() -> {
            Toast toast = Toast.makeText(activity, message, duration);
            toast.setGravity(Gravity.TOP | Gravity.CENTER_HORIZONTAL, 0, 0);
            toast.show();
        });
    }

    @UsedByGodot
    public int getBatteryPercent() {
        BatteryManager batteryManager =
                (BatteryManager) activity.getSystemService(Context.BATTERY_SERVICE);
        if (batteryManager == null) {
            return -1;
        }
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
    }

    @UsedByGodot
    public int isBatteryCharging() {
        Intent batteryStatus = activity.registerReceiver(
                null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        if (batteryStatus == null) {
            return -1;
        }

        int status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
        if (status == -1) {
            return -1;
        }

        return status == BatteryManager.BATTERY_STATUS_CHARGING
                || status == BatteryManager.BATTERY_STATUS_FULL ? 1 : 0;
    }
}
