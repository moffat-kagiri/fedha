import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class ProfileAvatarPicker extends StatefulWidget {
  final double radius;
  final Function(String?) onImageSelected;
  final String? avatarPath;
  final IconData placeholderIcon;

  const ProfileAvatarPicker({
    super.key,
    required this.radius,
    required this.onImageSelected,
    this.avatarPath,
    this.placeholderIcon = Icons.person,
  });

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  final ImagePicker _picker = ImagePicker();
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _localAvatarPath = widget.avatarPath;
  }

  Future<void> _pickImage(ImageSource source) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _localAvatarPath = pickedFile.path;
        });
        widget.onImageSelected(pickedFile.path);
      }
    } catch (e) {
      // Error handling
      debugPrint('Error picking image: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to select image. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Take a photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_localAvatarPath != null)
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _localAvatarPath = null;
                        });
                        widget.onImageSelected(null);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _localAvatarPath != null
                ? FileImage(File(_localAvatarPath!))
                : null,
            child: _localAvatarPath == null
                ? Icon(
                    widget.placeholderIcon,
                    size: widget.radius,
                    color: FedhaColors.primaryGreen,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: FedhaColors.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
