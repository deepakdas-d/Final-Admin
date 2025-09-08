import 'dart:io';
import 'package:admin/Crop/helperclass.dart' as AppHelper;
import 'package:admin/Screens/product/Model/productmodel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId; // Receive the document ID

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _formKey = GlobalKey<FormState>(); // Add a GlobalKey for the Form
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  // Define the custom accent color and text color for consistency
  static const Color _accentColor = Color.fromARGB(255, 209, 52, 67);
  static const Color _textColor = Color(0xFF1A1A1A);

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  Product? _product;
  File? _imageFile; // To hold the new image if selected

  // Text editing controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _materialsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _nameController.dispose();
    _idController.dispose();
    _materialsController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('products')
          .doc(widget.productId)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          _product = Product.fromFirestore(docSnapshot);
          // Initialize controllers with product data
          _nameController.text = _product!.name;
          _idController.text = _product!.productId;
          _materialsController.text = _product!.materials;
          _descriptionController.text = _product!.description;
          _priceController.text = _product!.price.toStringAsFixed(
            2,
          ); // Format price
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product not found.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop(); // Go back if product doesn't exist
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    await _pickImageWithCropCompress(source, true);
  }

  // Add this new method for handling image picking, compression, and cropping
  Future<void> _pickImageWithCropCompress(
    ImageSource source,
    bool isProductImage,
  ) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Adjusted for better quality
        maxHeight: 800,
        imageQuality: 85, // Balanced quality and size
      );

      if (pickedImage != null) {
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
            Navigator.pop(context);
            _showSnackBar('Failed to compress image', isError: true);
            return;
          }

          // Crop the image
          File? croppedImage = await AppHelper.cropImage(compressedImage);
          Navigator.pop(context);

          if (croppedImage == null) {
            _showSnackBar('Image cropping cancelled', isError: true);
            return;
          }

          // Update state with processed image
          setState(() {
            _imageFile = croppedImage;
          });

          _showSnackBar('Image processed successfully!', isError: false);

          // Log sizes for debugging
          final sizeInKbBefore = image.lengthSync() / 1024;
          final sizeInKbAfter = croppedImage.lengthSync() / 1024;
          print('Before Processing: ${sizeInKbBefore.toStringAsFixed(2)} KB');
          print('After Processing: ${sizeInKbAfter.toStringAsFixed(2)} KB');
        } catch (e) {
          Navigator.pop(context);
          _showSnackBar('Error processing image: $e', isError: true);
        }
      } else {
        _showSnackBar('No image selected', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                leading: const Icon(Icons.photo_library, color: _accentColor),
                title: Text(
                  'Photo Library',
                  style: TextStyle(color: _textColor),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: _accentColor),
                title: Text('Camera', style: TextStyle(color: _textColor)),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProduct() async {
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do not proceed
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _product?.imageUrl;

      // If a new image was selected, upload it
      if (_imageFile != null) {
        // Optional: Delete old image from Storage if it exists and is different
        if (_product != null &&
            _product!.imageUrl.isNotEmpty &&
            _product!.imageUrl != imageUrl) {
          try {
            await _storage.refFromURL(_product!.imageUrl).delete();
          } catch (e) {
            print(
              "Error deleting old image: $e",
            ); // Log, but don't block update
          }
        }

        final ref = _storage.ref().child(
          'products/${_idController.text}_${DateTime.now().millisecondsSinceEpoch}.png', // Consistent naming
        );
        final uploadTask = ref.putFile(_imageFile!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Prepare the data to update
      final updatedData = {
        'name': _nameController.text,
        'productId': _idController.text, // Ensure correct key for Firestore
        'materials': _materialsController.text,
        'description': _descriptionController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'imageUrl': imageUrl,
        'timestamp':
            FieldValue.serverTimestamp(), // Update timestamp on modification
      };

      // Update the document in Firestore
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to the list page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    // Show a confirmation dialog before deleting
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Dialog background to white
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(color: _textColor),
        ),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
          style: TextStyle(color: _textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: _accentColor,
            ), // Accent color for delete button
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isSaving = true);
      try {
        // Delete the document from Firestore
        await _firestore.collection('products').doc(widget.productId).delete();

        // Optional: Delete the image from Firebase Storage
        if (_product != null && _product!.imageUrl.isNotEmpty) {
          await _storage.refFromURL(_product!.imageUrl).delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back to the list page
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Consistent white background
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Loading...' : 'Edit Product',
          style: const TextStyle(
            fontWeight: FontWeight.w600, // Consistent font weight
            fontSize: 18, // Consistent font size
            color: _textColor, // Custom text color
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // AppBar background to white
        foregroundColor: _textColor, // General foreground color for icons/text
        elevation: 1, // Subtle elevation

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _textColor,
          ), // Custom icon color
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: _accentColor,
            ), // Accent color for delete icon
            onPressed: _isSaving ? null : _deleteProduct,
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentColor),
            ) // Accent color for indicator
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey, // Assign the key
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Image Display and Picker ---
                        GestureDetector(
                          onTap:
                              _showImagePickerOptions, // Call the method to show options
                          child: Container(
                            height: 180, // Consistent height for image picker
                            decoration: BoxDecoration(
                              color: Colors
                                  .grey[50], // Light background for image picker
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300, // Subtle border
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : (_product?.imageUrl.isNotEmpty ?? false)
                                  ? Image.network(
                                      _product!.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            color:
                                                _accentColor, // Accent color for icon
                                            size: 50,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to change product image',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24), // Increased spacing
                        // --- Text Fields with Validators ---
                        _buildTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          icon: Icons.shopping_bag_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              // <-- Modified line
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _idController,
                          label: 'Product ID',
                          icon: Icons.qr_code_scanner_outlined,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter an ID'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _materialsController,
                          label: 'Materials',
                          icon: Icons.blender_outlined,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter materials'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a description'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _priceController,
                          label: 'Price',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a price';
                            }
                            final parsedValue = double.tryParse(value);
                            if (parsedValue == null) {
                              return 'Please enter a valid number';
                            }
                            // Added price validation for length before decimal (if needed, same as add page)
                            final parts = value.split('.');
                            if (parts[0].length > 6) {
                              return 'Price must be less than 6 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        // --- Update Button ---
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.save_alt_outlined,
                            color: Colors.white,
                          ),
                          label: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'UPDATE PRODUCT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                          onPressed: _isSaving ? null : _updateProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _accentColor, // Custom button color
                            foregroundColor:
                                Colors.white, // Text color for button
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2, // Subtle elevation
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Saving changes...',
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

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500, // Adjusted font weight
          color: Colors.grey[700], // Softer label color
        ),
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
      autovalidateMode:
          AutovalidateMode.onUserInteraction, // Validate as the user types
      cursorColor: _accentColor, // Accent color for cursor
    );
  }
}
