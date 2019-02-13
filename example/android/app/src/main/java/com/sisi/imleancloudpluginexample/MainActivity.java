package com.sisi.imleancloudpluginexample;

import android.os.Bundle;

import com.avos.avoscloud.PushService;
import com.avos.avoscloud.im.v2.AVIMClient;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    //AVIMClient.setAutoOpen(true);
    //PushService.setDefaultPushCallback(this, MainActivity.class);
    //PushService.setAutoWakeUp(true);
    //PushService.setDefaultChannelId(this, "default");

  }
}
