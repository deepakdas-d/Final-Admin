import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddUserController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final placeController = TextEditingController();

  // Focus nodes
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final ageFocus = FocusNode();
  final phoneFocus = FocusNode();
  final placeFocus = FocusNode();
  final addressFocus = FocusNode();

  // Reactive variables
  var selectedRole = 'SALESMEN'.obs;
  var selectedGender = RxString('');
  var selectedImage = Rx<File?>(null);
  var isLoading = false.obs;
  var passwordVisible = false.obs;

  final ImagePicker picker = ImagePicker();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  var currentLocation = ''.obs;

  @override
  void onClose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    placeController.dispose();

    // Dispose focus nodes
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    ageFocus.dispose();
    phoneFocus.dispose();
    placeFocus.dispose();
    addressFocus.dispose();

    // Clear image file reference
    selectedImage.value = null;

    super.onClose();
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation (adjust pattern as needed)
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,15}$').hasMatch(phone);
  }

  // Password validation
  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
  }

  // Validate form with custom rules
  bool _validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showErrorDialog('Please enter a valid email address');
      return false;
    }

    if (!_isValidPhone(phoneController.text.trim())) {
      _showErrorDialog('Please enter a valid phone number');
      return false;
    }

    if (!_isValidPassword(passwordController.text.trim())) {
      _showErrorDialog(
        'Password must be at least 8 characters with uppercase, lowercase, and number',
      );
      return false;
    }

    if (selectedGender.value.isEmpty) {
      _showErrorDialog('Please select a gender');
      return false;
    }

    return true;
  }

  Future<void> _getAddressFromUserId(String userId) async {
    try {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Get latitude and longitude from user document
        double? latitude = userData['latitude']?.toDouble();
        double? longitude = userData['longitude']?.toDouble();

        if (latitude != null && longitude != null) {
          print("Found user coordinates: $latitude, $longitude");
          // Get address from coordinates
          await _getAddressFromLatLng(latitude, longitude);

          // Optional: Also show the stored address for comparison
          String storedAddress = userData['address'] ?? 'No stored address';
          String place = userData['place'] ?? '';
          print("Stored address: $storedAddress");
          print("Stored place: $place");
        } else {
          print("User coordinates not found in database");
          // Fallback to stored address if coordinates are missing
          String fallbackAddress =
              userData['address'] ?? 'Location not available';
          currentLocation.value = fallbackAddress;
        }
      } else {
        print("User document not found");
        currentLocation.value = "User not found";
      }
    } catch (e) {
      print("Error fetching user location: $e");
      currentLocation.value = "Error fetching location";
    }
  }

  // Keep the existing _getAddressFromLatLng method as is
  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentLocation.value =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }
    } catch (e) {
      print("Error getting address: $e");
      currentLocation.value =
          "Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}";
    }
  }

  

  // Alternative method if you want to fetch multiple users' locations
  Future<void> _getAddressFromUserPhone(String phoneNumber) async {
    try {
      // Query user by phone number
      QuerySnapshot userQuery = await firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber.trim())
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            userQuery.docs.first.data() as Map<String, dynamic>;

        double? latitude = userData['latitude']?.toDouble();
        double? longitude = userData['longitude']?.toDouble();

        if (latitude != null && longitude != null) {
          print(
            "Found coordinates for phone $phoneNumber: $latitude, $longitude",
          );
          await _getAddressFromLatLng(latitude, longitude);

          // Also get user info for reference
          String userName = userData['name'] ?? 'Unknown';
          String userPlace = userData['place'] ?? '';
          print("User: $userName from $userPlace");
        } else {
          print("User coordinates not found in database");
          // Fallback to stored address
          String fallbackAddress =
              userData['address'] ?? 'Location not available for this user';
          currentLocation.value = fallbackAddress;
        }
      } else {
        print("User not found with phone: $phoneNumber");
        currentLocation.value = "User not found";
      }
    } catch (e) {
      print("Error fetching user location by phone: $e");
      currentLocation.value = "Error fetching location";
    }
  }

  // Method to get all user data including location
  Future<Map<String, dynamic>?> getUserLocationData(String userId) async {
    try {
      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Get reverse geocoded address if coordinates exist
        double? latitude = userData['latitude']?.toDouble();
        double? longitude = userData['longitude']?.toDouble();

        String reverseGeocodedAddress = '';
        if (latitude != null && longitude != null) {
          await _getAddressFromLatLng(latitude, longitude);
          reverseGeocodedAddress = currentLocation.value;
        }

        return {
          'uid': userData['uid'],
          'name': userData['name'],
          'email': userData['email'],
          'phone': userData['phone'],
          'address': userData['address'], // Stored address
          'place': userData['place'],
          'latitude': latitude,
          'longitude': longitude,
          'reverseGeocodedAddress':
              reverseGeocodedAddress, // Generated from coordinates
          'lastLocationUpdate': userData['lastLocationUpdate'],
          'role': userData['role'],
          'isActive': userData['isActive'],
        };
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }



  // Method to get all users with their location data (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllUsersWithLocation() async {
    try {
      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('lastLocationUpdate', descending: true)
          .get();

      List<Map<String, dynamic>> usersList = [];

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        double? latitude = userData['latitude']?.toDouble();
        double? longitude = userData['longitude']?.toDouble();

        usersList.add({
          'uid': userData['uid'],
          'name': userData['name'],
          'email': userData['email'],
          'phone': userData['phone'],
          'address': userData['address'],
          'place': userData['place'],
          'latitude': latitude,
          'longitude': longitude,
          'lastLocationUpdate': userData['lastLocationUpdate'],
          'role': userData['role'],
          'isActive': userData['isActive'],
          'hasLocation': latitude != null && longitude != null,
        });
      }

      return usersList;
    } catch (e) {
      print("Error fetching users with location: $e");
      return [];
    }
  }

  Future<void> pickImage() async {
    try {
      print('Opening image picker');
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected: ${image.path}');
        selectedImage.value = File(image.path);
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (selectedImage.value == null) return null;

    try {
      final ref = storage.ref().child('salesperson_images/$userId.jpg');
      final uploadTask = ref.putFile(selectedImage.value!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Check for duplicate phone using transaction for better consistency
  Future<bool> _isPhoneDuplicate(String phone) async {
    try {
      final result = await firestore.runTransaction((transaction) async {
        final phoneQuery = await firestore
            .collection('users')
            .where('phone', isEqualTo: phone.trim())
            .limit(1)
            .get();
        return phoneQuery.docs.isNotEmpty;
      });
      return result;
    } catch (e) {
      print('Error checking phone duplicate: $e');
      return false; // Assume no duplicate on error to allow continuation
    }
  }

  Future<void> createUser() async {
    if (isLoading.value) return; // Prevent multiple calls

    if (!_validateForm()) {
      return;
    }

    // Handle missing image
    if (selectedImage.value == null) {
      final bool proceed = await _showImageConfirmationDialog();
      if (!proceed) return;
    }

    isLoading.value = true;

    try {
      // Check for duplicate phone
      final phoneExists = await _isPhoneDuplicate(phoneController.text.trim());
      if (phoneExists) {
        _showErrorDialog('Phone number is already in use');
        return;
      }

      // TODO: Replace with server-side user creation
      // This should be done via Cloud Functions or your backend API
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final User? user = userCredential.user;
      if (user != null) {
        String? imageUrl;

        // Upload image if selected
        if (selectedImage.value != null) {
          try {
            imageUrl = await _uploadImage(user.uid);
          } catch (e) {
            print('Image upload failed: $e');
            // Continue without image instead of failing completely
            _showErrorDialog('User created but image upload failed');
          }
        }

        // Save user data to Firestore
        await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'place': placeController.text.trim(),
          'gender': selectedGender.value,
          'role': selectedRole.value.toLowerCase(),
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': auth.currentUser?.uid,
          'isActive': true,
          'latitude': null,
          'longitude': null,
          'lastLocationUpdate': null,
        });

        // Update display name
        await user.updateDisplayName(nameController.text.trim());

        _showSuccessDialog('User created successfully!');
        clearForm(); // Clear form after success
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      print('Error creating user: $e');
      _showErrorDialog('Error creating user: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with mix of letters and numbers';
      case 'invalid-email':
        return 'Invalid email address format';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: $errorCode';
    }
  }

  Future<bool> _showImageConfirmationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('No Image Selected'),
            content: const Text(
              'No profile image is selected. Do you want to proceed without an image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Success', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Pop back to previous screen
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[50],
              foregroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('Oops!', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    ageController.clear();
    phoneController.clear();
    addressController.clear();
    passwordController.clear();
    placeController.clear();
    selectedImage.value = null;
    selectedRole.value = 'SALESMEN';
    selectedGender.value = '';
    passwordVisible.value = false;
  }

  void showUserLocation(String userId) async {
    await _getAddressFromUserId(userId);
    // currentLocation.value now contains the reverse geocoded address
    print("User location: ${currentLocation.value}");
  }

  // 2. Search user by phone and show location
  void searchAndShowLocation(String phoneNumber) async {
    await _getAddressFromUserPhone(phoneNumber);
    print("Search result location: ${currentLocation.value}");
  }
}
