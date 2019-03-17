package com.sisi.imleancloudplugin;

/**
 * Created by ruirui on 2019/1/28.
 */

import android.util.Log;

import com.alibaba.fastjson.JSON;
import com.avos.avoscloud.AVCallback;
import com.avos.avoscloud.AVException;
import com.avos.avoscloud.im.v2.AVIMClient;
import com.avos.avoscloud.im.v2.AVIMConversation;
import com.avos.avoscloud.im.v2.AVIMConversationsQuery;
import com.avos.avoscloud.im.v2.AVIMException;
import com.avos.avoscloud.im.v2.AVIMMessage;
import com.avos.avoscloud.im.v2.AVIMMessageOption;
import com.avos.avoscloud.im.v2.AVIMTemporaryConversation;
import com.avos.avoscloud.im.v2.callback.AVIMClientCallback;
import com.avos.avoscloud.im.v2.callback.AVIMConversationCallback;
import com.avos.avoscloud.im.v2.callback.AVIMConversationCreatedCallback;
import com.avos.avoscloud.im.v2.callback.AVIMConversationQueryCallback;
import com.avos.avoscloud.im.v2.callback.AVIMMessagesQueryCallback;
import com.avos.avoscloud.im.v2.messages.AVIMAudioMessage;
import com.avos.avoscloud.im.v2.messages.AVIMImageMessage;
import com.avos.avoscloud.im.v2.messages.AVIMTextMessage;
import com.avos.avoscloud.im.v2.messages.AVIMVideoMessage;
import com.sisi.imleancloudplugin.cache.LCIMConversationItemCache;
import com.sisi.imleancloudplugin.utils.LCIMConversationUtils;
import com.sisi.imleancloudplugin.utils.LCIMLogUtils;
import com.sisi.imleancloudplugin.utils.LCIMNotificationUtils;


