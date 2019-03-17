//使用Leancloud官方自带的消息缓存
import 'package:flutter/material.dart';
import 'sql/conversation.dart';
import 'dart:convert';
import 'dart:async';
import 'refresh_list_view.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'contact.dart';
import 'custome_router.dart';

class talk2 extends StatefulWidget {
  String conversationId;
  String username;
  talk2(this.conversationId, this.username);

  @override
  talk2State createState() => new talk2State();
}

class talk2State extends State<talk2> {
  bool isLoading = true;
  bool isMoreData = true;
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final StreamController<List<dynamic>> _streamController =
      StreamController<List<dynamic>>();

  final FocusNode focusNode = new FocusNode();
  ConversationSqlite dbc = new ConversationSqlite();
  bool isopendTalk;
  static List<dynamic> messages = [];

  Future<void> saveNewconversation(
      String conversationId, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString('currentUser');
    bool isconversationExist = await dbc.conversationExist(username);
    if (isconversationExist == false) {
      Conversation conversation =
          new Conversation(currentUser, conversationId, username);
      await dbc.insert(conversation);
    } else {
      print('会话已经存在');
    }
    await dbc.close();
  }

  Future<void> getConversationId(String username) async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString('currentUser');

    String conversationId =
        await ImleancloudPlugin.getConversation(currentUser, username);
    print(conversationId);
  }

  //更新LastDelivered
  Future<void> updateLastDelivered(String jsonLastDelivered) async {
    Map<String, dynamic> mapLastdelivered = json.decode(jsonLastDelivered);
    String conversationId = mapLastdelivered['conversationId'];
    int LastDelivered = mapLastdelivered['LastDelivered'];
    await dbc.updateLastDelivered(conversationId, LastDelivered);
    dbc.close();
  }

  Future<void> onReceiveMessage() async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.addEventHandler(
      onReceiveMessage: (Map<String, dynamic> message) async {
        print('这是talk文件传来的消息');
        if (widget.conversationId == message['conversationId'] && isopendTalk) {
          steamlist();
          conversationRead();
        }
        String content = json.decode(message['content'])['_lctext'];
        _showNotification(message['getfrom'], content);
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
      },
      onLastReadAtUpdated: (Map<String, dynamic> lastreadat) async {
        print('更新最后读取时间');
        print(lastreadat);
      },
      onLastDeliveredAtUpdated: (Map<String, dynamic> lastdeliver) async {
        print('更新接收时间');
        print(lastdeliver);
        String jsonLastDelivered = lastdeliver['LastDeliveredAt'];
        updateLastDelivered(jsonLastDelivered);
      },
    );
  }

  Future<void> _showNotification(String getfrom, String content) async {
    var flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, getfrom, content, platformChannelSpecifics, payload: 'item x');
  }

  Future<void> sendText(String content, String conversationId) async {
    Map send = {
      "getfrom": "myself",
      "content": "{\"_lctype\":-1,\"_lctext\":\"$content\"}",
      "MessageStatus": "loading",
      "conversationId": conversationId,
    };
    textEditingController.clear();
    messages.add(send);
    _streamController.sink.add(messages);
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    String sendresult =
        await ImleancloudPlugin.sendText(content, conversationId);
    if (sendresult == 'sendsuccess') {
      send['MessageStatus'] = 'sendsuccess';
      steamlist();
    } else {
      steamlist();
    }
    steamlist();
    isMoreData = true;
  }

  void conversationRead() {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.conversationRead();
  }

  Future<void> steamlist() async {
    messages = await getMessage(10);
    _streamController.sink.add(messages);
    await dbc.sequenceConversation(
        messages[messages.length - 1]['conversationId'],
        messages[messages.length - 1]['Timestamp']);
    // dbc.close();
  }

  Future<List<dynamic>> getMessage(int count) async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    String listmessages = await ImleancloudPlugin.queryUnreadMessages(
        widget.conversationId, count);
    print(listmessages);
    List<dynamic> mapmessages = json.decode(listmessages);
    if (mapmessages.length == 0) {
      mapmessages = [];
    }
    return mapmessages;
  }

  Future test(String sendContent) async {
    sendText(sendContent, widget.conversationId);
  }

  Future<bool> onBackPress() async {
    isopendTalk = false;
    messages = [];
    Navigator.of(context).pushReplacement(CustomeRout(contact(), -1.0));

    //return Future.value(true);
  }

  Future<void> inittalk() async {
    await getConversationId(widget.username);
    conversationRead();
  }

