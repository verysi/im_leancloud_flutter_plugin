class Message {
  String content;
  String conversationId;
  String messagefrom;
  String messageId;
  int id;
  int timestamp;
  int deliveredAt;
  int updateAt;

  Message(this.content, this.messagefrom, this.conversationId);

  Message.map(Map obj) {
    this.content = obj['content'];
    this.messagefrom = obj['messagefrom'];
    this.conversationId = obj['conversationId'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['content'] = this.content;
    map['messagefrom'] = this.messagefrom;
    map['conversationId'] = this.conversationId;
    return map;
  }

  void setMessageId(int id) {
    this.id = id;
  }
}
