class Message {
  String content;
  String conversationId;
  String messagefrom;
  String messageId;
  String MessageStatus;//枚举：
  int id;
  int timestamp;
  int deliveredAt;
  int updateAt;

  Message(this.content, this.messagefrom, this.conversationId);

  Message.map(Map obj) {
    this.content = obj['content'];
    this.messagefrom = obj['messagefrom'];
    this.conversationId = obj['conversationId'];
    this.MessageStatus=obj['MessageStatus'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['content'] = this.content;
    map['messagefrom'] = this.messagefrom;
    map['conversationId'] = this.conversationId;
    map['MessageStatus']=this.MessageStatus;
    return map;
  }

  void setMessageId(int id) {
    this.id = id;
  }
}
