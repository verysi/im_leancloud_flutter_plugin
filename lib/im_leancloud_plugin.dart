import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:platform/platform.dart';

typedef Future<dynamic> EventHandler(Map<String, dynamic> event);

class ImLeancloudPlugin {
  static const MethodChannel _channel =
      const MethodChannel('im_leancloud_plugin');

  final Platform _platform;
  final MethodChannel _channel2;

  @visibleForTesting
  ImLeancloudPlugin.private(MethodChannel channel, Platform platform)
      : _channel2 = channel,
        _platform = platform;

  /// Singleton property
  static ImLeancloudPlugin _instancePlugin = new ImLeancloudPlugin.private(
      const MethodChannel('im_leancloud_plugin'), const LocalPlatform());

  /// Get plugin instance
  static ImLeancloudPlugin getInstance() {
    return _instancePlugin;
  }

  var _logLevel = 0;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Initialize the Native SDK
  void initialize(String appId, String appKey) {
    _channel.setMethodCallHandler(_handler);
    var args = <String, dynamic>{
      'appId': appId,
      'appKey': appKey,
    };
    _channel.invokeMethod('initialize', args);
  }

  Future<bool> onLoginClick(String args) async {
    // bool isloginLcchat=await _channel.invokeMethod('onLoginClick', args);
    // return isloginLcchat;

    bool isloginLcchat = await _channel.invokeMethod('onLoginClick', args);
    return isloginLcchat;
  }
  //上传文件，文件名fileName需加上后缀名
    Future<String> uploadFile(String filePath, String fileName) async {
    var args = <String, dynamic>{
      'filePath': filePath,
      'fileName': fileName,
    };
    String fileId =
    await _channel.invokeMethod('uploadFile', args);
    print('fileId:$fileId');
    return fileId;
  }

  Future<String> getConversation(String currentUser, String username) async {
    var args = <String, dynamic>{
      'currentUser': currentUser,
      'username': username,
    };
    String conversationId =
        await _channel.invokeMethod('getConversation', args);
    return conversationId;
  }

  Future<String> conversationList(String currentUser) async {
    var args = <String, dynamic>{
      'currentUser': currentUser,
    };
    String conversations =
        await _channel.invokeMethod('conversationList', args);
    return conversations;
  }

  //消息发送成功，返回'sendsuccess',失败返回'sendfalse'
  Future<String> sendText(String content, String conversationId) async {
    var args = <String, dynamic>{
      'content': content,
      'conversationId': conversationId,
    };
    String sendresult = await _channel.invokeMethod('sendText', args);
    print('sendresult:$sendresult');
    return sendresult;
  }

  Future<String> sendImage(String imagePath, String conversationId) async {
    var args = <String, dynamic>{
      'imagePath': imagePath,
      'conversationId': conversationId,
    };

    String sendresult = await _channel.invokeMethod('sendImage', args);
    print('sendresult:$sendresult');
    return sendresult;
  }

  Future<String> sendAudio(String audioPath, String conversationId) async {
    var args = <String, dynamic>{
      'audioPath': audioPath,
      'conversationId': conversationId,
    };

    String sendresult = await _channel.invokeMethod('sendAudio', args);
    return sendresult;
  }

  Future<String> sendVideo(String videoPath, String conversationId) async {
    var args = <String, dynamic>{
      'audioPath': videoPath,
      'conversationId': conversationId,
    };

    String sendresult = await _channel.invokeMethod('sendVideo', args);
    return sendresult;
  }

  void conversationRead() {
    _channel.invokeMethod('conversationRead');
  }

  /// Setup log level must be before called initialize function
  /// The call must be include args:
  ///  [level]  --> OFF(0), ERROR(1), WARNING(2), INFO(3), DEBUG(4), VERBOSE(5), ALL(6);
  /// Leancloud logger level
  /// iOS only have ON or OFF. So when you set OFF, it's OFF. When you set another logger level, it's ON.
  void setLogLevel(LeancloudLoggerLevel level) {
    switch (level) {
      case LeancloudLoggerLevel.OFF:
        this._logLevel = 0;
        break;
      case LeancloudLoggerLevel.ERROR:
        this._logLevel = 1;
        break;
      case LeancloudLoggerLevel.WARNING:
        this._logLevel = 2;
        break;
      case LeancloudLoggerLevel.INFO:
        this._logLevel = 3;
        break;
      case LeancloudLoggerLevel.DEBUG:
        this._logLevel = 4;
        break;
      case LeancloudLoggerLevel.VERBOSE:
        this._logLevel = 5;
        break;
    }
    var args = <String, dynamic>{
      'level': this._logLevel,
    };
    _channel.invokeMethod('setLogLevel', args);
  }

  Future<String> queryUnreadMessages(
      String conversationId, int unreadcount) async {
    var args = <String, dynamic>{
      'conversationId': conversationId,
      'unreadcount': unreadcount,
    };
    String messages = await _channel.invokeMethod('queryUnreadMessages', args);
    return messages;
  }

  Future<String> queryHistoryMessages(String conversationId, String messageId,
      int Timestamp, int pageSize) async {
    var args = <String, dynamic>{
      'conversationId': conversationId,
      'messageId': messageId,
      'Timestamp': Timestamp,
      'pageSize': pageSize,
    };
    String historymessages =
        await _channel.invokeMethod('queryHistoryMessages', args);
    return historymessages;
  }

  Future<void> signoutClick() async {
    await _channel.invokeMethod('signoutClick');
  }

  EventHandler _onReceiveMessage;
  EventHandler _onConnectionResume;
  EventHandler _unRead;
  EventHandler _onLastReadAtUpdated;
  EventHandler _onLastDeliveredAtUpdated;

  void addEventHandler({
    EventHandler onReceiveMessage,
    EventHandler onConnectionResume,
    EventHandler unRead,
    EventHandler onLastReadAtUpdated,
    EventHandler onLastDeliveredAtUpdated,
  }) {
    _onReceiveMessage = onReceiveMessage;
    _onConnectionResume = onConnectionResume;
    _unRead = unRead;
    _onLastReadAtUpdated = onLastReadAtUpdated;
    _onLastDeliveredAtUpdated = onLastDeliveredAtUpdated;
  }

  Future<dynamic> _handler(MethodCall call) {
    print("handle mehtod call ${call.method} ${call.arguments}");
    String method = call.method;
    switch (method) {
      case 'onReceiveMessage':
        return _onReceiveMessage(call.arguments.cast<String, dynamic>());
        break;
      case 'onConnectionResume':
        return _onConnectionResume(call.arguments.cast<String, dynamic>());
        break;
      case 'unRead':
        return _unRead(call.arguments.cast<String, dynamic>());
        break;
      case 'onLastReadAtUpdated':
        return _onLastReadAtUpdated(call.arguments.cast<String, dynamic>());
        break;
      case 'onLastDeliveredAtUpdated':
        return _onLastDeliveredAtUpdated(
            call.arguments.cast<String, dynamic>());
        break;
      default:
        print('没收到来自平台的回调');
    }
  }
}

enum LeancloudLoggerLevel { OFF, ERROR, WARNING, INFO, DEBUG, VERBOSE }
