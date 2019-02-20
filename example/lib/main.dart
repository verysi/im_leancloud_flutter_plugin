import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sql/conversation.dart';
import 'sql/sql.dart';
import 'sql/message.dart';
import 'login.dart';
import 'contact.dart';
import 'user.dart';
//import 'contact2.dart';

void main() {
  runApp(new MaterialApp(
    title: 'LeanCloud 即时通讯',
    theme: new ThemeData(
      primarySwatch: Colors.blue,
    ),
    routes: <String, WidgetBuilder>{
      '/contact': (BuildContext context) => contact(),
      '/login': (BuildContext context) => LoginPage(),
    },
    home: new MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool logined = false;
  String _platformVersion = 'Unknown';
  ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
  sql db = new sql();
  ConversationSqlite dbc = new ConversationSqlite();
  var flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    localNotification();
    initApp();
    super.initState();
  }

  Future _islogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString('currentUser');
    if (currentUser == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      User.currentUser = currentUser;
      logined = true;
      await dbc.getcurrentUserConversation(currentUser);
    }
  }

//这个和消息状态栏通知有关
  void localNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidRecieveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

//这个和消息状态栏通知有关
  Future _showNotification(String getfrom, String content) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, getfrom, content, platformChannelSpecifics, payload: 'item x');
  }

  Future<void> onLoginClick() async {
    if (logined) {
      // await ImleancloudPlugin.onLoginClick(User.currentUser);
      bool logining = await ImleancloudPlugin.onLoginClick(User.currentUser);
      if (logining) {
        User.isloginLcchat = true;
      }
      print('网络登陆状态：$logining');
      Navigator.of(context).pushReplacementNamed('/contact');
    }
  }

  Future<void> initApp() async {
    await _islogin();
    await initLeancloud();
    initPlatformState();
    onLoginClick();
  }

  void initLeancloud() {
    String appId = ""; //输入设置当前Leancloud appId
    String appKey = ""; //输入设置当前Leancloud appKey
    ImleancloudPlugin.initialize(appId, appKey);
  }

  void conversationRead() {
    ImleancloudPlugin.conversationRead();
  }

//保存新的会话
  Future<void> saveNewconversation(
      String conversationId, String username) async {
    bool isconversationExist = await dbc.conversationExist(username);
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(User.currentUser, conversationId, username);
      await dbc.insert(conversation);
    } else {
      print('会话已经存在');
    }
    await dbc.close();
  }

  //获取接收过来的会话里对方用户名，只有两人会话的情况
  String conversationName(List<dynamic> members) {
    if (members.length > 1) {
      if (User.currentUser == members[0]) {
        return members[1];
      } else {
        return members[0];
      }
    } else {
      return members[0];
    }
  }

//处理未读消息
  Future<void> Unreadconversation(String jsonUnread) async {
    Map<String, dynamic> mapUnread = json.decode(jsonUnread);
    List<dynamic> members = mapUnread['getMembers'];
    String username = conversationName(members);
    String conversationId = mapUnread['conversationId'];
    await saveNewconversation(conversationId, username);
    _showNotification(username, '有未读消息');
  }

  //更新LastDelivered
  Future<void> updateLastDelivered(String jsonLastDelivered) async {
    Map<String, dynamic> mapLastdelivered = json.decode(jsonLastDelivered);
    String conversationId = mapLastdelivered['conversationId'];
    int LastDelivered = mapLastdelivered['LastDelivered'];
    await dbc.updateLastDelivered(conversationId, LastDelivered);
    dbc.close();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ImLeancloudPlugin.platformVersion;
      ImleancloudPlugin.addEventHandler(
        //接收实时消息
        onReceiveMessage: (Map<String, dynamic> message) async {
          print('这是main文件里面传来的消息');
          String content = json.decode(message['content'])['_lctext'];
          Message onReceiveMessage = new Message(
              content, message['getfrom'], message['conversationId']);
          _showNotification(message['getfrom'], content);
          int res = await db.saveMessage(onReceiveMessage);
          print(res);
          saveNewconversation(message['conversationId'], message['getfrom']);
          await dbc.sequenceConversation(
              message['conversationId'], message['Timestamp']);
          dbc.close();
        },
        //网络状态重新连接
        onConnectionResume: (isResume) async {
          print(isResume);
        },
        //未读消息状态发生变化
        unRead: (Map<String, dynamic> unreadmessage) async {
          print(unreadmessage);
          String jsonUnread = unreadmessage['unRead'];
          await dbc.getcurrentUserConversation;
          await Unreadconversation(jsonUnread);
        },
        onLastReadAtUpdated: (Map<String, dynamic> lastreadat) async {
          print('更新最后读取时间');
          print(lastreadat);
        },
        onLastDeliveredAtUpdated: (Map<String, dynamic> lastdeliver) async {
          print('更新会话列表');
          print(lastdeliver);
          String jsonLastDelivered = lastdeliver['LastDeliveredAt'];
          updateLastDelivered(jsonLastDelivered);
        },
      );
    } on PlatformException {
      platformVersion = '获取平台版本失败';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/start.png'),
      ),
    );
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

    await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new SecondScreen(payload)),
    );
  }

  Future onDidRecieveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
            title: new Text(title),
            content: new Text(body),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: new Text('Ok'),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await Navigator.push(
                    context,
                    new MaterialPageRoute(
                      builder: (context) => new SecondScreen(payload),
                    ),
                  );
                },
              )
            ],
          ),
    );
  }
}

class SecondScreen extends StatefulWidget {
  final String payload;
  SecondScreen(this.payload);
  @override
  State<StatefulWidget> createState() => new SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  String _payload;
  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Second Screen with payload: " + _payload),
      ),
      body: new Center(
        child: new RaisedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: new Text('Go back!'),
        ),
      ),
    );
  }
}
