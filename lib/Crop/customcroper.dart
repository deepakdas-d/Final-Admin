import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CustomCropScreen extends StatefulWidget {
  final File image;
  const CustomCropScreen({super.key, required this.image});

  @override
  State<CustomCropScreen> createState() => _CustomCropScreenState();
}

class _CustomCropScreenState extends State<CustomCropScreen> {
  final CropController _controller = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          title: const Text("Crop Image"),
          backgroundColor: Colors.red,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Return null on back press
            },
          ),
          actions: [
            PopupMenuButton<double?>(
              icon: const Icon(Icons.crop),
              onSelected: (value) {
                _controller.aspectRatio = value; // set aspect ratio
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1.0, child: Text("1:1 (Square)")),
                const PopupMenuItem(value: 16 / 9, child: Text("16:9")),
                const PopupMenuItem(value: 4 / 3, child: Text("4:3")),
                const PopupMenuItem(value: null, child: Text("Free")),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              controller: _controller,
              image: widget.image.readAsBytesSync(),
              onCropped: (croppedData) {
                try {
                  Uint8List imageData;
                  if (croppedData is CropSuccess) {
                    imageData = croppedData
                        .croppedImage; // Access croppedImage from CropSuccess
                  } else if (croppedData is Uint8List) {
                    imageData =
                        croppedData as Uint8List; // Fallback for older versions
                  } else {
                    throw Exception(
                      'Unexpected croppedData type: ${croppedData.runtimeType}',
                    );
                  }

                  final croppedFile = File(
                    '${widget.image.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
                  );
                  croppedFile.writeAsBytesSync(imageData);
                  print('Cropped file saved at: ${croppedFile.path}');
                  Navigator.pop(context, croppedFile);
                } catch (e) {
                  print('Error in onCropped: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to crop image: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context); // Return null on error
                }
              },
              baseColor: Colors.black,
              maskColor: Colors.black.withOpacity(0.5),
              withCircleUi: false,
              cornerDotBuilder: (size, cornerIndex) =>
                  const DotControl(color: Colors.red),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Done"),
              onPressed: () {
                _controller.crop(); // Triggers onCropped
              },
            ),
          ),
        ],
      ),
    );
  }
}
