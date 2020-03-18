import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';

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
                  .getSimpleRaisedButton(),
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomTextField(_eMailController, "e-mail")
                      .getSimpleTextField(),
                  Padding(padding: const EdgeInsets.all(20.0)),
                  CustomTextField(_passwordController, "password")
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
                  print("signInError: e");
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
                .getSimpleRaisedButton(),
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
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント登録'),
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(30.0),
            ),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomTextField(_eMailController, "e-mail")
                      .getSimpleTextField(),
                  Padding(padding: const EdgeInsets.all(20.0)),
                  CustomTextField(_passwordController, "password")
                      .getSecretTextField(),
                ],
              ),
            ),
            SimpleRaisedButton("登録する", () {
              if (_eMailController.text != "" &&
                  _passwordController.text != "") {
                _signUp(_eMailController.text, _passwordController.text).then(
                  (AuthResult result) {
                    _user = result.user;
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil("/roomList", (_) => false);
                    registProfile();
                  },
                ).catchError((e) {
                  print("signUpError: e");
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
                  backgroundColor: Colors.redAccent,
                  fontSize: 20.0,
                );
              }
            }, fontSize: 24.0, width: 70.0)
                .getSimpleRaisedButton(),
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

  Future<void> registProfile() async {
    //uidをドキュメント名にしてユーザー情報をFirestoreの'users'コレクションに登録
    _firestore.collection('users').document(_user.uid).setData({
      'id': _user.uid,
      'email': _user.email,
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
            ).getSimpleRaisedButton(),
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
            document.data['careateUser'],
            participantNum: document.data['participantNum']),
      );
    });
    rooms.forEach((Room room) {
      list.add(
        ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/chat'),
              builder: (BuildContext context) => ChatPage(room),
            ),
          ),
          leading: Padding(padding: EdgeInsets.all(20.0)),
          title: Text(room.name ?? '？'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('${room.participantNum ?? '？'}人'),
              Padding(padding: EdgeInsets.all(20.0))
            ],
          ),
        ),
      );
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
}

class RoomCreatePage extends StatelessWidget {
  final TextEditingController _roomNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルームを作成'),
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CustomTextField(_roomNameController, "ルーム名").getSimpleTextField(),
              Padding(
                padding: const EdgeInsets.all(30.0),
              ),
              SimpleRaisedButton("作成する", () async {
                //roomのidはタイムスタンプを使う。
                int id = DateTime.now().millisecondsSinceEpoch;
                Room room =
                    Room('$id', _roomNameController.text, _user.displayName);
                await createRoom(room);

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/chat'),
                    builder: (BuildContext context) => ChatPage(room),
                  ),
                );
              }, fontSize: 24.0, width: 70.0)
                  .getSimpleRaisedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> createRoom(Room room) async {
    return await _firestore
        .collection('rooms')
        .document(room.id)
        .setData(<String, dynamic>{
      'id': room.id,
      'name': room.name,
      'createUser': room.createUser,
      'participantNum': 1,
    });
  }
}

class ChatPage extends StatefulWidget {
  final Room room;

  ChatPage(this.room);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット'),
        actions: <Widget>[
          Center(
            child: Text('${widget.room.name}　　'),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                  hintText: "メッセージを入力",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  fillColor: Colors.white70,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {},
                    highlightColor: const Color.fromARGB(100, 0, 77, 34),
                  )),
            ),
            StreamBuilder(
              stream: _firestore
                  .collection('rooms')
                  .document(widget.room.id)
                  .collection('messages')
                  .snapshots(),
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

                  return Container(
                    constraints: BoxConstraints.expand(
                        height: MediaQuery.of(context).size.height -
                            AppBar().preferredSize.height -
                            100),
                    child: ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (BuildContext context, int index) {
                        DocumentSnapshot document =
                            snapshot.data.documents.elementAt(index);
                        Message message = Message(document.data['content'],
                            document.data['userName']);
                        return buildMessageRow(message);
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Row buildMessageRow(Message message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          message.userName,
          style: TextStyle(fontSize: 10.0),
        ),
        Padding(
          padding: EdgeInsets.all(10.0),
        ),
        Text(
          message.content,
          style: TextStyle(fontSize: 20.0),
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _userNameController = TextEditingController();
  final UserUpdateInfo _userUpdateInfo = UserUpdateInfo();

  double deviceWidth;
  double bodyHeight;
  File _imageFile;
  Image _image;

  @override
  void initState() {
    super.initState();
    _userNameController.text = _user.displayName ?? null;
    if (_user.photoUrl != null) {
      _image = Image(image: CachedNetworkImageProvider(_user.photoUrl));
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    bodyHeight =
        MediaQuery.of(context).size.height - AppBar().preferredSize.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィールを編集'),
      ),
      body: Container(
        height: bodyHeight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: setImage,
                  child: Container(
                    width: deviceWidth * 0.7,
                    height: deviceWidth * 0.7,
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
              Padding(
                padding: const EdgeInsets.all(20.0),
              ),
              CustomTextField(_userNameController, "ユーザー名")
                  .getSimpleTextField(),
              Padding(
                padding: const EdgeInsets.all(30.0),
              ),
              SimpleRaisedButton("保存", saveProfile, fontSize: 24.0, width: 70.0)
                  .getSimpleRaisedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(image.path);
    //画像が横長の場合
    if (properties.width < properties.height) {
      image = await FlutterNativeImage.cropImage(
        image.path,
        0,
        ((properties.height - properties.width) / 2).round(),
        properties.width,
        properties.width,
      );
    }
    //画像が縦長の場合
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

    setState(() {
      _imageFile = image;
    });
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
    });

    Navigator.of(context).pop();
  }

  Future<String> getImageURL(File file) async {
    print(file);
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    final StorageReference reference =
        _firebaseStorage.ref().child('images').child('$timeStamp');
    final StorageUploadTask uploadTask =
        reference.putFile(file, StorageMetadata(contentType: "image/jpeg"));

    StorageTaskSnapshot snapshot = await uploadTask.onComplete;
    if (snapshot.error == null) {
      return await snapshot.ref.getDownloadURL();
    } else {
      print('error: ${snapshot.error}');
      return null;
    }
  }
}

class CustomTextField {
  final TextEditingController controller;
  final String hintText;
  bool isValid;

  CustomTextField(this.controller, this.hintText, {this.isValid: false});

  Padding getSimpleTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hintText,
        ),
        style: const TextStyle(fontSize: 18.0),
      ),
    );
  }

  Padding getSecretTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: hintText,
        ),
        style: const TextStyle(fontSize: 18.0),
      ),
    );
  }
}

class SimpleRaisedButton {
  final String text;
  final double fontSize;
  final double width;
  final Function function;

  SimpleRaisedButton(this.text, this.function,
      {this.fontSize: 24.0, this.width: 70.0});

  RaisedButton getSimpleRaisedButton() {
    return RaisedButton(
      padding: EdgeInsets.symmetric(horizontal: width, vertical: 15.0),
      shape: StadiumBorder(),
      color: const Color.fromARGB(255, 0, 102, 20),
      highlightColor: const Color.fromARGB(255, 0, 179, 36),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
      onPressed: function,
    );
  }
}

class Room {
  final String id;
  final String name;
  final String createUser;
  int participantNum;

  Room(this.id, this.name, this.createUser, {this.participantNum});
}

class Message {
  final String content;
  final String userName;

  Message(this.content, this.userName);
}
