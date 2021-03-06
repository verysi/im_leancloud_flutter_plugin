package com.sisi.imleancloudplugin.handler;

import com.avos.avoscloud.im.v2.AVIMClient;
import com.avos.avoscloud.im.v2.AVIMMessage;
import com.avos.avoscloud.im.v2.AVIMConversation;
import com.avos.avoscloud.im.v2.AVIMConversationEventHandler;

import java.util.List;


import com.sisi.imleancloudplugin.ImLeancloudPlugin;
import com.sisi.imleancloudplugin.cache.LCIMConversationItemCache;
import com.sisi.imleancloudplugin.event.LCIMConversationReadStatusEvent;


/**
 * Created by wli on 15/12/1.
 * 和 Conversation 相关的事件的 handler
 * 需要应用主动调用  AVIMMessageManager.setConversationEventHandler
 * 关于回调会何时执行可以参见 https://leancloud.cn/docs/realtime_guide-android.html#添加其他成员
 */
public class LCIMConversationHandler extends AVIMConversationEventHandler {

    private static LCIMConversationHandler eventHandler;

    public static synchronized LCIMConversationHandler getInstance() {
        if (null == eventHandler) {
            eventHandler = new LCIMConversationHandler();
        }
        return eventHandler;
    }

    private LCIMConversationHandler() {
    }

    @Override
    public void onUnreadMessagesCountUpdated(AVIMClient client, AVIMConversation conversation) {
        LCIMConversationItemCache.getInstance().insertConversation(conversation.getConversationId());
        AVIMMessage lastMessage = conversation.getLastMessage();
        System.out.println("LCIMConversationHandler#onUnreadMessagesCountUpdated conv=" + conversation.getConversationId() + ", lastMsg: " + lastMessage.getContent());
        System.out.println(lastMessage.getContent());
        ImLeancloudPlugin.instance.unRead(conversation);
    }

    @Override
    public void onLastDeliveredAtUpdated(AVIMClient client, AVIMConversation conversation) {
        System.out.println("onLastDeliveredAtUpdated");
        System.out.println(conversation.getConversationId());
        System.out.println(conversation.getName());
        System.out.println(conversation.getMembers());
        ImLeancloudPlugin.instance.onLastDeliveredAtUpdated(conversation);
        //LCIMConversationReadStatusEvent event = new LCIMConversationReadStatusEvent();
       // event.conversationId = conversation.getConversationId();
    }

    @Override
    public void onLastReadAtUpdated(AVIMClient client, AVIMConversation conversation) {
        System.out.println("onLastReadAtUpdated");
        System.out.println(conversation.getLastReadAt());
        System.out.println(conversation.getConversationId());
        System.out.println(conversation.getName());
        System.out.println(conversation.getMembers());
        ImLeancloudPlugin.instance.onLastReadAtUpdated(conversation);


       // LCIMConversationReadStatusEvent event = new LCIMConversationReadStatusEvent();
      //  event.conversationId = conversation.getConversationId();


    }

    @Override
    public void onMemberLeft(AVIMClient client, AVIMConversation conversation, List<String> members, String kickedBy) {
        // 因为不同用户需求不同，此处暂不做默认处理，如有需要，用户可以通过自定义 Handler 实现
    }

    @Override
    public void onMemberJoined(AVIMClient client, AVIMConversation conversation, List<String> members, String invitedBy) {
    }

    @Override
    public void onKicked(AVIMClient client, AVIMConversation conversation, String kickedBy) {
    }

    @Override
    public void onInvited(AVIMClient client, AVIMConversation conversation, String operator) {
    }

    @Override
    public void onMessageRecalled(AVIMClient client, AVIMConversation conversation, AVIMMessage message) {

    }

    @Override
    public void onMessageUpdated(AVIMClient client, AVIMConversation conversation, AVIMMessage message) {

    }

}
