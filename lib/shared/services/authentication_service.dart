import 'dart:developer';
import 'package:health_tracker/data/models/user_model.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_tracker/shared/constants/consts_variables.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // AuthenticationService(this._firebaseAuth, this._firestore);

  Future<model.User> getUserDetails() async {
    User currentUser = _firebaseAuth.currentUser!;

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();
    return model.User.fromSnap(documentSnapshot);
  }

  // Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
    log('Signed Out');
  }

  // EMAIL AUTHENTICATION
  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      log('Signed In');
      return "success";
    } on FirebaseAuthException catch (e) {
      log(e.message!);
      return e.message;
    }
  }

  Future<String?> signUp(
      {required String name,
      required Sex? sex,
      required String email,
      required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      model.User user = model.User(
        username: name,
        sex: sex,
        uid: userCredential.user!.uid,
        photoUrl: '',
        email: email,
        bio: '',
        isDarkMode: true,
        bookmarkedRecipes: [],
        followers: [],
        following: [],
        createdAt: DateTime.now(),
        goalCalories: 2000,
        dailyStreak: 0,
        totalStars: 0,
      );

      await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .set(user.toJson());

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
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

      log('Signed Up');
      return "success";
    } on FirebaseAuthException catch (e) {
      log(e.message!);
      return e.message;
    }
  }

  // GOOGLE AUTHENTICATION

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '409829871485-92a71rr7pnon4ks5dkgud05cf8571kei.apps.googleusercontent.com',
      );
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        log('Google sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception('Không lấy được thông tin xác thực Google');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          final model.User newUser = model.User(
            username: user.displayName ?? 'User',
            sex: null,
            uid: user.uid,
            photoUrl: user.photoURL ?? '',
            email: user.email ?? '',
            bio: '',
            isDarkMode: true,
            bookmarkedRecipes: [],
            followers: [],
            following: [],
            createdAt: DateTime.now(),
            goalCalories: 2000,
            dailyStreak: 0,
            totalStars: 0,
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toJson());

          await _firestore
              .collection('users')
              .doc(user.uid)
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
        }
      }

      log('Signed Up With Google');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('Google sign-in Firebase error: ${e.message}');
      throw Exception(e.message ?? 'Đăng nhập Google thất bại');
    } catch (e) {
      log('Google sign-in error: $e');
      rethrow;
    }
  }
}
