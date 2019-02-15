package com.sisi.imleancloudplugin.handler;

import android.content.Context;
import android.content.Intent;

import com.avos.avoscloud.AVCallback;
import com.avos.avoscloud.AVException;
import com.avos.avoscloud.im.v2.AVIMClient;
import com.avos.avoscloud.im.v2.AVIMConversation;
import com.avos.avoscloud.im.v2.AVIMTypedMessage;
import com.avos.avoscloud.im.v2.AVIMTypedMessageHandler;
import com.avos.avoscloud.im.v2.messages.AVIMTextMessage;

import com.sisi.imleancloudplugin.LCChatKit;
import com.sisi.imleancloudplugin.LCChatKitUser;
import com.sisi.imleancloudplugin.ImLeancloudPlugin;
import com.sisi.imleancloudplugin.R;
import com.sisi.imleancloudplugin.cache.LCIMConversationItemCache;
import com.sisi.imleancloudplugin.cache.LCIMProfileCache;
import com.sisi.imleancloudplugin.event.LCIMIMTypeMessageEvent;
import com.sisi.imleancloudplugin.utils.LCIMConstants;
import com.sisi.imleancloudplugin.utils.LCIMLogUtils;
import com.sisi.imleancloudplugin.utils.LCIMNotificationUtils;

import java.util.HashMap;
import java.util.Map;

import de.greenrobot.event.EventBus;



/**
 * Created by zhangxiaobo on 15/4/20.
 * AVIMTypedMessage 的 handler，socket 过来的 AVIMTypedMessage 都会通过此 handler 与应用交互
 * 需要应用主动调用 AVIMMessageManager.registerMessageHandler 来注册
 * 当然，自定义的消息也可以通过这种方式来处理
 */
public class LCIMMessageHandler extends AVIMTypedMessageHandler<AVIMTypedMessage> {

  private Context context;

  public LCIMMessageHandler(Context context) {
    this.context = context.getApplicationContext();
  }

  @Override
  public void onMessage(AVIMTypedMessage message, AVIMConversation conversation, AVIMClient client) {
    if (message == null || message.getMessageId() == null) {
      LCIMLogUtils.d("may be SDK Bug, message or message id is null");
      return;
    }

    if (LCChatKit.getInstance().getCurrentUserId() == null) {
      LCIMLogUtils.d("selfId is null, please call LCChatKit.open!");
      client.close(null);
    } else {
      if (!client.getClientId().equals(LCChatKit.getInstance().getCurrentUserId())) {
        client.close(null);
      } else {
        if (LCIMNotificationUtils.isShowNotification(conversation.getConversationId())) {
          sendNotification(message, conversation);
        }
        LCIMConversationItemCache.getInstance().insertConversation(message.getConversationId());
        if (!message.getFrom().equals(client.getClientId())) {
          System.out.println(message.getContent());
          ImLeancloudPlugin.instance.onReceiveMessage(message.getConversationId(),message.getContent(),message.getFrom());
          sendEvent(message, conversation);
        }
      }
    }
  }

  @Override
  public void onMessageReceipt(AVIMTypedMessage message, AVIMConversation conversation, AVIMClient client) {
    super.onMessageReceipt(message, conversation, client);
  }

  /**
   * 发送消息到来的通知事件
   *
   * @param message
   * @param conversation
   */
  private void sendEvent(AVIMTypedMessage message, AVIMConversation conversation) {
    LCIMIMTypeMessageEvent event = new LCIMIMTypeMessageEvent();
    event.message = message;
    event.conversation = conversation;
    EventBus.getDefault().post(event);
  }

  private void sendNotification(final AVIMTypedMessage message, final AVIMConversation conversation) {
    if (null != conversation && null != message) {

      final String notificationContent = message instanceof AVIMTextMessage ?
        ((AVIMTextMessage) message).getText() : "不支持的消息类型";
       // ImLeancloudPlugin.instance.onReceiveMessage();
        // System.out.println(notificationContent);


       LCIMProfileCache.getInstance().getCachedUser(message.getFrom(), new AVCallback<LCChatKitUser>() {
        @Override
        protected void internalDone0(LCChatKitUser userProfile, AVException e) {
          if (e != null) {
            LCIMLogUtils.logException(e);
          } else if (null != userProfile) {
            String title = userProfile.getName();
            //Intent intent = getIMNotificationIntent(conversation.getConversationId(), message.getFrom());
            //LCIMNotificationUtils.showNotification(context, title, notificationContent, null, intent);
            System.out.println(title);
            System.out.println(notificationContent);
          }
        }
      });
    }
  }

  /**
   * 点击 notification 触发的 Intent
   * 注意要设置 package 已经 Category，避免多 app 同时引用 lib 造成消息干扰
   * @param conversationId
   * @param peerId
   * @return
   */
  private Intent getIMNotificationIntent(String conversationId, String peerId) {
    Intent intent = new Intent();
    intent.setAction(LCIMConstants.CHAT_NOTIFICATION_ACTION);
    intent.putExtra(LCIMConstants.CONVERSATION_ID, conversationId);
    intent.putExtra(LCIMConstants.PEER_ID, peerId);
    intent.setPackage(context.getPackageName());
    intent.addCategory(Intent.CATEGORY_DEFAULT);
    return intent;
  }
}