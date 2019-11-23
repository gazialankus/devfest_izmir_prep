import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'post_list_view.dart';
import 'signin.dart' as auth;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool addInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          FlatButton(
            child: Icon(Icons.exit_to_app),
            onPressed: () {
              auth.signOut();
            },
          )
        ],
      ),
      body: PostListView(),
      floatingActionButton: addInProgress ? null : FloatingActionButton(
        onPressed: () async {
          var firebaseUser = await FirebaseAuth.instance.currentUser();
          if (firebaseUser == null) {
            print("WILL ACTUALLY LOG IN");
            firebaseUser = await auth.handleSignIn();
          }

          if (firebaseUser == null) {
            await auth.signInErrorAlert(context);
            return;
          }

          print(firebaseUser.uid);


          final newPost = await showDialog<Map>(context: context, builder: (context) {
            var title = "";
            var bodyController = TextEditingController();

            return AlertDialog(
              title: Text("Yeni Yazı"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: TextField(
                      onChanged: (v) => title = v,
                      decoration: InputDecoration(
                        labelText: "Başlık",
                      ),
                    ),
                  ),
                  Flexible(
                    child: TextField(
                      controller: bodyController,
                      decoration: InputDecoration(
                        labelText: "İçerik",
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text("Vazgeç"),
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                ),
                FlatButton(
                  child: Text("Kaydet"),
                  onPressed: () {
                    Navigator.of(context).pop({
                      "title": title,
                      "body": bodyController.text,
                      "authorUid": firebaseUser.uid,
                      "authorName": firebaseUser.displayName
                    });
                  },
                ),
              ],
            );
          });

          if (newPost == null) return;

          setState(() {
            addInProgress = true;
          });
          try {
            await Firestore.instance.collection("posts").add(newPost);
          } finally {
            setState(() {
              addInProgress = false;
            });
          }
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

}

