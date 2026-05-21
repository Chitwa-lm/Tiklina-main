import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gig_models.dart';
import '../../services/database_service.dart';
import '../../widgets/photo_upload_widget.dart';

/// Post Request Wizard - 4-step flow to create a waste collection request
/// 
/// Steps:
/// 1. Details: Waste type, volume, description
/// 2. Location: Address, GPS coordinates
/// 3. Photos: Upload waste photos
/// 4. Price: Estimated cost and review
class PostRequestWizardScreen extends StatefulWidget {
  const PostRequestWizardScreen({Key? key}) : super(key: key);

  @override
  State<PostRequestWizardScreen> createState() => _PostRequestWizardScreenState();
}

class _PostRequestWizardScreenState extends State<PostRequestWizardScreen> {
  late DatabaseService _databaseService;
  late SupabaseClient _supabase;

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Details
  String _wasteType = 'Mixed Waste';
  String _volumeCategory = 'Small';
  final TextEditingController _descriptionController = TextEditingController();

  // Step 2: Location
  final TextEditingController _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _locationError;

  // Step 3: Photos
  List<String> _photoUrls = [];

  // Step 4: Price
  final TextEditingController _estimatedCostController = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _supabase = Supabase.instance.client;
    _getCurrentLocation();
  }

  /// Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('[PostRequestWizard] Error getting location: $e');
    }
  }

  /// Validate current step
  bool _validateStep(int step) {
    switch (step) {
      case 0: // Details
        if (_wasteType.isEmpty || _descriptionController.text.isEmpty) {
          _showError('Please fill all fields');
          return false;
        }
        return true;

      case 1: // Location
        if (_addressController.text.isEmpty) {
          _showError('Please enter address');
          return false;
        }
        if (_latitude == null || _longitude == null) {
          _showError('Location required');
          return false;
        }
        return true;

      case 2: // Photos
        if (_photoUrls.isEmpty) {
          _showError('Please upload at least one photo');
          return false;
        }
        return true;

      case 3: // Price
        if (_estimatedCostController.text.isEmpty ||
            double.tryParse(_estimatedCostController.text) == null) {
          _showError('Please enter valid cost');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  /// Submit request
  Future<void> _submitRequest() async {
    if (!_validateStep(3)) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create waste request
      final request = await _databaseService.createWasteRequest(
        clientId: userId,
        locationLat: _latitude!,
        locationLng: _longitude!,
        address: _addressController.text,
        wasteType: _wasteType,
        volumeCategory: _volumeCategory,
        description: _descriptionController.text,
        estimatedCost: double.parse(_estimatedCostController.text),
        photoUrls: _photoUrls,
      );

      if (request != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request posted! Collectors will start bidding.')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showError('Failed to post request: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Post Waste Collection Request'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _currentStep
                              ? Colors.green
                              : Colors.grey[300],
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index <= _currentStep
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(_currentStep),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_validateStep(_currentStep)) {
                                if (_currentStep < 3) {
                                  setState(() => _currentStep++);
                                } else {
                                  _submitRequest();
                                }
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _currentStep < 3 ? 'Next' : 'Post Request',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'What type of waste?';
      case 1:
        return 'Where is it located?';
      case 2:
        return 'Show us the waste';
      case 3:
        return 'Review & Post';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildPhotosStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  /// Step 1: Details
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Waste Type'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _wasteType,
          items: [
            'Mixed Waste',
            'Organic',
            'Plastic',
            'Metal',
            'Glass',
            'Paper',
            'E-Waste',
            'Construction Debris',
          ]
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => setState(() => _wasteType = value ?? 'Mixed Waste'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 16),

        const Text('Volume/Size'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _volumeCategory,
          items: ['Small (Bag)', 'Medium (Box)', 'Large (Multiple Bags)', 'Very Large (Bulk)']
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
              .toList(),
          onChanged: (value) => setState(() => _volumeCategory = value ?? 'Small (Bag)'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 16),

        const Text('Additional Details'),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the waste, urgency level, any special instructions...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  /// Step 2: Location
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current location: ${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text('Address / Location Description'),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Street name, building number, landmarks...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
        ),
      ],
    );
  }

  /// Step 3: Photos
  Widget _buildPhotosStep() {
    return PhotoUploadWidget(
      onPhotosUploaded: (urls) {
        setState(() => _photoUrls = urls);
      },
      maxPhotos: 5,
      title: 'Upload Waste Photos',
      subtitle: 'Show collectors what they\'ll be collecting',
    );
  }

  /// Step 4: Review
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewRow('Waste Type', _wasteType),
              const SizedBox(height: 8),
              _reviewRow('Volume', _volumeCategory),
              const SizedBox(height: 8),
              _reviewRow('Location', _addressController.text),
              const SizedBox(height: 8),
              _reviewRow('Photos', '${_photoUrls.length} uploaded'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text('Estimated Collection Cost'),
        const SizedBox(height: 8),
        TextField(
          controller: _estimatedCostController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefix: const Text('\$'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: '50',
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Once posted, collectors nearby will receive notifications and can accept your request. You\'ll be notified when a collector accepts.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }
}
