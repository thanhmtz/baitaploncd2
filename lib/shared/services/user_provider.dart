import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:health_tracker/data/models/user_model.dart';
import 'package:health_tracker/data/repositories/firebase_auth.dart';
import 'package:health_tracker/shared/constants/consts_variables.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final FirebaseAuthRepo _authRepo = FirebaseAuthRepo();

  User get getUser => _user!;
  bool get isLoaded => _user != null;

  Future<void> refreshUser() async {
    final user = await _authRepo.getUserDetails();
    _user = user;
    notifyListeners();
  }

  Future<void> updateMacroGoals({
    required int goalCalories,
    required int goalProteinPct,
    required int goalFatPct,
    required int goalCarbsPct,
  }) async {
    if (_user == null) {
      await refreshUser();
    }

    if (_user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
      'goalCalories': goalCalories,
      'goalProteinPct': goalProteinPct,
      'goalFatPct': goalFatPct,
      'goalCarbsPct': goalCarbsPct,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await refreshUser();
  }

  Future<void> updateSex(Sex sex) async {
    if (_user == null) {
      await refreshUser();
    }

    if (_user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({'sex': sex == Sex.male ? 1 : 2});

    await refreshUser();
  }
}
