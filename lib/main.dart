import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';

import 'myWidgets.dart';
import 'objects.dart';

final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
final Firestore _firestore = Firestore.instance;
final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
FirebaseUser _user;
const Color borderColor = Colors.black54;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Room',
      theme: ThemeData(primaryColor: const Color.fromARGB(255, 0, 178, 36)),
      initialRoute: "/signIn",
      routes: <String, WidgetBuilder>{
        "/signIn": (BuildContext context) => SignInPage(),
        "/signUp": (BuildContext context) => SignUpPage(),
        "/roomList": (BuildContext context) => RoomListPage(),
        "/createRoom": (BuildContext context) => RoomCreatePage(),
        "/profile": (BuildContext context) => ProfilePage(),
      },
    );
  }
}

class SignInPage extends StatelessWidget {
  final TextEditingController _eMailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: Container(
//        height: MediaQuery.of(context).size.height -
//            AppBar().preferredSize.height,
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: SimpleRaisedButton("新規登録はこちら", () {
                Navigator.of(context).pushNamed("/signUp");
              }, fontSize: 16.0, width: 20.0)
                  .getRoundedRaisedButton(),
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomTextField(_eMailController, labelText: "e-mail")
                      .getSimpleTextField(),
//                    Padding(padding: const EdgeInsets.all(20.0)),
                  CustomTextField(_passwordController, labelText: "password")
                      .getSecretTextField(),
                ],
              ),
            ),
            SimpleRaisedButton("ログインする", () {
              if (_eMailController.text != "" &&
                  _passwordController.text != "") {
                _signIn(_eMailController.text, _passwordController.text).then(
                  (AuthResult result) {
                    _user = result.user;
                    Navigator.of(context).pushReplacementNamed("/roomList");
                  },
                ).catchError((e) {
                  print("signInError: $e");
                  Fluttertoast.showToast(
                    msg: "入力された内容に誤りがあります。",
                    gravity: ToastGravity.CENTER,
                    fontSize: 20.0,
                  );
                });
              } else {
                Fluttertoast.showToast(
                    msg: "空欄があります。",
                    gravity: ToastGravity.CENTER,
                    fontSize: 20.0);
              }
            }, fontSize: 24.0, width: 70.0)
                .getRoundedRaisedButton(),
          ],
        ),
      ),
    );
  }

  Future<AuthResult> _signIn(String email, String password) async {
    final AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result;
  }
}

class SignUpPage extends StatelessWidget {
  final TextEditingController _eMailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserUpdateInfo _userUpdateInfo = UserUpdateInfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント登録'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CustomTextField(_nameController, labelText: "name")
                        .getSimpleTextField(),
                    Padding(padding: const EdgeInsets.all(20.0)),
                    CustomTextField(_eMailController, labelText: "e-mail")
                        .getSimpleTextField(),
                    Padding(padding: const EdgeInsets.all(20.0)),
                    CustomTextField(_passwordController, labelText: "password")
                        .getSecretTextField(),
                  ],
                ),
              ),
            ),
            SimpleRaisedButton("登録する", () async {
              if (_eMailController.text != "" &&
                  _passwordController.text != "") {
                _signUp(_eMailController.text, _passwordController.text).then(
                  (AuthResult result) async {
                    _user = result.user;
                    _userUpdateInfo.displayName = _nameController.text;
                    await _user.updateProfile(_userUpdateInfo);
                    _user = await _firebaseAuth.currentUser();
                    await registUser();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil("/roomList", (_) => false);
                  },
                ).catchError((e) {
                  print("signUpError: $e");
                  Fluttertoast.showToast(
                    msg: "入力された内容に誤りがあります。",
                    gravity: ToastGravity.CENTER,
                    fontSize: 20.0,
                  );
                });
              } else {
                Fluttertoast.showToast(
                  msg: "空欄があります。",
                  gravity: ToastGravity.CENTER,
                  fontSize: 20.0,
                );
              }
            }, fontSize: 24.0, width: 70.0)
                .getRoundedRaisedButton(),
          ],
        ),
      ),
    );
  }

  Future<AuthResult> _signUp(String email, String password) async {
    final AuthResult result =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result;
  }

  Future<void> registUser() async {
    //uidをドキュメント名にしてユーザー情報をFirestoreの'users'コレクションに登録
    await _firestore.collection('users').document(_user.uid).setData({
      'id': _user.uid,
      'email': _user.email,
      'name': _user.displayName,
    });
  }
}