import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class LeancloudMessage {
    protected static AVIMConversation imConversation;
    private static LeancloudMessage leancloudmessage;
    // private static AVIMMessage oldmessage;

    private LeancloudMessage() {

    }

    public static synchronized LeancloudMessage getInstance() {
        if (null == leancloudmessage) {
            leancloudmessage = new LeancloudMessage();
        }
        return leancloudmessage;
    }

    public static Map<String, Object> MessageToMap(AVIMMessage message) {
        Map<String, Object> messagemap = new HashMap<>();
        messagemap.put("conversationId", message.getConversationId());
        messagemap.put("content", message.getContent());
        messagemap.put("getfrom", message.getFrom());
        messagemap.put("MessageStatus", message.getMessageStatus());
        messagemap.put("MessageId", message.getMessageId());
        messagemap.put("Timestamp", message.getTimestamp());
        return messagemap;
    }

    public static String MessagesToMaps(List<AVIMMessage> messages) {
        List<Map<String, Object>> messagemaps = new ArrayList<>();
        int messageLength = messages.size();
        if (messageLength == 0) {
            messagemaps = null;
        } else if (messageLength == 1) {
            messagemaps.add(MessageToMap(messages.get(0)));
        } else {
            int i;
            for (i = 0; i < messageLength; i++) {
                messagemaps.add(MessageToMap(messages.get(i)));
            }
        }

        String json = JSON.toJSONString(messagemaps);
        return json;
    }


    static void getConversation(MethodCall call, final MethodChannel.Result result) {
        final String currentUser = LeancloudArgsConverter.getStringValue(call, result, "currentUser");
        final String memberId = LeancloudArgsConverter.getStringValue(call, result, "username");
        LCChatKit.getInstance().getClient().open(new AVIMClientCallback() {
            @Override
            public void done(AVIMClient client, AVIMException e) {
                if (e == null) {
                    client.createConversation(
                            Arrays.asList(memberId), "[" + currentUser + "," + memberId + "]", null, false, true, new AVIMConversationCreatedCallback() {
                                @Override
                                public void done(AVIMConversation avimConversation, AVIMException e) {
                                    if (null != e) {
                                        System.out.println(e.getMessage());
                                    } else {
                                        //updateConversation(avimConversation);
                                        LeancloudMessage.getInstance().imConversation = avimConversation;
                                        result.success(avimConversation.getConversationId());

                                    }
                                }
                            });
                }
            }
        });
    }

    protected static void updateConversation(AVIMConversation conversation) {
        if (null != conversation) {
            if (conversation instanceof AVIMTemporaryConversation) {
                System.out.println("Conversation expired flag: " + ((AVIMTemporaryConversation) conversation).isExpired());
            }
            //conversationFragment.setConversation(conversation);
            LCIMConversationItemCache.getInstance().insertConversation(conversation.getConversationId());
            LCIMConversationUtils.getConversationName(conversation, new AVCallback<String>() {
                @Override
                protected void internalDone0(String s, AVException e) {
                    if (null != e) {
                        LCIMLogUtils.logException(e);
                    } else {
                        //initActionBar(s);

                    }
                }
            });
        }
    }

    public static void conversationList(MethodCall call, final MethodChannel.Result result) {
        final String currentUser = LeancloudArgsConverter.getStringValue(call, result, "currentUser");
        AVIMClient cUser = AVIMClient.getInstance(currentUser);
        cUser.open(new AVIMClientCallback() {
            @Override
            public void done(AVIMClient client, AVIMException e) {
                if (e == null) {//登录成功
                    AVIMConversationsQuery query = client.getConversationsQuery();
                    query.limit(20);
                    query.findInBackground(new AVIMConversationQueryCallback() {
                        @Override
                        public void done(List<AVIMConversation> convs, AVIMException e) {
                            if (e == null) {
                                //convs就是获取到的conversation列表
                                //注意：按每个对话的最后更新日期（收到最后一条消息的时间）倒序排列
                                result.success(LeancloudMessage.jsonconversationList(convs));
                            }
                        }
                    });
                }
            }
        });
    }

    public static String jsonconversationList(List<AVIMConversation> convs) {
        List<Map<String, Object>> conversationmaps = new ArrayList<>();
        int conversationLength = convs.size();
        if (conversationLength > 0) {
            for (int i = 0; i < conversationLength; i++) {
                conversationmaps.add(conversationToMap(convs.get(i)));

            }
        } else {
            conversationmaps = null;
        }
        String jsonconversation = JSON.toJSONString(conversationmaps);
        return jsonconversation;
    }

    public static Map<String, Object> conversationToMap(AVIMConversation conv) {
        Map<String, Object> convmap = new HashMap<>();
        convmap.put("conversationId", conv.getConversationId());
        convmap.put("getMembers", conv.getMembers());
        convmap.put("getName", conv.getName());
        return convmap;
    }


    public static void conversationRead() {
        LeancloudMessage.getInstance().imConversation.read();
    }

    public void setConversation(final AVIMConversation conversation) {
        imConversation = conversation;
        fetchMessages();
        imConversation.read();
        LCIMNotificationUtils.addTag(conversation.getConversationId());
        if (!conversation.isTransient()) {
            if (conversation.getMembers().size() == 0) {
                conversation.fetchInfoInBackground(new AVIMConversationCallback() {
                    @Override
                    public void done(AVIMException e) {
                        if (null != e) {
                            LCIMLogUtils.logException(e);
                        }
                    }
                });
            } else {

            }
        } else {

        }
    }

    static void queryUnreadMessages(MethodCall call, final MethodChannel.Result result) {
        String conversationId = LeancloudArgsConverter.getStringValue(call, result, "conversationId");
        int unreadcount = LeancloudArgsConverter.getIntValue(call, result, "unreadcount");
        AVIMConversation conv = LCChatKit.getInstance().getClient().getConversation(conversationId);
        conv.queryMessages(unreadcount, new AVIMMessagesQueryCallback() {
            @Override
            public void done(List<AVIMMessage> messages, AVIMException e) {
                if (e == null) {
                    //成功获取最新消息记录
                    // List<Map> messagemaps = LeancloudMessage.MessagesToMaps(messages);
                    result.success(LeancloudMessage.MessagesToMaps(messages));

                }
            }
        });

    }

    static void queryHistoryMessages(MethodCall call, final MethodChannel.Result result) {
        final String conversationId = LeancloudArgsConverter.getStringValue(call, result, "conversationId");
        final String messageId = LeancloudArgsConverter.getStringValue(call, result, "messageId");
        final long Timestamp = (long) call.argument("Timestamp");
        final int pageSize = LeancloudArgsConverter.getIntValue(call, result, "pageSize");
        final AVIMConversation conv = LCChatKit.getInstance().getClient().getConversation(conversationId);

        conv.queryMessages(messageId, Timestamp, pageSize, new AVIMMessagesQueryCallback() {
            @Override
            public void done(List<AVIMMessage> nextPage, AVIMException e) {
                // nextPage 下一页聊天记录
                result.success(LeancloudMessage.MessagesToMaps(nextPage));

            }
        });


    }


    /**
     * 拉取消息，必须加入 conversation 后才能拉取消息
     */
    private void fetchMessages() {
        imConversation.queryMessages(new AVIMMessagesQueryCallback() {
            @Override
            public void done(List<AVIMMessage> messageList, AVIMException e) {
                if (filterException(e)) {
                    clearUnreadConut();
                }
            }
        });
    }

    /**
     * 发送文本消息
     *
     * @param
     */
    static void sendText(MethodCall call, MethodChannel.Result result) {
        AVIMTextMessage message = new AVIMTextMessage();
        String content = LeancloudArgsConverter.getStringValue(call, result, "content");
        String conversationId = LeancloudArgsConverter.getStringValue(call, result, "conversationId");
        message.setText(content);
        sendMessage(message, conversationId, result);
    }

    /**
     * 发送图片消息
     * 上传的图片最好要压缩一下
     *
     * @param
     */
    static void sendImage(MethodCall call, MethodChannel.Result result) {
        String imagePath = LeancloudArgsConverter.getStringValue(call, result, "imagePath");
        String conversationId = LeancloudArgsConverter.getStringValue(call, result, "conversationId");

        try {
            sendMessage(new AVIMImageMessage(imagePath), conversationId, result);
        } catch (IOException e) {
            LCIMLogUtils.logException(e);
        }
    }

    /**
     * 发送语音消息
     *
     * @param
     */
    static void sendAudio(MethodCall call, MethodChannel.Result result) {
        String audioPath = LeancloudArgsConverter.getStringValue(call, result, "audioPath");
        String conversationId = LeancloudArgsConverter.getStringValue(call, result, "conversationId");
        try {
            AVIMAudioMessage audioMessage = new AVIMAudioMessage(audioPath);
            sendMessage(audioMessage, conversationId, result);
        } catch (IOException e) {
            LCIMLogUtils.logException(e);
        }
    }


    /**
     * 发送视频消息
     *
     * @param
     */
    static void sendVideo(MethodCall call, MethodChannel.Result result) {
        String videoPath = LeancloudArgsConverter.getStringValue(call, result, "videoPath");
        String conversationId = LeancloudArgsConverter.getStringValue(call, result, "conversationId");
        try {
            AVIMVideoMessage videoMessage = new AVIMVideoMessage(videoPath);
            sendMessage(videoMessage, conversationId, result);
        } catch (IOException e) {
            LCIMLogUtils.logException(e);
        }
    }


    static void sendMessage(AVIMMessage message, String conversationId, MethodChannel.Result result) {
        sendMessage(message, true, conversationId, result);
    }

    /**
     * 发送消息
     *
     * @param message
     */
    static void sendMessage(AVIMMessage message, boolean addToList, String conversationId, final MethodChannel.Result result) {
        AVIMMessageOption option = new AVIMMessageOption();
        option.setReceipt(true);
        AVIMConversation avConversation = LCChatKit.getInstance().getClient().getConversation(conversationId);
        avConversation.sendMessage(message, option, new AVIMConversationCallback() {
            @Override
            public void done(AVIMException e) {
                System.out.println("消息发送成功");
                result.success("sendsuccess");


                if (null != e) {
                    LCIMLogUtils.logException(e);
                    System.out.println("消息发送失败");
                    result.success("sendfalse");
                }
            }
        });
    }


    private boolean filterException(Exception e) {
        if (null != e) {
            LCIMLogUtils.logException(e);
            //Toast.makeText(getContext(), e.getMessage(), Toast.LENGTH_SHORT).show();
        }
        return (null == e);
    }

    private void clearUnreadConut() {
        if (imConversation.getUnreadMessagesCount() > 0) {
            imConversation.read();
        }
    }


}
