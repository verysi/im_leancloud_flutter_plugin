package com.sisi.imleancloudplugin;

import android.content.Context;

import com.alibaba.fastjson.JSON;
import com.avos.avoscloud.im.v2.AVIMConversation;
import com.avos.avoscloud.im.v2.AVIMTypedMessage;

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

    private ImLeancloudPlugin(Registrar registrar, MethodChannel channel) {
        this.registrar = registrar;
        this.channel = channel;
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
                LeancloudFunction.onLoginClick(call, result);
                break;
            case "setLogLevel":
                LeancloudFunction.setLogLevel(call, result);
                break;
            case "uploadFile":
                LeancloudFunction.uploadFile(call, result);
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
            case "sendVideo":
                LeancloudMessage.sendVideo(call, result);
                break;
            case "conversationRead":
                LeancloudMessage.conversationRead();
                break;
            case "queryUnreadMessages":
                LeancloudMessage.queryUnreadMessages(call, result);
                break;
            case "queryHistoryMessages":
                LeancloudMessage.queryHistoryMessages(call, result);
                break;
            case "signoutClick":
                LeancloudFunction.signoutClick();
                break;
            case "conversationList":
                LeancloudMessage.conversationList(call, result);
                break;
            default:
                result.notImplemented();
        }


    }

    //接收消息
    public void onReceiveMessage(AVIMTypedMessage message) {

        Map<String, Object> notification = new HashMap<>();
        notification.put("conversationId", message.getConversationId());
        notification.put("content", message.getContent());
        notification.put("getfrom", message.getFrom());
        notification.put("Timestamp",message.getTimestamp());
        notification.put("MessageType",message.getMessageType());
        ImLeancloudPlugin.instance.channel.invokeMethod("onReceiveMessage", notification);

    }

    //unRead传送未读的会话以及数目
    public void unRead(AVIMConversation conv) {
        Map<String, Object> convmap = new HashMap<>();
        convmap.put("conversationId", conv.getConversationId());
        convmap.put("UnreadMessagesCount", conv.getUnreadMessagesCount());
        convmap.put("getMembers", conv.getMembers());
        convmap.put("getName", conv.getName());
        String jsonconversation = JSON.toJSONString(convmap);


        Map<String, Object> unReadmap = new HashMap<>();
        unReadmap.put("unRead", jsonconversation);
        ImLeancloudPlugin.instance.channel.invokeMethod("unRead", unReadmap);
    }

    //用于判断是否已读
    public void onLastReadAtUpdated(AVIMConversation conv) {
        Map<String, Object> convmap = new HashMap<>();
        convmap.put("conversationId", conv.getConversationId());
        convmap.put("getMembers", conv.getMembers());
        convmap.put("LastReadAt", conv.getLastReadAt());
        convmap.put("getName", conv.getName());
        String jsonconversation = JSON.toJSONString(convmap);

        Map<String, Object> LastReadAtmap = new HashMap<>();
        LastReadAtmap.put("LastReadAt", jsonconversation);
        ImLeancloudPlugin.instance.channel.invokeMethod("onLastReadAtUpdated", LastReadAtmap);
    }
//更新会话接收时间
    public void onLastDeliveredAtUpdated(AVIMConversation conv) {
        Map<String, Object> convmap = new HashMap<>();
        convmap.put("conversationId", conv.getConversationId());
        convmap.put("getMembers", conv.getMembers());
        convmap.put("LastDelivered", conv.getLastDeliveredAt());
        convmap.put("getName", conv.getName());
        String jsonconversation = JSON.toJSONString(convmap);

        Map<String, Object> LastDeliveredmap = new HashMap<>();
        LastDeliveredmap.put("LastDeliveredAt", jsonconversation);
        ImLeancloudPlugin.instance.channel.invokeMethod("onLastDeliveredAtUpdated", LastDeliveredmap);
    }

}
