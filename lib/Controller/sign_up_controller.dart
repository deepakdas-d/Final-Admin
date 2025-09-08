// import 'package:admin/home.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class SignupController extends GetxController {
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   var isPasswordVisible = false.obs;
//   var isConfirmPasswordVisible = false.obs;
//   var isLoading = false.obs; // Added isLoading observable

//   final firebaseAuth = FirebaseAuth.instance;
//   final firestore = FirebaseFirestore.instance;

//   Future<void> signUp() async {
//     isLoading.value = true; // Set loading to true
//     try {
//       final email = emailController.text.trim();
//       final phone = phoneController.text.trim();
//       final password = passwordController.text;
//       final confirmPassword = confirmPasswordController.text;

//       if (email.isEmpty ||
//           phone.isEmpty ||
//           password.isEmpty ||
//           confirmPassword.isEmpty) {
//         Get.snackbar('Error', 'Please fill all fields');
//         return;
//       }

//       if (password != confirmPassword) {
//         Get.snackbar('Error', 'Passwords do not match');
//         return;
//       }

//       // Check if phone or email is registered anywhere before attempting Firebase creation
//       if (await isPhoneRegisteredAnywhere(phone)) {
//         Get.snackbar('Error', 'Phone number is already registered.');
//         return;
//       }

//       if (await isEmailRegisteredAnywhere(email)) {
//         Get.snackbar('Error', 'Email is already registered.');
//         return;
//       }

//       final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       final user = userCredential.user;
//       if (user != null) {
//         await firestore.collection('admins').doc(user.uid).set({
//           'email': email,
//           'phone': phone,
//           'uid': user.uid,
//           'role': 'admin',
//           'createdAt': Timestamp.now(),
//         });

//         Get.snackbar('Success', 'Admin signup successful!');
//         Get.offAll(() => Dashboard());
//       } else {
//         Get.snackbar('Error', 'User creation failed. Please try again.');
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = 'Signup failed';
//       if (e.code == 'email-already-in-use') {
//         message = 'Email is already in use by another account.';
//       } else if (e.code == 'weak-password') {
//         message = 'The password provided is too weak.';
//       } else if (e.code == 'invalid-email') {
//         message = 'The email address is not valid.';
//       } else {
//         message = e.message ?? 'An unknown Firebase authentication error occurred.';
//       }
//       Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(10));
//     } catch (e) {
//       Get.snackbar('Error', 'An unexpected error occurred: $e', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(10));
//     } finally {
//       isLoading.value = false; // Set loading to false regardless of success or failure
//     }
//   }

//   /// Checks if a phone number is registered in 'admins', 'Sales', or 'Makers' collections.
//   Future<bool> isPhoneRegisteredAnywhere(String phone) async {
//     final collections = ['admins', 'Sales', 'Makers'];
//     for (final collection in collections) {
//       final query = await firestore
//           .collection(collection)
//           .where('phone', isEqualTo: phone)
//           .limit(1)
//           .get();
//       if (query.docs.isNotEmpty) return true;
//     }
//     return false;
//   }

//   /// Checks if an email address is registered in 'admins', 'Sales', or 'Makers' collections.
//   Future<bool> isEmailRegisteredAnywhere(String email) async {
//     final collections = ['admins', 'Sales', 'Makers'];
//     for (final collection in collections) {
//       final query = await firestore
//           .collection(collection)
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();
//       if (query.docs.isNotEmpty) return true;
//     }
//     return false;
//   }

//   void togglePasswordVisibility() =>
//       isPasswordVisible.value = !isPasswordVisible.value;

//   void toggleConfirmPasswordVisibility() =>
//       isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

//   @override
//   void onClose() {
//     emailController.dispose();
//     phoneController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.onClose();
//   }
// }


import 'package:admin/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var isLoading = false.obs;

  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // GlobalKey to validate the form from the UI
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  Future<void> signUp() async {
    // Validate all form fields using the form key
    if (!signupFormKey.currentState!.validate()) {
      return; // Stop if any validation fails
    }

    isLoading.value = true;
    try {
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final password = passwordController.text;
      final confirmPassword = confirmPasswordController.text;

      // Basic null/empty checks (though TextFormField validators handle most of this)
      if (email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        Get.snackbar('Error', 'Please fill all fields.');
        return;
      }

      if (password != confirmPassword) {
        Get.snackbar('Error', 'Passwords do not match.');
        return;
      }

      // Check if phone number is already registered in your collections
      if (await isPhoneRegisteredAnywhere(phone)) {
        Get.snackbar('Error', 'This phone number is already registered.', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(10));
        return;
      }

      // Attempt to create user with email and password
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Store user data in Firestore
        await firestore.collection('admins').doc(user.uid).set({
          'email': email,
          'phone': phone,
          'uid': user.uid,
          'role': 'admin',
          'createdAt': Timestamp.now(),
        });

        Get.snackbar('Success', 'Admin signup successful!');
        Get.offAll(() => Dashboard());
      } else {
        Get.snackbar('Error', 'User creation failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email address is already in use by another account.';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak. Please use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid. Please check the format.';
      } else {
        message = e.message ?? 'An unknown Firebase authentication error occurred.';
      }
      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(10));
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(10));
    } finally {
      isLoading.value = false;
    }
  }

  /// Checks if a phone number is registered in 'admins', 'Sales', or 'Makers' collections.
  Future<bool> isPhoneRegisteredAnywhere(String phone) async {
    final collections = ['admins', 'Sales', 'Makers'];
    for (final collection in collections) {
      final query = await firestore
          .collection(collection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return true;
    }
    return false;
  }

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}