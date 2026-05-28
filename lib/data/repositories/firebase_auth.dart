import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_tracker/data/repositories/storage.dart';
import 'package:health_tracker/data/repositories/user_repository.dart';
import 'package:health_tracker/data/models/user_model.dart' as model;
import 'package:health_tracker/shared/constants/consts_variables.dart';

class FirebaseAuthRepo implements UserRepository {
  FirebaseAuthRepo();

  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<model.User> getUserDetails() async {
    User currentUser = _firebaseAuth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> register(
      {required String username,
      required String email,
      required String password,
      required Sex sex,
      Uint8List? file}) async {
    try {
      UserCredential cred = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      _firebaseAuth.currentUser!.updateDisplayName(username);
      String photoUrl = file != null
          ? await FireStorage().uploadImageToStorage('profilePics', file, false)
          : 'https://i.stack.imgur.com/l60Hf.png';

      model.User user = model.User(
        username: username,
        uid: cred.user!.uid,
        sex: sex,
        photoUrl: photoUrl,
        email: email,
        bio: '',
        bookmarkedRecipes: [],
        followers: [],
        following: [],
        isDarkMode: true,
        createdAt: DateTime.now(),
        goalCalories: 2000,
        dailyStreak: 0,
        totalStars: 0,
      );

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toJson());

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .collection('tree_data')
          .doc('main')
          .set({
        'treeLevel': 1,
        'totalXp': 0,
        'currentXp': 0,
        'treeStage': 'Seed',
        'streakDays': 0,
        'todayXp': 0,
        'dataDate': DateTime.now().toIso8601String().substring(0, 10),
        'lastActiveDate': '',
        'todayActivities': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  logout() async {
    try {
      await GoogleSignIn().signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signinanonym() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.toString());
    }
  }
}
