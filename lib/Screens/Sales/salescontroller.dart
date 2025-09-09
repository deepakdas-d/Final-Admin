import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SalesManagementController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  final ValueNotifier<String> selectedFilter = ValueNotifier('all');
  final ValueNotifier<bool> isLoadingMore = ValueNotifier(false);
  final ValueNotifier<DocumentSnapshot?> lastDocument = ValueNotifier(null);
  final ValueNotifier<List<Map<String, dynamic>>> users = ValueNotifier([]);
  final int batchSize = 20;
  Timer? _debounce;
  bool _initialized = false; // 🔒 prevent double init

  void onInit() {
    if (_initialized) return; // ✅ only run once
    _initialized = true;

    scrollController.addListener(_scrollListener);

    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        searchQuery.value = searchController.text.toLowerCase();
        resetAndFetchUsers();
      });
    });

    resetAndFetchUsers(); // 🚀 fetch users on load
  }

  SalesManagementController() {
    scrollController.addListener(_scrollListener);
    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        searchQuery.value = searchController.text.toLowerCase();
        resetAndFetchUsers();
      });
    });
    resetAndFetchUsers();
  }

  void dispose() {
    _debounce?.cancel();
    scrollController.dispose();
    searchController.dispose();
    searchQuery.dispose();
    selectedFilter.dispose();
    isLoadingMore.dispose();
    lastDocument.dispose();
    users.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.extentAfter < 300 && !isLoadingMore.value) {
      fetchUsers();
    }
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    resetAndFetchUsers();
  }

  Future<void> resetAndFetchUsers() async {
    lastDocument.value = null;
    users.value = [];
    await fetchUsers();
  }

  Future<void> fetchUsers() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'salesmen')
          .orderBy('createdAt', descending: true)
          .limit(batchSize);

      if (lastDocument.value != null) {
        query = query.startAfterDocument(lastDocument.value!);
      }

      if (selectedFilter.value != 'all') {
        query = query.where(
          'isActive',
          isEqualTo: selectedFilter.value == 'active',
        );
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        isLoadingMore.value = false;
        return;
      }

      lastDocument.value = snapshot.docs.last;

      final newUsers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((user) {
            final name = (user['name'] ?? '').toString().toLowerCase();
            final email = (user['email'] ?? '').toString().toLowerCase();
            final phone = (user['phone'] ?? '').toString().toLowerCase();
            final place = (user['place'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.value) ||
                email.contains(searchQuery.value) ||
                phone.contains(searchQuery.value) ||
                place.contains(searchQuery.value);
          })
          .toList();

      // Deduplicate by user ID
      final existingIds = users.value
          .map((user) => user['id'] as String)
          .toSet();
      final uniqueNewUsers = newUsers
          .where((user) => !existingIds.contains(user['id']))
          .toList();

      users.value = [...users.value, ...uniqueNewUsers];
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> resetAllSalespersonsCounts(BuildContext context) async {
    // 🔹 Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
            'Are you sure you want to reset all salesperson counts?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    // 🔹 Proceed only if user confirms
    if (confirm != true) {
      debugPrint("❌ Reset cancelled by user");
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // 🔹 Get only users with role 'salesmen'
      final usersSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'salesmen')
          .get();

      // 🔹 Use batch for efficiency
      WriteBatch batch = firestore.batch();

      for (var doc in usersSnapshot.docs) {
        batch.update(doc.reference, {
          'totalLeads': 0,
          'totalOrders': 0,
          'totalPostSaleFollowUp': 0,
        });
      }

      // 🔹 Commit all updates in one go
      await batch.commit();

      debugPrint("✅ All salesperson counts reset to zero.");
      Get.snackbar(
        "Success",
        "All salesperson counts reset.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint("❌ Error resetting counts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error resetting counts: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
