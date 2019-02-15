//使用Leancloud官方自带的消息缓存
import 'package:flutter/material.dart';
import 'sql/conversation.dart';
import 'dart:convert';
import 'dart:async';
import 'sql/sqlconversation.dart';
import 'sql/message.dart';
import 'refresh_list_view.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class talk2 extends StatefulWidget {
  String conversationId;
  String username;
  talk2(this.conversationId, this.username);

  @override
  talk2State createState() => new talk2State();
}

class talk2State extends State<talk2> {
  bool isLoading = true;
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final StreamController<List<dynamic>> _streamController =
      StreamController<List<dynamic>>();

  final FocusNode focusNode = new FocusNode();
  sqlConversation dbc = new sqlConversation();
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
      int res = await dbc.saveConversation(conversation);
      print('会话列表数：$res');
    } else {
      print('会话已经存在');
    }
  }

  Future getConversationId(String username) async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    String conversationId = await ImleancloudPlugin.getConversation(username);
    print(conversationId);
  }

  Future<void> onReceiveMessage() async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.addEventHandler(
      onReceiveMessage: (Map<String, dynamic> message) async {
        steamlist();
        if (widget.conversationId == message['conversationId'] && isopendTalk) {
          conversationRead();
        }
        String content = json.decode(message['content'])['_lctext'];
        Message onReceiveMessage =
            new Message(content, message['getfrom'], message['conversationId']);
        _showNotification(message['getfrom'], content);
        saveNewconversation(message['conversationId'], message['getfrom']);
      },
    );
  }

  Future _showNotification(String getfrom, String content) async {
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
    i = 1;
  }

  void conversationRead() {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.conversationRead();
  }

  Future<void> steamlist() async {
    messages = await getMessage(1);
    _streamController.sink.add(messages);
  }

  Future<List<dynamic>> getMessage(int page) async {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    String listmessages = await ImleancloudPlugin.queryUnreadMessages(
        widget.conversationId, 10 * page);
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
    Navigator.pop(context);
    isopendTalk = false;
    messages = [];
    return Future.value(false);
  }

  Future<void> inittalk() async {
    await getConversationId(widget.username);
    conversationRead();
  }

  int i = 1;
  Future<void> _refresh() async {
    if (messages.length < i * 10) {
      print('已经拉到最顶');
    } else {
      i = i + 2; //下拉加载20条数据
      messages = await getMessage(i);
      _streamController.sink.add(messages);
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
              top: new BorderSide(color: Colors.black54, width: 0.5)),
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
    //Text('${detail['content']}');
    //.....
  }
}