class RoomListPage extends StatefulWidget {
  @override
  _RoomListPageState createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルーム一覧'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.person,
              size: 32.0,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed("/profile");
            },
          )
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              stream: _firestore.collection('rooms').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData)
                  return Center(
                    child: Container(
                      constraints:
                          BoxConstraints(maxWidth: 300.0, maxHeight: 300.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                else {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(100, 210, 255, 229),
                    ),
                    child: getRooms(snapshot.data),
                  );
                }
              },
            ),
            SimpleRaisedButton(
              "ルームを作成",
              () => Navigator.of(context).pushNamed("/createRoom"),
              fontSize: 24.0,
              width: 70.0,
            ).getRoundedRaisedButton(),
          ],
        ),
      ),
    );
  }

  Widget getRooms(QuerySnapshot snapshot) {
    List<Room> rooms = [];
    List<Widget> list = [
      Divider(
        color: borderColor,
      )
    ];

    snapshot.documents.forEach((DocumentSnapshot document) {
      rooms.add(
        Room(document.data['id'], document.data['name'],
            document.data['createUser'], document.data['imgURL'],
            participantNum: document.data['participantNum']),
      );
    });
    rooms.forEach((Room room) {
      //FirebaseStorageに保存してあるルームの画像を取得
      Image roomImg;
      if (room.imgURL != null) {
        roomImg = Image(image: CachedNetworkImageProvider(room.imgURL));
      }

      //ルームを作成したユーザーはそのルームを削除することができる。
      if (room.createUser == _user.displayName) {
        list.add(
          ListTile(
            onTap: () => Navigator.of(this.context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/chat'),
                builder: (BuildContext context) => ChatPage(room),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'ルームを削除',
              onPressed: () => deleteRoom(room),
            ),
            title: Row(
              children: <Widget>[
                Flexible(child: Text(room.name ?? '？')),
                Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(left: 10.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    border: Border.all(
                      color: const Color.fromARGB(255, 200, 200, 200),
                    ),
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: roomImg != null
                          ? roomImg.image
                          : AssetImage(
                              "assets/images/text_photoSelect.png"), //room.imgがなかった場合に表示
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                )
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('${room.participantNum ?? '？'}人'),
                Padding(padding: EdgeInsets.all(10.0))
              ],
            ),
          ),
        );
      } else {
        list.add(
          ListTile(
            onTap: () => Navigator.of(this.context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/chat'),
                builder: (BuildContext context) => ChatPage(room),
              ),
            ),
            leading: Padding(
              padding: EdgeInsets.all(24.0), //削除アイコンがある場合と文字の開始値がそろうように調整した。
            ),
            title: Row(
              children: <Widget>[
                Text(room.name ?? '？'),
                Container(
                    width: 40,
                    height: 40,
                    margin: EdgeInsets.only(left: 10.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      border: Border.all(
                        color: const Color.fromARGB(255, 200, 200, 200),
                      ),
                      image: DecorationImage(
                        fit: BoxFit.fill,
                        image: roomImg != null
                            ? roomImg.image
                            : AssetImage("assets/images/text_photoSelect.png"),
                      ),
                    )),
                Padding(
                  padding: EdgeInsets.all(10.0),
                )
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('${room.participantNum ?? '？'}人'),
                Padding(padding: EdgeInsets.all(10.0))
              ],
            ),
          ),
        );
      }
      list.add(Divider(
        color: borderColor,
      ));
    });

    return list.length > 1
        ? ListView(
            children: list,
            shrinkWrap: true,
          )
        : Center(
            child: Text(
              'チャットルームを\n作成しましょう！',
              style: TextStyle(
                fontSize: 28.0,
                height: 1.5,
              ),
            ),
          );
  }

  void deleteRoom(Room room) {
    showDialog(
        context: this.context,
        builder: (_) {
          if (room.participantNum == 0) {
            return AlertDialog(
              title: Text("【ルームを削除】"),
              content: Text("${room.name}を削除しますか？"),
              actions: <Widget>[
                FlatButton(
                  child: Text("キャンセル"),
                  onPressed: () => Navigator.pop(this.context),
                ),
                FlatButton(
                  child: Text("削除する", style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    DocumentReference roomRef =
                        _firestore.collection("rooms").document(room.id);
                    QuerySnapshot snapshot =
                        await roomRef.collection("messages").getDocuments();
                    snapshot.documents
                        .forEach((DocumentSnapshot document) async {
                      await document.reference.delete();
                    });
                    await roomRef.delete();
                    Navigator.pop(this.context);
                  },
                )
              ],
            );
          } else {
            return AlertDialog(
              title: Text("【使用中のルーム】"),
              content: Text(
                  "${room.name}には${room.participantNum}人のユーザが参加中のため、削除できません。"),
              actions: <Widget>[
                FlatButton(
                  child: Text("戻る"),
                  onPressed: () => Navigator.pop(this.context),
                ),
              ],
            );
          }
        });
  }
}

