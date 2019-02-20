package com.sisi.imleancloudplugin;

/**
 * Created by ruirui on 2019/1/28.
 */

import android.content.Context;

import com.avos.avoscloud.AVException;
import com.avos.avoscloud.AVInstallation;
import com.avos.avoscloud.AVLogger;
import com.avos.avoscloud.AVOSCloud;
import com.avos.avoscloud.SaveCallback;
import com.avos.avoscloud.im.v2.AVIMClient;
import com.avos.avoscloud.im.v2.AVIMException;
import com.avos.avoscloud.im.v2.callback.AVIMClientCallback;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;


class LeancloudFunction {


    static void initialize(MethodCall call, MethodChannel.Result result, Context context) {
        LCChatKit.getInstance().setProfileProvider(CustomUserProvider.getInstance());
        AVOSCloud.setDebugLogEnabled(true);
        String appId = LeancloudArgsConverter.getStringValue(call, result, "appId");
        String appKey = LeancloudArgsConverter.getStringValue(call, result, "appKey");
        LCChatKit.getInstance().init(context, appId, appKey);
        AVIMClient.setAutoOpen(true);
        AVInstallation.getCurrentInstallation().saveInBackground(new SaveCallback() {
            public void done(AVException e) {
                if (e == null) {
                    // 保存成功
                    String installationId = AVInstallation.getCurrentInstallation().getInstallationId();
                    System.out.println("---  " + installationId);
                } else {
                    // 保存失败，输出错误信息
                    System.out.println("failed to save installation.");
                }
            }
        });

    }

    /**
     * Setup log level must be before call initialize function
     * <p>
     * The call must be include args:
     * level  --> OFF(0), ERROR(1), WARNING(2), INFO(3), DEBUG(4), VERBOSE(5), ALL(6);
     *
     * @param call   MethodCall from LeancloudFlutterPlugin.onMethodCall function
     * @param result MethodChannel.Result from LeancloudFlutterPlugin.onMethodCall function
     */
    static void setLogLevel(MethodCall call, MethodChannel.Result result) {
        int level_int = LeancloudArgsConverter.getIntValue(call, result, "level");
        // AVLogger.Level level = AVLogger.Level.OFF;
        int level = AVLogger.LOG_LEVEL_NONE;
        switch (level_int) {
            case 0:
                // already assigned to this value
                break;
            case 1:
                level = AVLogger.LOG_LEVEL_ERROR;
                break;
            case 2:
                level = AVLogger.LOG_LEVEL_WARNING;
                break;
            case 3:
                level = AVLogger.LOG_LEVEL_INFO;
                break;
            case 4:
                level = AVLogger.LOG_LEVEL_DEBUG;
                break;
            case 5:
                level = AVLogger.LOG_LEVEL_VERBOSE;
                break;
            default:
                break;
        }
        AVOSCloud.setLogLevel(level);
    }

    static void onLoginClick(MethodCall call, final MethodChannel.Result result) {
        String clientId = (String) call.arguments;
        LCChatKit.getInstance().open(clientId, new AVIMClientCallback() {
            @Override
            public void done(AVIMClient avimClient, AVIMException e) {
                if (null == e) {
                    System.out.println("帐号登陆即时通讯成功");
                   result.success(true);


                } else {
                    System.out.println("帐号登陆即时通讯失败");
                   result.success(false);
                }
            }
        });
    }

    static void signoutClick() {
        LCChatKit.getInstance().close(new AVIMClientCallback() {
            @Override
            public void done(AVIMClient client, AVIMException e) {
                if (e == null) {
                    System.out.println("即时通讯账号退出成功");
                    //登出成功
                }
            }
        });
    }


}


