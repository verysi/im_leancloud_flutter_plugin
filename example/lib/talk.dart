//使用自建的消息缓存，详情查看sql文件夹。
import 'package:flutter/material.dart';
import 'sql/conversation.dart';
import 'dart:convert';
import 'dart:async';
import 'sql/sql.dart';
import 'sql/message.dart';
import 'sql/sqlconversation.dart';
import 'package:im_leancloud_plugin/im_leancloud_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class talk extends StatefulWidget {
  String conversationId;
  String username;
  talk(this.conversationId, this.username);

  @override
  talkState createState() => new talkState();
}

class talkState extends State<talk> {
  bool isLoading = true;
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final StreamController<List<Message>> _streamController =
      StreamController<List<Message>>();
  List<String> contents = List<String>();
  final FocusNode focusNode = new FocusNode();
  sql db = new sql();
  sqlConversation dbc = new sqlConversation();
  List<Message> messages;
  bool isopendTalk;

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
        String content = json.decode(message['content'])['_lctext'];
        Message onReceiveMessage =
            new Message(content, message['getfrom'], message['conversationId']);
        int res = await db.saveMessage(onReceiveMessage);
        getMessage();
        if (widget.conversationId == message['conversationId'] && isopendTalk) {
          conversationRead();
        }
        saveNewconversation(message['conversationId'], message['getfrom']);
      },
    );
  }

  void sendText(String content, String conversationId) {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.sendText(content, conversationId);
  }

  void conversationRead() {
    ImLeancloudPlugin ImleancloudPlugin = ImLeancloudPlugin.getInstance();
    ImleancloudPlugin.conversationRead();
  }

  Future saveMessage(String sendContent) async {
    Message message = new Message(sendContent, 'meself', widget.conversationId);
    int res = await db.saveMessage(message);
    print(res);
    textEditingController.clear();
  }

  Future getMessage() async {
    messages = await db.getMessageFrom(widget.conversationId);
    _streamController.sink.add(messages);
  }

  Future test(String sendContent) async {
    await saveMessage(sendContent);
    sendText(sendContent, widget.conversationId);
    getMessage();
  }

  Future<bool> onBackPress() async {
    Navigator.pop(context);
    isopendTalk = false;
    return Future.value(false);
  }

  Future inittalk() async {
    await getConversationId(widget.username);
    conversationRead();
  }

  @override
  void initState() {
    isopendTalk = true;
    inittalk();
    onReceiveMessage();
    getMessage();
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
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => buildItem(index,
                  snapshot.data[snapshot.data.length - index - 1].toMap()),
              itemCount: snapshot.data.length,
              reverse: true,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }

  Widget buildItem(int index, Map detail) {
    return Padding(
      padding: widget.username == detail['messagefrom']
          ? const EdgeInsets.only(left: 10)
          : const EdgeInsets.only(right: 0),
      child: Container(
        alignment: widget.username == detail['messagefrom']
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
              image: widget.username == detail['messagefrom']
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
            '${detail['content']}',
            style: widget.username == detail['messagefrom']
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