class RoomCreatePage extends StatefulWidget {
  @override
  _RoomCreatePageState createState() => _RoomCreatePageState();
}

class _RoomCreatePageState extends State<RoomCreatePage> {
  final TextEditingController _roomNameController = TextEditingController();
  double _deviceWidth;
  File _imageFile;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ルームを作成'),
      ),
      body: Container(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      String currentRoomName =
                          _roomNameController.text; //この時点で入力されているルーム名を保存

                      File image = await setImage();
                      setState(() {
                        _imageFile = image;
                      });

                      _roomNameController.text =
                          currentRoomName; //リビルドされTextControllerの値が消えてしまうので、に保存しておいたルーム名を代入
                    },
                    child: Container(
                      width: _deviceWidth * 0.7,
                      height: _deviceWidth * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color.fromARGB(255, 200, 200, 200)),
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: _imageFile != null
                              ? FileImage(_imageFile)
                              : AssetImage(
                                  'assets/images/text_photoSelect.png'),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment(0.7, 0.7),
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 200, 200, 200),
                            ),
                            color: Colors.green,
                          ),
                          child: Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(10.0)),
                CustomTextField(_roomNameController, labelText: "ルーム名")
                    .getSimpleTextField(),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                ),
                SimpleRaisedButton("作成する", () async {
                  if (_imageFile != null) {
                    //_imageFileをFirebase Storageに保存し、ダウンロードURLを取得
                    String imgURL = await getImageURL(_imageFile);
                    //roomのidは作成時のタイムスタンプにする。
                    int id = DateTime.now().millisecondsSinceEpoch;
                    Room room = Room('$id', _roomNameController.text,
                        _user.displayName, imgURL);
                    String result = await createRoom(room);

                    if (result == "success") {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/chat'),
                          builder: (BuildContext context) => ChatPage(room),
                        ),
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: "予期せぬエラーが発生しました。",
                        gravity: ToastGravity.CENTER,
                        fontSize: 20.0,
                      );
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: "画像が選択されていません。",
                      gravity: ToastGravity.CENTER,
                      fontSize: 20.0,
                    );
                  }
                }, fontSize: 24.0, width: 70.0)
                    .getRoundedRaisedButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> createRoom(Room room) async {
    try {
      DocumentReference docRef =
          _firestore.collection('rooms').document(room.id);

      await docRef.setData(<String, dynamic>{
        'id': room.id,
        'name': room.name,
        'createUser': room.createUser,
        'participantNum': 0,
        'imgURL': room.imgURL,
      });
      docRef.collection('messages').document('0').setData(<String, dynamic>{});

      return "success";
    } catch (e) {
      print(e);
      return ("error");
    }
  }
}

class ChatPage extends StatefulWidget {
  final Room room;

  ChatPage(this.room);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionListener =
      ItemPositionsListener.create();
  TextEditingController _messageController = TextEditingController();
  DocumentReference _roomRef;
  Image roomImg;

