import 'package:admin/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SigninController extends GetxController {
  // Text Controllers
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable variables
  var isPasswordVisible = false.obs;
  var isLoading = false.obs; // Added loading state
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupValidationListeners();
  }

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    emailOrPhoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Setup validation listeners for real-time feedback
  void _setupValidationListeners() {
    // Listen to changes to clear error message when user starts typing
    emailOrPhoneController.addListener(() {
      if (hasError.value) {
        _clearError();
      }
    });

    passwordController.addListener(() {
      if (hasError.value) {
        _clearError();
      }
    });
  }

  /// Clear error state
  void _clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }

  /// Set error state
  void _setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    // A more robust email regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone format (for India, 10 digits)
  /// Adjust regex based on your target region's phone number format
  bool _isValidPhone(String phone) {
    // This regex checks for a 10-digit number.
    // If you need to support country codes, leading zeros, or other formats,
    // adjust this regex accordingly.
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Firebase sign in method
  /// Returns null on success, or an error message string on failure.
  Future<String?> signIn(String input, String password) async {
    try {
      String? email;
      String? uid;
      // ignore: unused_local_variable
      String collectionName =
          ''; // To track which collection the user belongs to

      if (_isValidEmail(input)) {
        email = input;
      } else if (_isValidPhone(input)) {
        // Search across all relevant collections for the phone number
        final List<String> collections = ['admins', 'Sales', 'Makers'];
        DocumentSnapshot? userDoc;

        for (final collection in collections) {
          QuerySnapshot query = await FirebaseFirestore.instance
              .collection(collection)
              .where('phone', isEqualTo: input)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            userDoc = query.docs.first;
            collectionName = collection; // Store the collection name
            break; // Found the user in this collection, no need to check others
          }
        }

        if (userDoc != null) {
          email = userDoc.get('email');
          uid = userDoc.id; // Use doc.id for UID
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      // Proceed with Firebase Auth sign-in using the retrieved email
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password);

      // Ensure UID is set for role verification
      uid ??= userCredential.user!.uid;

      // Now, verify the role based on the UID.
      // Assuming 'admins' collection is where your primary users for this app are,
      // and 'Sales', 'Makers' are other roles that might also sign in.
      // You can refine this role check based on your specific access control logic.
      DocumentSnapshot userRoleDoc = await FirebaseFirestore.instance
          .collection('admins') // Only checking admins collection for access
          .doc(uid)
          .get();

      if (userRoleDoc.exists && userRoleDoc.get('role') == 'admin') {
        return null; // Success, user is an admin
      } else {
        // If not found in 'admins' or not an 'admin' role, sign out and deny access
        await FirebaseAuth.instance.signOut();
        return 'Access denied. You are not authorized to use this admin panel.';
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Please check your Email and Password and try again.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// Handle sign in process with loading state
  Future<void> handleSignIn() async {
    try {
      isLoading.value = true;
      _clearError(); // Clear previous errors

      HapticFeedback.lightImpact(); // Haptic feedback on button press

      final input = emailOrPhoneController.text.trim();
      final password = passwordController.text.trim();

      // Basic input validation
      if (input.isEmpty || password.isEmpty) {
        _setError('Please fill in both fields.');
        _handleSignInError(
          'Please fill in both fields.',
        ); // Use consistent error handler
        return;
      }

      if (!_isValidEmail(input) && !_isValidPhone(input)) {
        _setError('Please enter a valid email or 10-digit phone number.');
        _handleSignInError(
          'Please enter a valid email or 10-digit phone number.',
        ); // Use consistent error handler
        return;
      }

      if (password.length < 6) {
        _setError('Password must be at least 6 characters long.');
        _handleSignInError(
          'Password must be at least 6 characters long.',
        ); // Use consistent error handler
        return;
      }

      // Attempt sign in
      final result = await signIn(input, password);

      if (result == null) {
        // Success
        _handleSignInSuccess();
      } else {
        // Error
        _setError(result);
        _handleSignInError(result);
      }
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      _handleSignInError('An unexpected error occurred: $e');
    } finally {
      isLoading.value = false; // Always stop loading
    }
  }

  /// Handle successful sign in
  void _handleSignInSuccess() {
    Get.offAll(() => Dashboard()); // Navigate to Dashboard

    Get.snackbar(
      "Welcome Back!",
      "Signed in successfully",
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade700,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );

    HapticFeedback.lightImpact(); // Success haptic feedback
  }

  /// Handle sign in errors
  void _handleSignInError(String error) {
    _showErrorSnackbar("Login Failed", error);

    HapticFeedback.heavyImpact(); // Error haptic feedback
  }

  /// Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade700,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10), // Added margin for better appearance
    );
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Handle forgot password
  Future<void> handleForgotPassword() async {
    final input = emailOrPhoneController.text.trim();

    if (input.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address to reset password.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade700,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    // Only allow email for password reset
    if (!_isValidEmail(input)) {
      Get.snackbar(
        'Error',
        'Password reset is only available for email addresses. Please enter a valid email.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade700,
        margin: const EdgeInsets.all(10),
      );
      return;
    }

    try {
      isLoading.value = true;
      _clearError(); // Clear any previous errors

      await FirebaseAuth.instance.sendPasswordResetEmail(email: input);

      Get.snackbar(
        'Password Reset',
        'A password reset link has been sent to $input. Please check your inbox.',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade700,
        icon: const Icon(Icons.email, color: Colors.blue),
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send password reset email.';
      if (e.code == 'user-not-found') {
        message = 'No user found with that email address.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many password reset requests. Please try again later.';
      }
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade700,
        margin: const EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear all form data
  void clearForm() {
    emailOrPhoneController.clear();
    passwordController.clear();
    _clearError();
    isPasswordVisible.value = false;
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      clearForm();
      // Optionally navigate back to sign-in page after sign out
      // Get.offAll(() => Signin()); // Assuming Signin is your root for unauthenticated users
    } catch (e) {
      print('Sign out error: $e'); // Log error for debugging
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade700,
        margin: const EdgeInsets.all(10),
      );
    }
  }
}
