import 'package:flutter/cupertino.dart';

class Room {
  final String id;
  final String name;
  final String createUser;
  int participantNum;

  Room(this.id, this.name, this.createUser, {this.participantNum: 0});
}

class Message {
  final int generatedTime;
  final String content;
  final String userName;
  CrossAxisAlignment alignment;
  TextDirection textDirection;
  Color backgroundColor;

  Message(this.generatedTime, this.content, this.userName,
      {this.alignment: CrossAxisAlignment.start,
      this.textDirection: TextDirection.ltr,
      this.backgroundColor: const Color.fromARGB(255, 255, 255, 255)});
}
