import 'package:flutter/material.dart';

enum MessageStatus {
  AVIMMessageStatusNone,
  AVIMMessageStatusSending,
  AVIMMessageStatusSent,
  AVIMMessageStatusReceipt,
  AVIMMessageStatusFailed,
  readed
}

class MessageState {
  String lastmessagestatus;
  static Map conversationstatus = {};
  static Future<void> setconversationstatus(String conversationId) {
    if (!conversationstatus.containsKey(conversationId)) {
      conversationstatus.addAll({conversationId: 'readed'});
    } else {
      conversationstatus[conversationId] = 'unread';
    }
  }
}

void main() {
  runApp(new MaterialApp(
    title: '测试',
    theme: new ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: new maptest(),
  ));
}

class maptest extends StatefulWidget {
  @override
  _maptestState createState() => new _maptestState();
}

class _maptestState extends State<maptest> {
  String text = '你好';
  haha() async {
    await MessageState.setconversationstatus('conid');
    setState(() {
      text = MessageState.conversationstatus['conid'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('sss'),
      ),
      body: new ListView(
        children: <Widget>[
          // 一个有图片和文字组成的简单列表item
          new ListTile(
            title: new Text('添加'),
            // 右边的图标
            trailing: new Icon(Icons.delete),
            onTap: () {
              haha();
            },
          ),
          new ListTile(
            title: new Text('$text'),
            // 右边的图标
            trailing: new Icon(Icons.delete),
            onTap: () {

            },
          ),
        ],
      ),
    );
  }
}
