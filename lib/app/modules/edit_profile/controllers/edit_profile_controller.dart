import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/model/profile_model.dart';

class EditProfileController extends GetxController {
  // Initialize TextEditingControllers
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();

  var profile = ProfileModel(
    userName: 'User Name',
    email: 'user@example.com',
    phoneNumber: '+1234567890',
  ).obs;

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  var videoPath = ''.obs; // Path for recorded video
  VideoPlayerController? videoPlayerController; // Video player controller

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        profile.update((val) {
          val!.userName = data['userName'] ?? '';
          val.email = data['email'] ?? '';
          val.phoneNumber = data['phoneNumber'] ?? '';
          val.profileImage = _storage.read('profileImage') ?? '';
        });

        // Load video if it exists
        final storedVideoPath = _storage.read('profileVideo');
        if (storedVideoPath != null) {
          videoPath.value = storedVideoPath;
          videoPlayerController =
              VideoPlayerController.file(File(storedVideoPath))
                ..initialize().then((_) {
                  update(); // Update UI
                });
        }

        userNameController.text = profile.value.userName;
        emailController.text = profile.value.email;
        phoneNumberController.text = profile.value.phoneNumber;
      }
    }
  }

  void updateProfileImage() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Get.back();
                pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Get.back();
                pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _storage.write('profileImage', pickedFile.path);
        profile.update((val) {
          val?.profileImage = pickedFile.path;
        });
      } else {
        Get.snackbar("Info", "No image captured",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to capture image",
          snackPosition: SnackPosition.BOTTOM);
      print('Error picking image: $e');
    }
  }

  void pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _storage.write('profileImage', pickedFile.path);
        profile.update((val) {
          val?.profileImage = pickedFile.path;
        });
      } else {
        Get.snackbar("Info", "No image selected",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image",
          snackPosition: SnackPosition.BOTTOM);
      print('Error picking image: $e');
    }
  }

  void recordVideo() async {
    try {
      final pickedVideo = await _picker.pickVideo(source: ImageSource.camera);
      if (pickedVideo != null) {
        // Save video path to GetStorage
        _storage.write('profileVideo', pickedVideo.path);

        // Update video path and initialize VideoPlayerController
        videoPath.value = pickedVideo.path;
        videoPlayerController = VideoPlayerController.file(File(pickedVideo.path))
          ..initialize().then((_) {
            videoPlayerController!.play(); // Auto-play video
            update(); // Update UI
          });
      } else {
        Get.snackbar("Info", "No video recorded",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to record video",
          snackPosition: SnackPosition.BOTTOM);
      print('Error recording video: $e');
    }
  }

  void updateUserName(String name) {
    profile.update((val) {
      val!.userName = name;
    });
  }

  void updateEmail(String email) {
    profile.update((val) {
      val!.email = email;
    });
  }

  void updatePhoneNumber(String phone) {
    profile.update((val) {
      val!.phoneNumber = phone;
    });
  }

  Future<void> saveUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'userName': profile.value.userName,
        'email': profile.value.email,
        'phoneNumber': profile.value.phoneNumber,
        'profileImage': profile.value.profileImage,
      });
    }
  }

  Future<void> deleteUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDocRef = _firestore.collection('users').doc(userId);
        await userDocRef.delete();

        _storage.remove('profileImage');
        _storage.remove('profileVideo');
      } else {
        Get.snackbar("Error", "No user found to delete data",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to delete user data",
          snackPosition: SnackPosition.BOTTOM);
      print("Error deleting user data: $e");
    }
  }
}