  @override
  void initState() {
    super.initState();
    entryRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Text(widget.room.name),
                scrollDirection: Axis.horizontal,
              ),
            ),
            Container(
              width: 35,
              height: 35,
              margin: EdgeInsets.only(left: 10.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 255, 255, 255),
                border: Border.all(
                  color: const Color.fromARGB(255, 200, 200, 200),
                ),
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: roomImg != null
                      ? roomImg.image
                      : AssetImage(
                          "assets/images/text_photoSelect.png"), //room.imgがなかった場合に表示
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Center(
            child: StreamBuilder(
                stream: _roomRef.snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  } else {
                    return Text('${snapshot.data['participantNum']}人が参加中　　');
                  }
                }),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width - 20.0,
              margin: EdgeInsets.only(bottom: 10.0),
              padding: EdgeInsets.only(left: 10.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 179, 36),
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: ObjectKey(this),
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "メッセージを入力",
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                  ),
//                  Container(
//                    height: 50.0,
//                    margin: EdgeInsets.only(right: 5.0),
//                    child: VerticalDivider(
//                      width: 1.0,
//                      color: const Color.fromARGB(255, 0, 179, 36),
//                      thickness: 1.0,
//                    ),
//                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      Message message = Message(
                          DateTime.now().millisecondsSinceEpoch,
                          _messageController.text,
                          _user.displayName);
                      _messageController.clear();
                      FocusScope.of(context).unfocus();
                      await sendMessage(message);
                    },
                    color: const Color.fromARGB(255, 0, 179, 36),
                    highlightColor: const Color.fromARGB(100, 0, 77, 34),
                  )
                ],
              ),
            ),
            StreamBuilder(
              stream: _roomRef.collection('messages').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData)
                  return Center(
                    child: Container(
                      constraints:
                          BoxConstraints(maxWidth: 300.0, maxHeight: 300.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                else {
                  List<DocumentSnapshot> documents = snapshot.data.documents;

                  moveToBottom();

                  if (documents.length > 1) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: ScrollablePositionedList.builder(
//                      child: ListView.builder(
                          itemCount: documents.length - 1,
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionListener,
                          itemBuilder: (BuildContext context, int index) {
                            DocumentSnapshot document =
                                documents.elementAt(index + 1);
                            Message message = Message(
                              document.data['generatedTime'] ?? 0,
                              document.data['content'] ?? '',
                              document.data['userName'] ?? '',
                            );
                            return buildMessageRow(message);
                          },
                        ),
                      ),
                    );
                  } else {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageRow(Message message) {
    if (message.userName == _user.displayName) {
      message.alignment = CrossAxisAlignment.end;
      message.textDirection = TextDirection.rtl;
      message.backgroundColor = Color.fromARGB(255, 227, 251, 232);
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: message.alignment,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 5.0),
            child: Text(
              message.userName,
              style: TextStyle(fontSize: 10.0),
            ),
          ),
          Row(
            textDirection: message.textDirection,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(255, 0, 179, 36)),
                    borderRadius: BorderRadius.circular(10.0),
                    color: message.backgroundColor,
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(3.0),
              ),
              Container(
                height: 50.0,
                alignment: Alignment.bottomCenter,
                child: Text(
                  ((DateTime.fromMillisecondsSinceEpoch(message.generatedTime))
                      .toString()
                      .substring(0, 19)),
                  style: TextStyle(fontSize: 10.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage(Message message) async {
    //メッセージ送信時のタイムスタンプをidとするメッセージのドキュメントをFirestoreに保存
    await _roomRef
        .collection('messages')
        .document(message.generatedTime.toString())
        .setData(<String, dynamic>{
      "generatedTime": message.generatedTime,
      "content": message.content,
      "userName": message.userName,
    });
  }

  Future<void> entryRoom() async {
    //FirebaseStorageからルーム画像を取得
    if (widget.room.imgURL != null) {
      roomImg = Image(image: CachedNetworkImageProvider(widget.room.imgURL));
    }

    //ルームの参加人数を１人追加
    _roomRef = _firestore.collection('rooms').document(widget.room.id);
    await _roomRef.updateData(<String, dynamic>{
      'participantNum': FieldValue.increment(1),
    });
  }

  Future<void> leaveRoom() async {
    await _roomRef.updateData(<String, dynamic>{
      'participantNum': FieldValue.increment(-1),
    });
    //ルームの削除は削除ボタンで行う仕様にした。
//    DocumentSnapshot document = await _roomRef.get();
//    if (document.data['participantNum'] == 0) {
//      QuerySnapshot snapshot =
//          await _roomRef.collection('messages').getDocuments();
//      snapshot.documents.forEach((DocumentSnapshot document) async {
//        await document.reference.delete();
//      });
//      await _roomRef.delete();
//    }
  }

  Future<void> moveToBottom() async {
    await _roomRef
        .collection('messages')
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      _itemScrollController.jumpTo(
        index: snapshot.documents.length - 2, //１個ダミーを入れてるのと、indexは0から始まるので-2する。
      );
    });
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final UserUpdateInfo _userUpdateInfo = UserUpdateInfo();

  double _deviceWidth;
  File _imageFile;
  Image _image;

  @override
  void initState() {
    super.initState();
    _userNameController.text = _user.displayName ?? null;
    if (_user.photoUrl != null) {
      _image = Image(image: CachedNetworkImageProvider(_user.photoUrl));
    }
    getUserData();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィールを編集'),
      ),
      body: Container(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      File image = await setImage();
                      setState(() {
                        _imageFile = image;
                      });
                    },
                    child: Container(
                      width: _deviceWidth * 0.7,
                      height: _deviceWidth * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color.fromARGB(255, 200, 200, 200)),
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: _imageFile != null
                              ? FileImage(_imageFile)
                              : _image != null
                                  ? _image.image
                                  : AssetImage(
                                      'assets/images/text_photoSelect.png'),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment(0.7, 0.7),
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 200, 200, 200),
                            ),
                            color: Colors.green,
                          ),
                          child: Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                CustomTextField(_userNameController, labelText: "ユーザー名")
                    .getSimpleTextField(),
                CustomTextField(
                  _commentController,
                  labelText: "コメント",
                  textInputType: TextInputType.multiline,
                  maxLine: 5,
                  maxLength: 300,
                ).getSimpleTextField(),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                ),
                SimpleRaisedButton("保存", saveProfile,
                        fontSize: 24.0, width: 70.0)
                    .getRoundedRaisedButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getUserData() async {
    DocumentSnapshot document;

    document = await _firestore.collection('users').document(_user.uid).get();
    _commentController.text = document.data['comment'] ?? "";
  }

  Future<void> saveProfile() async {
    _userUpdateInfo.displayName = _userNameController.text;
    if (_imageFile != null) {
      _userUpdateInfo.photoUrl = await getImageURL(_imageFile);
    }
    await _user.updateProfile(_userUpdateInfo);
    _user = await _firebaseAuth.currentUser();

    //uidをドキュメント名にしてユーザー情報をFirestoreの'users'コレクションに保存s
    _firestore.collection('users').document(_user.uid).setData({
      'id': _user.uid,
      'name': _user.displayName,
      'email': _user.email,
      'photoUrl': _user.photoUrl,
      'comment': _commentController.text,
    });

    Navigator.of(this.context).pop();
  }
}

