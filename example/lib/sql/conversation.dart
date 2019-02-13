class Conversation {
  String currentUser;
  String conversationId;
  String username;
  int id;

  Conversation(this.currentUser,this.conversationId, this.username);

  Conversation.map(Map obj) {
    this.currentUser=obj['currentUser'];
    this.conversationId = obj['conversationId'];
    this.username = obj['username'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['currentUser']=this.currentUser;
    map['conversationId'] = this.conversationId;
    map['username'] = this.username;
    return map;
  }

  void setConversationId(int id) {
    this.id = id;
  }
}
