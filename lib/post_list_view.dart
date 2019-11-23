import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devfest_izmir_prep/likers_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'signin.dart' as auth;

class PostListView extends StatefulWidget {
  const PostListView({
    Key key,
  }) : super(key: key);

  @override
  _PostListViewState createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  Stream<QuerySnapshot> _documentsStream;
  Set<String> ownLikes = {};

  @override
  void initState() {
    super.initState();
    _documentsStream = Firestore.instance.collection("posts").snapshots();
    updateOwnLikes();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _documentsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

//        return Text("DATA! ${snapshot.data.documents.length}");
        return buildList(snapshot.data);
      },
    );
  }

  ListView buildList(QuerySnapshot data) {
    TextStyle s = TextStyle();
    List<Widget> tiles = data.documents.map((DocumentSnapshot postSnapshot) {
      bool likeInProgress = false;

      return Container(
        child: ListTile(
          onTap: () {
            print("tapped");
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return LikersPage(postSnapshot);
            }));
          },
          title: RichText(
            text: TextSpan(
                style: Theme.of(context).textTheme.subhead,
                text: postSnapshot.data["title"],
                children: <InlineSpan>[
                  TextSpan(
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                    text: "  ${postSnapshot.data["authorName"]}",
                  )
                ]),
          ),
//            title: Text(e.data["title"]),
          subtitle: Text(postSnapshot.data["body"]),
          leading: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: IconButton(
                    icon: Icon(
                      ownLikes.contains(postSnapshot.documentID) ?
                        Icons.favorite : Icons.favorite_border
                    ),
                    onPressed: likeInProgress ? null : () async {
                      setState(() {
                        likeInProgress = true;
                      });
                      try {
//                        FirebaseUser firebaseUser =
//                            await FirebaseAuth.instance.currentUser();
                        FirebaseUser firebaseUser = await auth.handleSignIn();

                        if (firebaseUser == null) {
                          await auth.signInErrorAlert(context);
                          return;
                        }

                        if (ownLikes.contains(postSnapshot.documentID)) {
                          await doUnlike(firebaseUser, postSnapshot);
                        } else {
                          await doLike(firebaseUser, postSnapshot);
                        }

                      } finally {
                        likeInProgress = false;
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                  child: Text(getNumLikesText(postSnapshot.data["numLikes"])))
            ],
          ),
        ),
      );
    }).toList();

    return ListView(
      children: tiles,
    );
  }

  Future doLike(FirebaseUser firebaseUser, DocumentSnapshot postSnapshot) async {
    WriteBatch batch = Firestore.instance.batch();

    batch.setData(
        Firestore.instance
            .collection("users")
            .document(firebaseUser.uid)
            .collection("likedPosts")
            .document(postSnapshot.documentID),
        {"title": postSnapshot.data["title"]});
    batch.updateData(postSnapshot.reference,
        {"numLikes": FieldValue.increment(1)});
    batch.setData(
        postSnapshot.reference
            .collection("likers")
            .document(firebaseUser.uid),
        {"name": firebaseUser.displayName});

    setState(() {
      ownLikes.add(postSnapshot.documentID);
    });
    await batch.commit();
  }

  Future doUnlike(FirebaseUser firebaseUser, DocumentSnapshot postSnapshot) async {
    WriteBatch batch = Firestore.instance.batch();

    batch.delete(Firestore.instance
      .collection("users")
      .document(firebaseUser.uid)
      .collection("likedPosts")
      .document(postSnapshot.documentID));

    batch.updateData(postSnapshot.reference,
      {"numLikes": FieldValue.increment(-1)});

    batch.delete(
      postSnapshot.reference
        .collection("likers")
        .document(firebaseUser.uid));

    setState(() {
      ownLikes.remove(postSnapshot.documentID);
    });
    await batch.commit();
  }


  String getNumLikesText(num data) {
    if (data == null) {
      return "0";
    }
    return "+${data}";
  }

  Future updateOwnLikes() async {
    var firebaseUser = await FirebaseAuth.instance.currentUser();

    var querySnapshot = await Firestore.instance.collection("users")
      .document(firebaseUser.uid)
      .collection("likes").getDocuments();

    Set<String> likedIds = querySnapshot.documents.map((doc) => doc.documentID).toSet();

    setState(() {
      ownLikes = likedIds;
    });
  }

}
