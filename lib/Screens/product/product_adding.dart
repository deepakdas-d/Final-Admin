import 'dart:developer';
import 'dart:io';
import 'package:admin/Crop/customcroper.dart';
import 'package:admin/Crop/helperclass.dart' as AppHelper;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductAddPage extends StatefulWidget {
  @override
  _ProductAddPageState createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Define the custom accent color and text color for consistency
  static const Color _accentColor = Color.fromARGB(255, 209, 52, 67);
  static const Color _textColor = Color(0xFF1A1A1A);

  // State variables
  File? _imageFile;
  bool _isUploading = false;

  // Form data
  final Map<String, dynamic> _product = {
    'name': '',
    'id': '',
    'materials': '',
    'description': '',
    'price': null,
    'imageUrl': '',
    'timestamp': FieldValue.serverTimestamp(),
    'stock': 0, // Assuming stock is always initialized to 0
  };

  // Image Picker
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    await _pickImageWithCropCompress(source, true);
  }

  Future<void> _pickImageWithCropCompress(
    ImageSource source,
    bool isProductImage,
  ) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        _showSnackBar('No image selected', isError: true);
        return;
      }

      final String extension = pickedImage.path.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        _showSnackBar('Only JPG and PNG images are supported.', isError: true);
        return;
      }

      File originalImage = File(pickedImage.path);
      log('Original image path: ${originalImage.path}');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Step 1: Compress
        File? compressedImage = await AppHelper.compress(image: originalImage);
        if (compressedImage == null) {
          _showSnackBar('Failed to compress image', isError: true);
          return;
        }
        log('Compressed image path: ${compressedImage.path}');

        // Step 2: Open custom crop screen
        final File? croppedImage = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomCropScreen(image: compressedImage),
          ),
        );
        log('Cropped image path: ${croppedImage?.path}');

        if (croppedImage == null) {
          _showSnackBar('Image cropping cancelled', isError: true);
          return;
        }

        // Step 3: Update state
        setState(() {
          _imageFile = croppedImage;
          log('State updated with cropped image: ${_imageFile?.path}');
        });

        _showSnackBar('Image processed successfully!', isError: false);

        // Debug sizes
        final sizeBefore = originalImage.lengthSync() / 1024;
        final sizeAfter = croppedImage.lengthSync() / 1024;
        log('Before Processing: ${sizeBefore.toStringAsFixed(2)} KB');
        log('After Processing: ${sizeAfter.toStringAsFixed(2)} KB');
      } catch (e) {
        _showSnackBar('Error processing image: $e', isError: true);
      } finally {
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context); // Dismiss loading dialog
        }
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }
  // Add this new method for handling image picking, compression, and cropping
  // Future<void> _pickImageWithCropCompress(
  //   ImageSource source,
  //   bool isProductImage,
  // ) async {
  //   try {
  //     final XFile? pickedImage = await _picker.pickImage(
  //       source: source,
  //       maxWidth: 800, // Adjusted for better quality
  //       maxHeight: 800,
  //       imageQuality: 85, // Balanced quality and size
  //     );

  //     if (pickedImage != null) {
  //       File image = File(pickedImage.path);

  //       // Show loading indicator
  //       showDialog(
  //         context: context,
  //         barrierDismissible: false,
  //         builder: (context) =>
  //             const Center(child: CircularProgressIndicator()),
  //       );

  //       try {
  //         // Compress the image
  //         File? compressedImage = await AppHelper.compress(image: image);
  //         if (compressedImage == null) {
  //           Navigator.pop(context);
  //           _showSnackBar('Failed to compress image', isError: true);
  //           return;
  //         }

  //         // Crop the image
  //         File? croppedImage = await AppHelper.cropImage(compressedImage);
  //         Navigator.pop(context);

  //         if (croppedImage == null) {
  //           _showSnackBar('Image cropping cancelled', isError: true);
  //           return;
  //         }

  //         // Update state with processed image
  //         setState(() {
  //           _imageFile = croppedImage;
  //         });

  //         _showSnackBar('Image processed successfully!', isError: false);

  //         // Log sizes for debugging
  //         final sizeInKbBefore = image.lengthSync() / 1024;
  //         final sizeInKbAfter = croppedImage.lengthSync() / 1024;
  //         print('Before Processing: ${sizeInKbBefore.toStringAsFixed(2)} KB');
  //         print('After Processing: ${sizeInKbAfter.toStringAsFixed(2)} KB');
  //       } catch (e) {
  //         Navigator.pop(context);
  //         _showSnackBar('Error processing image: $e', isError: true);
  //       }
  //     } else {
  //       _showSnackBar('No image selected', isError: true);
  //     }
  //   } catch (e) {
  //     _showSnackBar('Error picking image: $e', isError: true);
  //   }
  // }

  // Add this helper method for showing snackbars
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
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
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Set bottom sheet background to white
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'Choose Image Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: _accentColor,
                ), // Accent color for icon
                title: const Text(
                  'Photo Library',
                  style: TextStyle(color: _textColor),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: _accentColor,
                ), // Accent color for icon
                title: const Text(
                  'Camera',
                  style: TextStyle(color: _textColor),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 8,
              ), // Adjust for notch
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed.
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product image.'),
          backgroundColor: Colors.red, // Error snackbar color
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    _formKey.currentState!.save();

    try {
      // 1. Upload image to Firebase Storage
      String fileName =
          'products/${_product['id']}_${DateTime.now().millisecondsSinceEpoch}.png'; // Use product ID for better organization
      UploadTask uploadTask = _storage
          .ref()
          .child(fileName)
          .putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      _product['imageUrl'] = downloadUrl;

      // 2. Add product data to Firestore
      await _firestore.collection('products').add(_product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green, // Success snackbar color
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
        });
        // Optionally pop the page after successful submission
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: ${e.toString()}'),
            backgroundColor: Colors.red, // Error snackbar color
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Consistent white background
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: _textColor, // Custom text color
            fontWeight: FontWeight.w600, // Consistent font weight
            fontSize: 18, // Consistent font size
          ),
        ),
        backgroundColor: Colors.white, // AppBar background to white
        elevation: 1, // Subtle elevation
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _textColor,
          ), // Custom icon color
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  _buildTextField(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Product Name',
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a name' : null,
                    onSaved: (value) => _product['name'] = value!.trim(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.qr_code_scanner_outlined,
                    label: 'Product ID',
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an ID' : null,
                    onSaved: (value) => _product['id'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.blender_outlined,
                    label: 'Materials Used',
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter materials' : null,
                    onSaved: (value) => _product['materials'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    maxLines: 4,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a description' : null,
                    onSaved: (value) => _product['description'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.attach_money_outlined,
                    label: 'Price',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }

                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return 'Enter a valid number';

                      // Check if the number before the decimal point has more than 6 digits
                      final parts = value.split('.');
                      if (parts[0].length > 6) {
                        return 'Price must be less than 6 digits';
                      }

                      return null;
                    },
                    onSaved: (value) =>
                        _product['price'] = double.parse(value!),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor, // Custom button color
                      foregroundColor: Colors.white, // Text color for button
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2, // Subtle elevation
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'ADD PRODUCT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading Product...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // A helper method to build styled TextFormFields
  Widget _buildTextField({
    required IconData icon,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: _accentColor,
        ), // Accent color for prefix icons
        filled: true,
        fillColor: Colors.grey[50], // Light fill for text fields
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300), // Subtle border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _accentColor,
            width: 2,
          ), // Accent color for focused border
        ),
        errorBorder: OutlineInputBorder(
          // Consistent error border
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Consistent focused error border
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      textInputAction: TextInputAction.next,
      cursorColor: _accentColor, // Accent color for cursor
    );
  }

  // A helper method for the image picker UI
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 180, // Slightly reduced height for better form flow
        decoration: BoxDecoration(
          color: Colors.grey[50], // Light background for image picker
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ), // Subtle border
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: _accentColor, // Accent color for the icon
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add product image',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