//モバイルのローカルストレージから写真を取得し、正方形にトリミングしてから圧縮したFile型の画像ファイルを返す。
Future<File> setImage() async {
  File image = await ImagePicker.pickImage(source: ImageSource.gallery);

  ImageProperties properties =
      await FlutterNativeImage.getImageProperties(image.path);
  //画像が縦長の場合
  if (properties.width < properties.height) {
    image = await FlutterNativeImage.cropImage(
      image.path,
      0,
      ((properties.height - properties.width) / 2).round(),
      properties.width,
      properties.width,
    );
  }
  //画像が横長の場合
  else {
    image = await FlutterNativeImage.cropImage(
      image.path,
      ((properties.width - properties.height) / 2).round(),
      0,
      properties.height,
      properties.height,
    );
  }
  image = await FlutterNativeImage.compressImage(image.path,
      quality: 80,
      targetWidth: 600,
      targetHeight: (properties.height * 600 / properties.width).round());

  return image;
}

//引数に受け取ったFile型の画像データをFirebase-Storageに保存し、そのデータのダウンロードURLを返す。
Future<String> getImageURL(File file) async {
  int timeStamp = DateTime.now().millisecondsSinceEpoch;
  final StorageReference reference =
      _firebaseStorage.ref().child('images').child('$timeStamp');

  //アップロードする画像ファイルの拡張子を取得し、メタデータのcontentTypeの指定に使う。
  String fileExtension = extension(file.path);
  String contentType = "image/";
  switch (fileExtension) {
    case ".jpg":
      contentType = contentType + "jpeg";
      break;
    case ".jpeg":
      contentType = contentType + "jpeg";
      break;
    case ".png":
      contentType = contentType + "png";
      break;
    case ".gif":
      contentType = contentType + "gif";
      break;
    default:
      break;
  }
  final StorageUploadTask uploadTask =
      reference.putFile(file, StorageMetadata(contentType: contentType));

  StorageTaskSnapshot snapshot = await uploadTask.onComplete;
  if (snapshot.error == null) {
    return await snapshot.ref.getDownloadURL();
  } else {
    print('error: ${snapshot.error}');
    return null;
  }
}
