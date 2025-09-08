
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComplaintDetailController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables for state management
  final RxString selectedStatus = 'pending'.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController responseController = TextEditingController();

  // Storing complaint data passed to the page
  late Map<String, dynamic> complaintData;
  
  // Flag to track if status has been initialized
  bool _statusInitialized = false;

  // Initialize controller with complaint data
  void initializeData(Map<String, dynamic> data) {
    complaintData = data;
    
    // Only set the initial status once when the controller is first initialized
    // This prevents resetting the user's selection when they interact with other fields
    if (!_statusInitialized) {
      selectedStatus.value = complaintData['status'] ?? 'pending';
      _statusInitialized = true;
    }
  }

  // Function to submit response to Firestore
  Future<void> submitResponse() async {
    if (responseController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a response message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final batch = firestore.batch();
      final String? currentUserId = _auth.currentUser?.uid;

      if (currentUserId == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // Fetch the complaint document to get the userId
      final complaintDoc = await firestore
          .collection('complaints')
          .doc(complaintData['docId'])
          .get();

      final String complaintUserId = complaintDoc['userId'];

      // Use a consistent document ID based on complaintId + userId (or just complaintId)
      final String docId = '${complaintData['complaintId']}_$currentUserId';
      final responseRef = firestore
          .collection('complaint_responses')
          .doc(docId);

      batch.set(responseRef, {
        'complaintId': complaintData['complaintId'],
        'response': responseController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'respondedBy': currentUserId,
        'userId': complaintUserId,
        'statusChanged': true,
        'newStatus': selectedStatus.value,
        'complaint': complaintData['complaint'],
      }, SetOptions(merge: true));

      // Update the main complaint doc
      if (complaintData['docId'] != null) {
        final complaintRef = firestore
            .collection('complaints')
            .doc(complaintData['docId']);
        batch.update(complaintRef, {
          'status': selectedStatus.value,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      Get.snackbar(
        'Success',
        'Response updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      responseController.clear();
      // Update the local complaint data to reflect the new status
      complaintData['status'] = selectedStatus.value;
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error updating response: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Method to manually refresh data if needed
  void refreshData() {
    // This method can be called to refresh without resetting user selections
    update();
  }

  // Clean up controller resources
  @override
  void onClose() {
    responseController.dispose();
    super.onClose();
  }
}