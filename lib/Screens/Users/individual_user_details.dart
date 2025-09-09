// ignore_for_file: unnecessary_null_comparison

import 'dart:developer';

import 'package:admin/Controller/usercontroller.dart';
import 'package:admin/Crop/helperclass.dart' as AppHelper;
import 'package:admin/Voice/admin_audio_listener.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class IndividualUserDetails extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const IndividualUserDetails({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<IndividualUserDetails> createState() => _IndividualUserDetailsState();
}

class _IndividualUserDetailsState extends State<IndividualUserDetails> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.put(AddUserController());
  final picker = ImagePicker();

  bool isLoading = true;
  int totalOrders = 0;
  int pending = 0;
  int outForDelivery = 0;
  int inProgress = 0;
  int accepted = 0;

  // Define the custom icon color
  static const Color _iconColor = Color.fromARGB(255, 209, 52, 67);
  static const Color _textColor = Color(0xFF1A1A1A);

  // Controllers
  late final _nameController = TextEditingController(
    text: widget.userData['name'],
  );
  late final _emailController = TextEditingController(
    text: widget.userData['email'],
  );
  late final _ageController = TextEditingController(
    text: widget.userData['age']?.toString() ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.userData['phone'],
  );
  late final _addressController = TextEditingController(
    text: widget.userData['address'],
  );
  late final _passwordController = TextEditingController();
  late final _placeController = TextEditingController(
    text: widget.userData['place'] ?? '',
  );

  // State variables
  bool _isActive = true;
  String? _imageUrl;
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _selectedGender;
  String? _selectedRole;
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchLocationData();
    fetchUserCounts();
  }

  void _initializeData() {
    _selectedGender = widget.userData['gender'];
    _isActive = widget.userData['isActive'] ?? true;
    _imageUrl = widget.userData['imageUrl'];
    _selectedRole = widget.userData['role'] ?? 'salesmen';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final lat = _locationData!['latitude'] ?? "N/A";
    final lng = _locationData!['longitude'] ?? "N/A";
    log("Opening map for coordinates: $lat, $lng");
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(url);
  }

  Future<void> _fetchLocationData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final locationData = await _controller.getUserLocationData(widget.userId);
      if (mounted) setState(() => _locationData = locationData);
    } catch (e) {
      _showError('Error fetching location: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    await _pickImageWithCropCompress(ImageSource.gallery, true);
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;
    try {
      final ref = _storage.ref().child(
        'salesperson_images/${widget.userId}.jpg',
      );
      final snapshot = await ref.putFile(_selectedImage!);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showError('Error uploading image: $e');
      return _imageUrl;
    }
  }

  // Validation methods
  String? _validate(String? value, String field, {int? minLength}) {
    if (field == 'Password') {
      if (value?.isEmpty ?? true) return null; // Password is optional
      if (value!.trim().length < 6) {
        return 'Password must be at least 6 characters';
      }
    } else {
      if (value?.trim().isEmpty ?? true) return '$field is required';
      if (minLength != null && value!.trim().length < minLength) {
        return '$field must be at least $minLength characters';
      }
      if (field == 'Email' &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
        return 'Enter valid email';
      }
      if (field == 'Age') {
        final age = int.tryParse(value!);
        if (age == null || age < 18 || age > 65) return 'Age must be 18-65';
      }
      if (field == 'Phone' && value!.length < 10) {
        return 'Enter valid phone number';
      }
    }
    return null;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Check if phone number is already in use
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .get();

      if (phoneQuery.docs.isNotEmpty &&
          phoneQuery.docs.first.id != widget.userId) {
        _showError('Phone number is already in use');
        return;
      }

      // 2. Upload new image
      final newImageUrl = await _uploadImage();

      // 3. Update Firestore user data
      await _firestore.collection('users').doc(widget.userId).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'place': _placeController.text.trim(),
        'gender': _selectedGender,
        'role': _selectedRole,
        'isActive': _isActive,
        'imageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. If password is changed, update it
      if (_passwordController.text.trim().isNotEmpty) {
        try {
          await _auth.currentUser?.updatePassword(
            _passwordController.text.trim(),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            _showError('Please log in again to change your password.');
          } else {
            _showError('Failed to update password. Please log in again.');
          }
          return;
        } catch (_) {
          _showError(
            'An unexpected error occurred while updating the password.',
          );
          return;
        }
      }

      // 5. Optional: fetch location data
      try {
        await _fetchLocationData();
      } catch (_) {
        _showError('User updated, but failed to fetch location.');
      }

      // 6. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('User updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        setState(() {
          _isEditing = false;
          _imageUrl = newImageUrl;
          _selectedImage = null;
        });
      }
    } catch (_) {
      _showError(
        'Something went wrong while updating the user. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: _iconColor), // Use custom color
            SizedBox(width: 12),
            Text(
              'Oops!',
              style: TextStyle(color: _iconColor),
            ), // Use custom color
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: _iconColor),
            ), // Use custom color
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageWithCropCompress(
    ImageSource source,
    bool isUserImage,
  ) async {
    try {
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800, // Adjusted for better quality
        maxHeight: 800,
        imageQuality: 85, // Balanced quality and size
      );

      if (pickedImage != null) {
        final String path = pickedImage.path;
        final String extension = path.split('.').last.toLowerCase();

        // --- ADDED VALIDATION CONDITION HERE ---
        if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
          _showSnackBar(
            'Only JPG and PNG images are supported.',
            isError: true,
          );
          return; // Stop processing if the file type is not supported
        }
        // --- END OF ADDED VALIDATION ---

        File image = File(pickedImage.path);

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // Compress the image
          File? compressedImage = await AppHelper.compress(image: image);
          if (compressedImage == null) {
            // Ensure Navigator.pop is called to dismiss the dialog
            Navigator.pop(context);
            _showSnackBar('Failed to compress image', isError: true);
            return;
          }

          // Crop the image
          File? croppedImage = await AppHelper.cropImage(compressedImage);
          // Ensure Navigator.pop is called to dismiss the dialog after cropping attempt
          // (even if cropping is cancelled)
          Navigator.pop(context);

          if (croppedImage == null) {
            _showSnackBar('Image cropping cancelled', isError: true);
            return;
          }

          // Update state with processed image
          setState(() {
            _selectedImage = croppedImage;
          });

          // Log sizes for debugging
          final sizeInKbBefore = image.lengthSync() / 1024;
          final sizeInKbAfter = croppedImage.lengthSync() / 1024;
          print('Before Processing: ${sizeInKbBefore.toStringAsFixed(2)} KB');
          print('After Processing: ${sizeInKbAfter.toStringAsFixed(2)} KB');
        } catch (e) {
          // Ensure Navigator.pop is called to dismiss the dialog in case of error
          if (Navigator.of(context).canPop()) {
            // Check if dialog is still open
            Navigator.pop(context);
          }
          _showSnackBar('Error processing image: $e', isError: true);
        }
      } else {
        _showSnackBar('No image selected', isError: true);
      }
    } catch (e) {
      // This catch block handles errors during the image picking itself
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit User' : 'User Details',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _textColor,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            _textColor, // Use custom text color for general foreground
        elevation: 1,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: _iconColor,
              ), // Use custom color
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _isEditing ? _buildSaveButton() : null,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildProfileSection(),
            const SizedBox(height: 24),
            _buildInfoCard('Personal Information', Icons.person, [
              _buildTextField(
                _nameController,
                'Name',
                Icons.person_outline,
                validator: (v) => _validate(v, 'Name', minLength: 2),
              ),
              _buildTextField(
                _ageController,
                'Age',
                Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => _validate(v, 'Age'),
              ),
              _buildDropdown('Gender', _selectedGender, [
                'Male',
                'Female',
                'Other',
              ], (v) => setState(() => _selectedGender = v)),
              _buildDropdown('Role', _selectedRole, [
                'salesmen',
                'maker',
              ], (v) => setState(() => _selectedRole = v)),
              _buildTextField(
                _placeController,
                'Place',
                Icons.place_outlined,
                validator: (v) => _validate(v, 'Place', minLength: 2),
              ),
              _buildTextField(
                _addressController,
                'Address',
                Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => _validate(v, 'Address'),
              ),
            ]),
            const SizedBox(height: 24),
            _buildInfoCard('Contact Information', Icons.contact_mail, [
              _buildTextField(
                Readonly: true,
                _emailController,
                'Email',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _validate(v, 'Email'),
              ),
              _buildTextField(
                _phoneController,
                'Phone',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => _validate(v, 'Phone'),
              ),
            ]),
            const SizedBox(height: 24),
            if (widget.userData['role'] != 'maker') ...[
              const SizedBox(height: 24),
              _buildCountCardofSales(),
            ],
            if (widget.userData['role'] != 'salesperson') ...[
              const SizedBox(height: 24),
              _buildCountCardOfMaker(),
            ],

            if (widget.userData['role'] != 'maker') ...[
              const SizedBox(height: 24),
              _buildLocationCard(),
            ],

            const SizedBox(height: 24),
            _buildStatusCard(),

            if (widget.userData['role'] != 'maker') ...[
              const SizedBox(height: 32),
              _buildMonitorButton(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    const double avatarRadius = 50.0;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[200],
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : _imageUrl != null
                    ? NetworkImage(_imageUrl!)
                    : null,
                child: _selectedImage == null && _imageUrl == null
                    ? const Icon(
                        Icons.person,
                        size: avatarRadius * 0.8,
                        color: Colors.grey,
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: _iconColor, // Use custom color
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'No Name',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _isActive ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white, // Explicitly set card color to white
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _iconColor), // Use custom color
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool Readonly = false,
  }) {
    return TextFormField(
      readOnly: Readonly,
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _iconColor), // Use custom color
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _isEditing ? Colors.grey[50] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _iconColor,
            width: 2,
          ), // Use custom color for focused border
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: _isEditing ? onChanged : null,
      validator: (v) => v == null ? 'Please select $label' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == 'Gender' ? Icons.person_outline : Icons.work_outline,
          color: _iconColor, // Use custom color
        ),
        filled: true,
        fillColor: _isEditing ? Colors.grey[50] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _iconColor,
            width: 2,
          ), // Use custom color for focused border
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final timestamp = _locationData?['lastLocationUpdate'];
    String formattedDate = 'Not available';

    if (timestamp is Timestamp) {
      formattedDate = DateFormat(
        "MMM d, y 'at' h:mm a",
      ).format(timestamp.toDate());
    }

    return InkWell(
      onTap: _openMap,
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.transparent, // Make card itself transparent
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: const DecorationImage(
              image: AssetImage(
                'assets/images/map.jpeg',
              ), // your background image
              fit: BoxFit.cover, // cover, contain, or fill
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: Colors.black, // Icon color for contrast
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Location Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Text color for contrast
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5, color: Colors.black),
                _buildInfoRow(
                  'Address',
                  _locationData?['reverseGeocodedAddress'] ?? 'Not available',
                ),
                _buildInfoRow(
                  'Coordinates',
                  _locationData != null &&
                          _locationData!['latitude'] != null &&
                          _locationData!['longitude'] != null
                      ? 'Lat: ${_locationData!['latitude'].toStringAsFixed(4)}, Lng: ${_locationData!['longitude'].toStringAsFixed(4)}'
                      : 'Not available',
                ),
                _buildInfoRow('Last Update', formattedDate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white, // Explicitly set card color to white
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: _iconColor,
                ), // Use custom color
                SizedBox(width: 10),
                Text(
                  'Account Status',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(
                  _isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _isActive ? Colors.green[600] : Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Account Status')),
                if (_isEditing)
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: Colors.green,
                  )
                else
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchUserCounts() async {
    try {
      setState(() => isLoading = true);

      // 🔹 Step 1: Fetch from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        totalOrders = data['totalOrders'] ?? 0;
      }

      // 🔹 Step 2: Fetch from Orders collection
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('cancel', isEqualTo: false)
          .where('makerId', isEqualTo: widget.userId)
          .get();

      int p = 0, o = 0, i = 0, a = 0;
      for (var order in ordersSnapshot.docs) {
        final status = order['order_status'];
        switch (status) {
          case 'pending':
            p++;
            break;
          case 'sent out for delivery':
            o++;
            break;
          case 'delivered':
            i++;
            break;
          case 'accepted':
            a++;
            break;
        }
      }

      setState(() {
        pending = p;
        outForDelivery = o;
        inProgress = i;
        accepted = a;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user counts: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> resetTotalOrders() async {
    try {
      final ordersRef = FirebaseFirestore.instance.collection('Orders');
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);

      // Step 1: Get all active (not cancelled) orders for this maker
      final ordersSnapshot = await ordersRef
          .where('makerId', isEqualTo: widget.userId)
          .where('cancel', isEqualTo: false)
          .get();

      int pendingCount = 0;

      // Step 2: Count only pending orders
      for (var orderDoc in ordersSnapshot.docs) {
        final status = orderDoc['order_status'] ?? '';
        if (status == 'pending') {
          pendingCount++;
        }
      }

      // Step 3: Reset maker's counters
      await userRef.set({
        'totalOrders': pendingCount,
        'pendingOrders': pendingCount,
        'acceptedOrders': 0,
        'sent out for deliveryOrders': 0,
        'deliveredOrders': 0,
      }, SetOptions(merge: true));

      // Step 4: Notify user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order counters reset for ${widget.userId}")),
      );

      // Step 5: Refresh UI counts
      fetchUserCounts();
    } catch (e) {
      print("Error resetting order counts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to reset order counts")),
      );
    }
  }

  Widget _buildCountCardofSales() {
    final userId = widget.userId;

    log("Building count card for userId: $userId");

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined, color: _iconColor),
                SizedBox(width: 10),
                Text(
                  'Marketing Data',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // 🔹 Listen to Firestore changes
            if (userId != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("No data found");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final totalLeads = data['totalLeads'] ?? 0;
                  final totalOrders = data['totalOrders'] ?? 0;
                  final totalPostSaleFollowUp =
                      data['totalPostSaleFollowUp'] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Leads"),
                          Text(
                            totalLeads.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Orders"),
                          Text(
                            totalOrders.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Post Sale Follow-ups"),
                          Text(
                            totalPostSaleFollowUp.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Reset Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Confirm Reset",
                            middleText:
                                "Are you sure you want to reset all counts to zero?",
                            textCancel: "Cancel",
                            textConfirm: "Yes, Reset",
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            onConfirm: () async {
                              Get.back(); // close dialog
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .update({
                                      'totalLeads': 0,
                                      'totalOrders': 0,
                                      'totalPostSaleFollowUp': 0,
                                    });

                                Get.snackbar(
                                  "Success",
                                  "Counts reset to zero.",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              } catch (e) {
                                Get.snackbar(
                                  "Error",
                                  "Failed to reset counts: $e",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset Counts"),
                      ),
                    ],
                  );
                },
              )
            else
              const Text("User not logged in"),
          ],
        ),
      ),
    );
  }

  //maker counter
  Widget _buildCountCardOfMaker() {
    final userId = widget.userId;

    log("Building Maker count card for userId: $userId");

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.production_quantity_limits,
                  color: Colors.deepPurple,
                ),
                SizedBox(width: 10),
                Text(
                  'Maker Dashboard',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // 🔹 Listen to Firestore changes
            if (userId != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("No data found");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final totalOrders = data['totalOrders'] ?? 0;
                  final pending = data['pendingOrders'] ?? 0;
                  final outForDelivery =
                      data['sent out for deliveryOrders'] ?? 0;
                  final delivered = data['deliveredOrders'] ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow("Total Orders", totalOrders, Colors.green),
                      const SizedBox(height: 10),
                      _buildRow("Pending", pending, Colors.orange),
                      const SizedBox(height: 10),

                      _buildRow(
                        "Out for Delivery",
                        outForDelivery,
                        Colors.purple,
                      ),
                      const SizedBox(height: 10),
                      _buildRow("Delivered", delivered, Colors.teal),
                      const SizedBox(height: 20),

                      // 🔹 Reset Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Get.defaultDialog(
                            title: "Confirm Reset",
                            middleText:
                                "Are you sure you want to reset all orders to zero?",
                            textCancel: "Cancel",
                            textConfirm: "Yes, Reset",
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            onConfirm: () async {
                              Get.back(); // close dialog
                              try {
                                await resetTotalOrders();

                                Get.snackbar(
                                  "Success",
                                  "Orders reset to zero.",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              } catch (e) {
                                Get.snackbar(
                                  "Error",
                                  "Failed to reset orders: $e",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset Orders"),
                      ),
                    ],
                  );
                },
              )
            else
              const Text("User not logged in"),
          ],
        ),
      ),
    );
  }

  // Helper widget for rows
  Widget _buildRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 20, 4, 147),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 20, 4, 147),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminAudioListenPage(userId: widget.userId),
          ),
        ),
        icon: const Icon(Icons.mic_none_outlined),
        label: const Text(
          'Monitor User Activity',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _iconColor, // Use custom color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _updateUser,
      backgroundColor: _iconColor, // Use custom color
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.save_outlined),
      label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
    );
  }
}
