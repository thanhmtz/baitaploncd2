import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_tracker/data/models/post_model.dart';
import 'package:health_tracker/data/repositories/storage.dart';
import 'package:health_tracker/providers/tree_provider.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FireStoreCrud {
  // FireStoreCrud();

  final _firestore = FirebaseFirestore.instance;

  // Upload a post
  Future<String> uploadPost(String description, Uint8List? file, String uid,
      String username, String profImage) async {
    String res = "Some error occured";
    try {
      String? photoUrl;
      if (file != null) {
        photoUrl =
            await FireStorage().uploadImageToStorage('posts', file, true);
      }
      String postId = const Uuid().v1();
      Post post = Post(
          description: description,
          uid: uid,
          username: username,
          likes: [],
          postId: postId,
          datePublished: DateTime.now(),
          postUrl: photoUrl,
          profImage: profImage);
      _firestore.collection('posts').doc(postId).set(post.toJson());
      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        // if the likes list contains the user uid, we need to remove it
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // else we need to add uid to the likes array
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Post comment
  Future<String> postComment(String postId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        // if the likes list contains the user uid, we need to remove it
        String commentId = const Uuid().v1();
        _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Delete Post
  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateDiaryMeal(
      String meal,
      String foodId,
      String type,
      String name,
      double calories,
      double carbs,
      double fat,
      double protein,
      {String? imageUrl,
      List<dynamic>? nutrients,
      double? fiber,
      double? sugar,
      double? sodium}) async {
    try {
      _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(DateTime.now()))
          .set({
        'totalCalories': FieldValue.increment(calories),
        'totalProtein': FieldValue.increment(protein),
        'totalCarbs': FieldValue.increment(carbs),
        'totalFat': FieldValue.increment(fat),
        if (fiber != null) 'totalFiber': FieldValue.increment(fiber),
        if (sugar != null) 'totalSugar': FieldValue.increment(sugar),
        if (sodium != null) 'totalSodium': FieldValue.increment(sodium),
        meal: {
          '${meal.toLowerCase()}Calories': FieldValue.increment(calories),
          '${meal.toLowerCase()}Protein': FieldValue.increment(protein),
          '${meal.toLowerCase()}Fat': FieldValue.increment(fat),
          '${meal.toLowerCase()}Carbs': FieldValue.increment(carbs),
          'foods': FieldValue.arrayUnion([
            {
              'id': foodId,
              'name': name,
              'calories': calories,
              'carbs': carbs,
              'protein': protein,
              'fat': fat,
              'source': type,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
              if (fiber != null) 'fiber': fiber,
              if (sugar != null) 'sugar': sugar,
              if (sodium != null) 'sodium': sodium,
              if (imageUrl != null) 'imageUrl': imageUrl,
              if (nutrients != null) 'nutrients': nutrients,
            }
          ])
        }
      }, SetOptions(merge: true)).onError(
              (error, stackTrace) => log('Error writing document: $error'));

      TreeService().addCaloriesXp();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> removeDiaryMealFood(
      String meal,
      String foodId,
      String name,
      double calories,
      double carbs,
      double fat,
      double protein,
      String type,
      {double? fiber,
      double? sugar,
      double? sodium}) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(DateTime.now()));

      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final mealKey = meal;
      final mealData = data[mealKey];

      if (mealData is Map && mealData['foods'] is List) {
        final foods = List<Map<String, dynamic>>.from(
          mealData['foods'].map((f) => Map<String, dynamic>.from(f as Map)),
        );

        int? foodIndex;
        for (int i = 0; i < foods.length; i++) {
          if (foods[i]['id'] == foodId) {
            foodIndex = i;
            break;
          }
        }

        if (foodIndex != null) {
          foods.removeAt(foodIndex);

          await docRef.update({
            'totalCalories': FieldValue.increment(-calories),
            'totalProtein': FieldValue.increment(-protein),
            'totalCarbs': FieldValue.increment(-carbs),
            'totalFat': FieldValue.increment(-fat),
            if (fiber != null) 'totalFiber': FieldValue.increment(-fiber),
            if (sugar != null) 'totalSugar': FieldValue.increment(-sugar),
            if (sodium != null) 'totalSodium': FieldValue.increment(-sodium),
            '$mealKey.${mealKey.toLowerCase()}Calories':
                FieldValue.increment(-calories),
            '$mealKey.${mealKey.toLowerCase()}Protein':
                FieldValue.increment(-protein),
            '$mealKey.${mealKey.toLowerCase()}Fat':
                FieldValue.increment(-fat),
            '$mealKey.${mealKey.toLowerCase()}Carbs':
                FieldValue.increment(-carbs),
            '$mealKey.foods': foods,
          });
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateDiaryWeight(DateTime date, String weight, String? bodyFat,
      String? skeletalMuscle, String? notes) async {
    try {
      _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(date))
          .set({
        'weight': FieldValue.arrayUnion([
          {
            'hour': date.hour,
            'minute': date.minute,
            'weight': weight,
            'bodyFat': bodyFat,
            'notes': notes
          }
        ])
      }, SetOptions(merge: true)).onError(
              (error, stackTrace) => log('Error writing document: $error'));
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> updateDiaryBloodPressure({
    required int systolic,
    required int diastolic,
    required int pulse,
    required DateTime date,
    String? notes,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(date))
          .set({
        'bloodPressure': FieldValue.arrayUnion([
          {
            'systolic': systolic,
            'diastolic': diastolic,
            'pulse': pulse,
            'hour': date.hour,
            'minute': date.minute,
            'notes': notes ?? '',
          }
        ])
      }, SetOptions(merge: true));
    } catch (e) {
      log('Update blood pressure error: $e');
    }
  }

  Future<void> updateDiaryBloodSugar({
    required double value,
    required String mealContext,
    required DateTime date,
    String? notes,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(date))
          .set({
        'bloodSugar': FieldValue.arrayUnion([
          {
            'value': value,
            'mealContext': mealContext,
            'hour': date.hour,
            'minute': date.minute,
            'notes': notes ?? '',
          }
        ])
      }, SetOptions(merge: true));
    } catch (e) {
      log('Update blood sugar error: $e');
    }
  }

  Future<void> updateDiaryWater(int waterValue) async {
    try {
      _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(DateTime.now()))
          .set({'water': waterValue}, SetOptions(merge: true)).onError(
              (error, stackTrace) => log('Error writing document: $error'));
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> quickAddMacros(
      double calories, double protein, double fat, double carbs) async {
    try {
      _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('diary')
          .doc(DateFormat('d-M-y').format(DateTime.now()))
          .set({
        'totalCalories': FieldValue.increment(calories),
        'quickAdd': {
          'calories': FieldValue.increment(calories),
          'protein': FieldValue.increment(protein),
          'fat': FieldValue.increment(fat),
          'carbs': FieldValue.increment(carbs),
        }
      }, SetOptions(merge: true)).onError(
              (error, stackTrace) => log('Error writing document: $error'));
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> bookmarkRecipe(String recipeId) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot user = await _firestore.collection('users').doc(uid).get();

    try {
      if (user['bookmarkedRecipes'].contains(recipeId)) {
        // if already bookmarked then remove from bookmarks
        _firestore.collection('users').doc(uid).update({
          'bookmarkedRecipes': FieldValue.arrayRemove([recipeId])
        });
        log("Bookmark Removed");
      } else {
        _firestore.collection('users').doc(uid).update({
          'bookmarkedRecipes': FieldValue.arrayUnion([recipeId])
        });
        log("Bookmark Added");
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Recipe rating methods
  Future<Map<String, dynamic>> getRecipeRating(String recipeId) async {
    try {
      final doc = await _firestore.collection('recipes').doc(recipeId).get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {'rating': 0.0, 'reviewCount': 0, 'totalStars': 0};
    } catch (e) {
      return {'rating': 0.0, 'reviewCount': 0, 'totalStars': 0};
    }
  }

  Future<double?> getUserRecipeRating(String recipeId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await _firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('reviews')
          .doc(uid)
          .get();
      if (doc.exists) {
        return (doc.data()!['rating'] as num).toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> rateRecipe(String recipeId, double rating) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final reviewRef = _firestore
          .collection('recipes')
          .doc(recipeId)
          .collection('reviews')
          .doc(uid);
      final recipeRef = _firestore.collection('recipes').doc(recipeId);

      final existing = await reviewRef.get();
      final oldRating = existing.exists ? (existing.data()!['rating'] as num).toDouble() : null;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(recipeRef);
        final data = snapshot.data() ?? {};
        final totalStars = (data['totalStars'] as num?)?.toDouble() ?? 0;
        final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

        double newTotalStars;
        int newReviewCount;

        if (oldRating != null) {
          newTotalStars = totalStars - oldRating + rating;
          newReviewCount = reviewCount;
        } else {
          newTotalStars = totalStars + rating;
          newReviewCount = reviewCount + 1;
        }

        final newRating = newReviewCount > 0 ? newTotalStars / newReviewCount : 0.0;

        transaction.set(recipeRef, {
          'rating': newRating,
          'reviewCount': newReviewCount,
          'totalStars': newTotalStars,
        });

        transaction.set(reviewRef, {
          'rating': rating,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      });
    } catch (e) {
      log('Rate recipe error: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? bio,
    String? photoUrl,
    Uint8List? newPhoto,
  }) async {
    try {
      String? uploadedPhotoUrl = photoUrl;
      
      if (newPhoto != null) {
        uploadedPhotoUrl = await FireStorage().uploadImageToStorage('profilePics', newPhoto, false);
      }
      
      final Map<String, dynamic> updates = {};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (uploadedPhotoUrl != null) updates['photoUrl'] = uploadedPhotoUrl;
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() ?? {};
    } catch (e) {
      throw e.toString();
    }
  }

  // Get users by IDs
  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> uids) async {
    try {
      final users = <Map<String, dynamic>>[];
      for (final uid in uids) {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          users.add(doc.data()!);
        }
      }
      return users;
    } catch (e) {
      throw e.toString();
    }
  }

  // ─── MY DISHES ────────────────────────────────────────────────────────────

  Future<String?> addMyDish({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? imageUrl,
    String? recipeId,
    String? mealType,
    String? diaryFoodId,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('myDishes')
          .add({
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'imageUrl': imageUrl ?? '',
        'recipeId': recipeId ?? '',
        'mealType': mealType ?? '',
        'diaryFoodId': diaryFoodId ?? '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      return docRef.id;
    } catch (e) {
      log('Add my dish error: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> streamMyDishes() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('myDishes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteMyDish(String docId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('myDishes')
          .doc(docId)
          .delete();
    } catch (e) {
      log('Delete my dish error: $e');
    }
  }

  // Stream<List<model.User>> getUsers() => _firestore.collection('users').snapshots().transform(Utils.transformer(model.User.fromSnap));
}
