import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';

/// Widget for uploading photos to Cloudinary
/// 
/// Features:
/// - Pick from gallery or camera
/// - Preview selected photos
/// - Upload to Cloudinary
/// - Show upload progress
/// - Handle errors gracefully
class PhotoUploadWidget extends StatefulWidget {
  final Function(List<String>) onPhotosUploaded; // Callback with Cloudinary URLs
  final int maxPhotos;
  final bool allowMultiple;
  final String title;
  final String? subtitle;
  final Function()? onUploadStart;
  final Function()? onUploadComplete;

  const PhotoUploadWidget({
    Key? key,
    required this.onPhotosUploaded,
    this.maxPhotos = 5,
    this.allowMultiple = true,
    this.title = 'Add Photos',
    this.subtitle,
    this.onUploadStart,
    this.onUploadComplete,
  }) : super(key: key);

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  late CloudinaryService _cloudinaryService;

  List<File> _selectedPhotos = [];
  List<String> _uploadedUrls = [];
  Map<int, double> _uploadProgress = {};
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _cloudinaryService = CloudinaryService();
  }

  /// Pick photo from gallery
  Future<void> _pickFromGallery() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return;

      setState(() {
        // Add only up to maxPhotos
        final available = widget.maxPhotos - _selectedPhotos.length;
        final toAdd = pickedFiles.take(available).toList();
        _selectedPhotos.addAll(toAdd.map((f) => File(f.path)));
      });
    } catch (e) {
      print('[PhotoUploadWidget] Error picking from gallery: $e');
      _showError('Failed to pick photo: $e');
    }
  }

  /// Take photo with camera
  Future<void> _pickFromCamera() async {
    try {
      if (_selectedPhotos.length >= widget.maxPhotos) {
        _showError('Maximum photos reached');
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedPhotos.add(File(pickedFile.path));
      });
    } catch (e) {
      print('[PhotoUploadWidget] Error taking photo: $e');
      _showError('Failed to take photo: $e');
    }
  }

  /// Remove selected photo
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  /// Upload all selected photos to Cloudinary
  Future<void> _uploadPhotos() async {
    if (_selectedPhotos.isEmpty) {
      _showError('No photos selected');
      return;
    }

    setState(() => _isUploading = true);
    widget.onUploadStart?.call();

    try {
      final urls = <String>[];

      for (int i = 0; i < _selectedPhotos.length; i++) {
        final url = await _cloudinaryService.uploadImage(
          filePath: _selectedPhotos[i].path,
          onProgress: (progress) {
            setState(() {
              _uploadProgress[i] = progress;
            });
          },
        );

        if (url.isNotEmpty) {
          urls.add(url);
        } else {
          throw Exception('Failed to upload photo ${i + 1}');
        }
      }

      setState(() {
        _uploadedUrls = urls;
        _selectedPhotos.clear();
        _uploadProgress.clear();
      });

      widget.onPhotosUploaded(urls);
      widget.onUploadComplete?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${urls.length} photo(s) uploaded successfully')),
      );
    } catch (e) {
      print('[PhotoUploadWidget] Error uploading photos: $e');
      _showError('Upload failed: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Show error dialog
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Action buttons
        if (!_isUploading) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectedPhotos.length < widget.maxPhotos
                      ? _pickFromGallery
                      : null,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectedPhotos.length < widget.maxPhotos
                      ? _pickFromCamera
                      : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),

        // Selected photos preview
        if (_selectedPhotos.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected (${_selectedPhotos.length}/${widget.maxPhotos})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedPhotos.length > 1)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedPhotos.clear()),
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            // Image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedPhotos[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // Remove button
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            // Upload progress
                            if (_uploadProgress.containsKey(index))
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                    child: LinearProgressIndicator(
                                      value: _uploadProgress[index],
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadPhotos,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploading
                    ? 'Uploading...'
                    : 'Upload ${_selectedPhotos.length} Photo(s)',
              ),
            ),
          ),
        ],

        // Uploaded URLs display
        if (_uploadedUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${_uploadedUrls.length} Photo(s) Uploaded',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _uploadedUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_uploadedUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        width: 100,
                        height: 100,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact photo upload button (for minimal UI)
class CompactPhotoUploadButton extends StatelessWidget {
  final Function(List<String>) onPhotosUploaded;
  final int maxPhotos;

  const CompactPhotoUploadButton({
    Key? key,
    required this.onPhotosUploaded,
    this.maxPhotos = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => PhotoUploadWidget(
            onPhotosUploaded: onPhotosUploaded,
            maxPhotos: maxPhotos,
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
