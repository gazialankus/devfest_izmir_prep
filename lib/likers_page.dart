import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LikersPage extends StatefulWidget {
  final DocumentSnapshot postDocument;

  LikersPage(this.postDocument);

  @override
  _LikersPageState createState() => _LikersPageState();
}

class _LikersPageState extends State<LikersPage> {
  List<DocumentSnapshot> docs;

  @override
  void initState() {
    super.initState();
    startLoadingLikers();
  }

  Future startLoadingLikers() async {
    Stream<QuerySnapshot> snapshots = widget.postDocument.reference.collection("likers").snapshots();

    await for (QuerySnapshot shot in snapshots) {
      if (!mounted) return;

      setState(() {
        docs = shot.documents;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    if (docs == null) {
      return CircularProgressIndicator();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Likers of ${widget.postDocument.data["title"]}"),
        ),
        body: ListView(
          children: docs
              .map((doc) => ListTile(
                    title: Text(doc.data["name"]),
                  ))
              .toList(),
        )
    );
  }

  Widget buildWithFuture(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Likers of ${widget.postDocument.data["title"]}"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future:
            widget.postDocument.reference.collection("likers").getDocuments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          if (snapshot.data.documents.isEmpty) {
            return Text("Nobody liked this so far");
          }
          return ListView(
            children: snapshot.data.documents
                .map((doc) => ListTile(
                      title: Text(doc.data["name"]),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
