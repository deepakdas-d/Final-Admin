
import 'package:flutter/material.dart';

class fileruser extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const fileruser({super.key, required this.onApplyFilters});

  @override
  State<fileruser> createState() => _fileruserState();
}

class _fileruserState extends State<fileruser> {
  String? _selectedRole;
  String? _selectedGender;
  bool? _isActive;
  String? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue[600]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 32, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Filter Users',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          ListTile(
            title: const Text('Gender'),
            trailing: const Icon(Icons.radio_button_unchecked),
            onTap: () {},
            enabled: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'Male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'Female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Other'),
                  value: 'Other',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Active Status'),
            trailing: const Icon(Icons.toggle_on),
            onTap: () {},
            enabled: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SwitchListTile(
              title: const Text('Active'),
              value: _isActive ?? false,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Place'),
            trailing: const Icon(Icons.location_on),
            onTap: () {},
            enabled: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _selectedPlace = value.isNotEmpty ? value : null;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter place',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilters({
                  'role': _selectedRole,
                  'gender': _selectedGender,
                  'isActive': _isActive,
                  'place': _selectedPlace,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedRole = null;
                  _selectedGender = null;
                  _isActive = null;
                  _selectedPlace = null;
                });
                widget.onApplyFilters({
                  'role': null,
                  'gender': null,
                  'isActive': null,
                  'place': null,
                });
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
