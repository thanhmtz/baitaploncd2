import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_tracker/shared/constants/consts_variables.dart';

class User {
  final String uid, photoUrl, username, email, bio;
  final Sex? sex;
  final bool isDarkMode;
  final DateTime? createdAt;
  final List bookmarkedRecipes, followers, following;
  final double? height;
  final double? weight;
  final int? goalCalories;
  final int? goalProteinPct;
  final int? goalFatPct;
  final int? goalCarbsPct;
  final int? dailyStreak;
  final int? totalStars;

  User({
    required this.username,
    required this.uid,
    required this.sex,
    required this.photoUrl,
    required this.email,
    required this.bio,
    required this.isDarkMode,
    required this.createdAt,
    required this.bookmarkedRecipes,
    required this.followers,
    required this.following,
    this.height,
    this.weight,
    this.goalCalories,
    this.goalProteinPct,
    this.goalFatPct,
    this.goalCarbsPct,
    this.dailyStreak,
    this.totalStars,
  });

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static Sex? _toSex(dynamic value) {
    if (value == 1 || value == '1' || value == 'male') return Sex.male;
    if (value == 2 || value == '2' || value == 'female') return Sex.female;
    return null;
  }

  static User fromSnap(DocumentSnapshot snap) {
    final data = snap.data();

    if (data == null) {
      throw Exception('User document not found');
    }

    final snapshot = data as Map<String, dynamic>;

    return User(
      username: snapshot['username'] ?? '',
      uid: snapshot['uid'] ?? snap.id,
      sex: _toSex(snapshot['sex']),
      photoUrl: snapshot['photoUrl'] ?? '',
      email: snapshot['email'] ?? '',
      bio: snapshot['bio'] ?? '',
      isDarkMode: snapshot['isDarkMode'] is bool
          ? snapshot['isDarkMode']
          : true,
      createdAt: _toDateTime(snapshot['createdAt']),
      bookmarkedRecipes: snapshot['bookmarkedRecipes'] is List
          ? snapshot['bookmarkedRecipes']
          : [],
      followers: snapshot['followers'] is List ? snapshot['followers'] : [],
      following: snapshot['following'] is List ? snapshot['following'] : [],
      height: _toDouble(snapshot['height']),
      weight: _toDouble(snapshot['weight']),
      goalCalories: _toInt(snapshot['goalCalories']),
      goalProteinPct: _toInt(snapshot['goalProteinPct']),
      goalFatPct: _toInt(snapshot['goalFatPct']),
      goalCarbsPct: _toInt(snapshot['goalCarbsPct']),
      dailyStreak: _toInt(snapshot['dailyStreak']),
      totalStars: _toInt(snapshot['totalStars']),
    );
  }

  User copyWith({
    String? username,
    String? uid,
    Sex? sex,
    String? photoUrl,
    String? email,
    String? bio,
    bool? isDarkMode,
    DateTime? createdAt,
    List? bookmarkedRecipes,
    List? followers,
    List? following,
    double? height,
    double? weight,
    int? goalCalories,
    int? goalProteinPct,
    int? goalFatPct,
    int? goalCarbsPct,
    int? dailyStreak,
    int? totalStars,
  }) {
    return User(
      username: username ?? this.username,
      uid: uid ?? this.uid,
      sex: sex ?? this.sex,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      createdAt: createdAt ?? this.createdAt,
      bookmarkedRecipes: bookmarkedRecipes ?? this.bookmarkedRecipes,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goalCalories: goalCalories ?? this.goalCalories,
      goalProteinPct: goalProteinPct ?? this.goalProteinPct,
      goalFatPct: goalFatPct ?? this.goalFatPct,
      goalCarbsPct: goalCarbsPct ?? this.goalCarbsPct,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      totalStars: totalStars ?? this.totalStars,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uid': uid,
      'sex': sex == Sex.male ? 1 : (sex == Sex.female ? 2 : null),
      'photoUrl': photoUrl,
      'email': email,
      'bio': bio,
      'isDarkMode': isDarkMode,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'bookmarkedRecipes': bookmarkedRecipes,
      'followers': followers,
      'following': following,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (goalCalories != null) 'goalCalories': goalCalories,
      if (goalProteinPct != null) 'goalProteinPct': goalProteinPct,
      if (goalFatPct != null) 'goalFatPct': goalFatPct,
      if (goalCarbsPct != null) 'goalCarbsPct': goalCarbsPct,
      if (dailyStreak != null) 'dailyStreak': dailyStreak,
      if (totalStars != null) 'totalStars': totalStars,
    };
  }
}