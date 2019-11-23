import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

void signOut() {
  _auth.signOut();
  _googleSignIn.signOut();
}

Future<FirebaseUser> handleSignIn() async {
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
  print("signed in " + user.displayName);
  return user;
}


Future signInErrorAlert(BuildContext context) async {
  await showDialog(context: context, builder: (context) {
    return AlertDialog(
      title: Text("Login required"),
      content: Text("You need to log in to add posts"),
      actions: <Widget>[
        FlatButton(
          child: Text("Dismiss"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  });
}
