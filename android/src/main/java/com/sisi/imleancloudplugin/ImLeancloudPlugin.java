package com.sisi.imleancloudplugin;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/**
 * ImLeancloudPlugin
 */
public class ImLeancloudPlugin implements MethodCallHandler {
    private static Context _applicationContext;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "im_leancloud_plugin");
        channel.setMethodCallHandler(new ImLeancloudPlugin(registrar, channel));
        _applicationContext = registrar.context().getApplicationContext();
    }

    public static ImLeancloudPlugin instance;
    private final Registrar registrar;
    public final MethodChannel channel;
    //public final Map<Integer, Result> callbackMap;

    private ImLeancloudPlugin(Registrar registrar, MethodChannel channel) {
        this.registrar = registrar;
        this.channel = channel;
        //this.callbackMap = new HashMap<>();
        instance = this;
    }


    @Override
    public void onMethodCall(MethodCall call, Result result) {

        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "initialize":
                LeancloudFunction.initialize(call, result, _applicationContext);
                break;
            case "onLoginClick":
                LeancloudFunction.onLoginClick((String) call.arguments);
                break;
            case "setLogLevel":
                LeancloudFunction.setLogLevel(call, result);
                break;
            case "getConversation":
                LeancloudMessage.getConversation(call, result);
                break;
            case "sendText":
                LeancloudMessage.sendText(call, result);
                break;
            case "sendImage":
                LeancloudMessage.sendImage(call, result);
                break;
            case "sendAudio":
                LeancloudMessage.sendAudio(call, result);
                break;
            case "conversationRead":
                LeancloudMessage.conversationRead();
                break;
            case "queryUnreadMessages":
                LeancloudMessage.queryUnreadMessages(call, result);
                break;
            case "signoutClick":
                LeancloudFunction.signoutClick();
                break;

            default:
                result.notImplemented();
        }


    }
//传送消息
    public void onReceiveMessage(String comversationId, String content, String getfrom) {

        Map<String, Object> notification = new HashMap<>();
        notification.put("conversationId", comversationId);
        notification.put("content", content);
        notification.put("getfrom", getfrom);
        ImLeancloudPlugin.instance.channel.invokeMethod("onReceiveMessage", notification);

    }
    //unRead传送未读的会话以及数目
    public void unRead(String comversationId, int unreadcount) {
        Map<String, Object> unread = new HashMap<>();
        unread.put("conversationId", comversationId);
        unread.put("unreadcount", unreadcount);
        System.out.println("unreadcount:"+unreadcount);
        ImLeancloudPlugin.instance.channel.invokeMethod("unRead", unread);
    }





}