//查看消息历史记录
  Future<void> _refresh() async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    String jsonhistorymessages;
    List<dynamic> historymessages;

    if (messages.length < 10) {
      print('已经拉到最顶');
    } else {
      if (isMoreData) {
        jsonhistorymessages = await ImleancloudPlugin.queryHistoryMessages(
            widget.conversationId,
            messages[0]['MessageId'],
            messages[0]['Timestamp'],
            20);
        historymessages = json.decode(jsonhistorymessages);
        if (historymessages.length < 20) {
          isMoreData = false;
        } else {
          isMoreData = true;
        }
        historymessages.addAll(messages);
        messages = historymessages;
        //下拉加载20条数据
        _streamController.sink.add(messages);
      } else {
        print('已经拉到最顶');
      }
    }
  }

  @override
  void initState() {
    isopendTalk = true;
    inittalk();
    steamlist();
    onReceiveMessage();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.username),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              onBackPress();
            }),
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                buildListMessage(),
                buildInput(),
              ],
            ),
            // buildLoading()
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black54)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.add),
                onPressed: () {
                  print('添加富媒体消息');
                  //......
                },
                color: Colors.black54,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: () {
                  print('获得图片');
                  //......
                },
                color: Colors.black54,
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              // margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: TextField(
                style: TextStyle(color: Colors.black54, fontSize: 18.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: '发消息',
                  hintStyle: TextStyle(color: Colors.black38),
                ),
                focusNode: focusNode,
                // maxLines: ?,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => test(textEditingController.text),
                color: Colors.blue,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(
              top: new BorderSide(color: Colors.black12, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: null,
              //child: CircularProgressIndicator(
              //valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
              // child: Text(
              // '开始聊天吧！',
              //style: Theme.of(context).textTheme.display1,
              // ),
            );
          } else {
            return RefreshListView(
              onRefreshCallback: () {},
              loadMoreCallback: _refresh,
              listView: ListView.builder(
                padding: EdgeInsets.all(10.0),
                itemBuilder: (context, index) => buildItem(
                    index, snapshot.data[snapshot.data.length - index - 1]),
                // itemBuilder: (context, index) =>
                //   buildItem(index, snapshot.data[index]),

                itemCount: snapshot.data.length,
                reverse: true,
                controller: listScrollController,
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildItem(int index, Map detail) {
    return Padding(
      padding: widget.username == detail['getfrom']
          ? const EdgeInsets.only(left: 10)
          : const EdgeInsets.only(right: 0),
      child: Container(
        alignment: widget.username == detail['getfrom']
            ? Alignment.centerLeft
            : Alignment.centerRight,
        margin: EdgeInsets.only(
          left: 10,
          right: 30,
          top: 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: widget.username == detail['getfrom']
                  ? AssetImage('assets/images/chat.png')
                  : AssetImage('assets/images/rchat.png'),
              centerSlice: Rect.fromLTWH(15, 10, 20, 3),
            ),
          ),
          constraints: BoxConstraints(
            minWidth: 1.0,
            maxWidth: 270.0,
            minHeight: 1.0,
          ),
          padding: EdgeInsets.fromLTRB(20.0, 10.0, 15.0, 15.0),
          child: Text(
            '${json.decode(detail['content'])['_lctext']}',
            style: widget.username == detail['getfrom']
                ? TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white)
                : TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
          ),
        ),
      ),
    );
  }
}
