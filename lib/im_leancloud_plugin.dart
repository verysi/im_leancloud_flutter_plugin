import 'dart:async';
import 'dart:convert';
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

  void onLoginClick(String args) {
    _channel.invokeMethod('onLoginClick', args);
  }

  Future<String> getConversation(String username) async {
    var args = <String, dynamic>{
      'username': username,
    };
    String conversationId =
        await _channel.invokeMethod('getConversation', args);
    return conversationId;
  }

  void sendText(String content, String conversationId) {
    var args = <String, dynamic>{
      'content': content,
      'conversationId': conversationId,
    };

    _channel.invokeMethod('sendText', args);
  }

  void sendImage(String imagePath, String conversationId) {
    var args = <String, dynamic>{
      'imagePath': imagePath,
      'conversationId': conversationId,
    };

    _channel.invokeMethod('sendImage', args);
  }

  void sendAudio(String audioPath, String conversationId) {
    var args = <String, dynamic>{
      'audioPath': audioPath,
      'conversationId': conversationId,
    };

    _channel.invokeMethod('sendAudio', args);
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

  Future<void> signoutClick() async {
    await _channel.invokeMethod('signoutClick');
  }

  EventHandler _onReceiveMessage;
  EventHandler _unReadMessages;
  EventHandler _unRead;

  void addEventHandler({
    EventHandler onReceiveMessage,
    EventHandler unReadMessages,
    EventHandler unRead,
  }) {
    _onReceiveMessage = onReceiveMessage;
    _unReadMessages = unReadMessages;
    _unRead = unRead;
  }

  Future<dynamic> _handler(MethodCall call) {
    print("handle mehtod call ${call.method} ${call.arguments}");
    String method = call.method;
    switch (method) {
      case 'onReceiveMessage':
        return _onReceiveMessage(call.arguments.cast<String, dynamic>());
        break;
      case 'unReadMessages':
        return _unReadMessages(call.arguments.cast<bool>());
        break;
      case 'unRead':
        print("调用 ${call.method}");
        return _unRead(call.arguments.cast<String, dynamic>());
        break;
      default:
        print('没收到来自平台的方法');
    }
  }
}

enum LeancloudLoggerLevel { OFF, ERROR, WARNING, INFO, DEBUG, VERBOSE }
