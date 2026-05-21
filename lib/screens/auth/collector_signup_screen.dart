import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/cloudinary_service.dart';

/// Collector signup screen with KYC verification
/// 
/// Two-step process:
/// 1. Account details (name, email, phone, password)
/// 2. KYC verification (ID photo, selfie, bank account info, service radius)
class CollectorSignupScreen extends StatefulWidget {
  final Function(String userId)? onSignupComplete;

  const CollectorSignupScreen({
    Key? key,
    this.onSignupComplete,
  }) : super(key: key);

  @override
  State<CollectorSignupScreen> createState() => _CollectorSignupScreenState();
}

class _CollectorSignupScreenState extends State<CollectorSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // KYC fields
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  final TextEditingController _serviceRadiusController =
      TextEditingController(text: '10');

  late SupabaseClient _supabase;
  late DatabaseService _databaseService;
  late CloudinaryService _cloudinaryService;

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  File? _idPhotoFile;
  File? _selfiePhotoFile;
  String? _idPhotoUrl;
  String? _selfiePhotoUrl;
  bool _uploadingIdPhoto = false;
  bool _uploadingSelfiePhoto = false;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _databaseService = DatabaseService();
    _cloudinaryService = CloudinaryService();
  }

  void _setError(String message) {
    setState(() => _errorMessage = message);
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  /// Validate step 1 (account details)
  bool _validateStep1() {
    if (_nameController.text.isEmpty) {
      _setError('Name is required');
      return false;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _setError('Valid email is required');
      return false;
    }
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      _setError('Valid phone number is required');
      return false;
    }
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      _setError('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _setError('Passwords do not match');
      return false;
    }
    return true;
  }

  /// Validate step 2 (KYC details)
  bool _validateStep2() {
    if (_idPhotoUrl == null || _idPhotoUrl!.isEmpty) {
      _setError('ID photo is required');
      return false;
    }
    if (_selfiePhotoUrl == null || _selfiePhotoUrl!.isEmpty) {
      _setError('Selfie photo is required');
      return false;
    }
    if (_bankAccountController.text.isEmpty) {
      _setError('Bank account number is required');
      return false;
    }
    if (_bankHolderController.text.isEmpty) {
      _setError('Account holder name is required');
      return false;
    }
    if (_serviceRadiusController.text.isEmpty ||
        double.tryParse(_serviceRadiusController.text) == null) {
      _setError('Valid service radius is required');
      return false;
    }
    return true;
  }

  /// Pick photo from gallery or camera
  Future<void> _pickPhoto({required bool isIdPhoto, required bool useCamera}) async {
    try {
      final picker = ImagePicker();
      final source = useCamera ? ImageSource.camera : ImageSource.gallery;

      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      if (isIdPhoto) {
        setState(() => _idPhotoFile = file);
      } else {
        setState(() => _selfiePhotoFile = file);
      }
    } catch (e) {
      _setError('Failed to pick photo: $e');
    }
  }

  /// Upload photo to Cloudinary
  Future<void> _uploadPhoto({required bool isIdPhoto}) async {
    final file = isIdPhoto ? _idPhotoFile : _selfiePhotoFile;
    if (file == null) {
      _setError('No photo selected');
      return;
    }

    try {
      if (isIdPhoto) {
        setState(() => _uploadingIdPhoto = true);
      } else {
        setState(() => _uploadingSelfiePhoto = true);
      }

      final url = await _cloudinaryService.uploadImage(
        filePath: file.path,
        folder: 'kyc',
      );

      if (url.isNotEmpty) {
        if (isIdPhoto) {
          setState(() => _idPhotoUrl = url);
        } else {
          setState(() => _selfiePhotoUrl = url);
        }
      }
    } catch (e) {
      _setError('Upload failed: $e');
    } finally {
      if (isIdPhoto) {
        setState(() => _uploadingIdPhoto = false);
      } else {
        setState(() => _uploadingSelfiePhoto = false);
      }
    }
  }

  /// Sign up as collector
  Future<void> _signupAsCollector() async {
    _clearError();
    if (!_validateStep2()) return;

    setState(() => _isLoading = true);

    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authResponse.user == null) {
        throw Exception('Signup failed');
      }

      // Create collector profile with KYC data
      await _databaseService.createOrUpdateProfile(
        userId: authResponse.user!.id,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        userRole: 'Collector',
        photoUrl: _selfiePhotoUrl,
        serviceRadiusKm: double.parse(_serviceRadiusController.text),
      );

      // Store KYC data in separate table (if it exists)
      try {
        await Supabase.instance.client.from('kyc_verifications').insert({
          'user_id': authResponse.user!.id,
          'id_photo_url': _idPhotoUrl,
          'selfie_photo_url': _selfiePhotoUrl,
          'id_status': 'Pending',
          'selfie_status': 'Pending',
          'bank_account_number': _bankAccountController.text.trim(),
          'bank_account_holder': _bankHolderController.text.trim(),
          'verification_status': 'Pending',
          'submitted_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('KYC table may not exist: $e');
      }

      widget.onSignupComplete?.call(authResponse.user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Your KYC is under review. Check email for updates.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on AuthException catch (e) {
      _setError('Auth error: ${e.message}');
    } catch (e) {
      _setError('Signup failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up as Collector'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 0 ? Colors.green : Colors.grey[300],
                  ),
                  child: const Center(
                    child: Text('1', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Container(
                  width: 40,
                  height: 2,
                  color: _currentStep >= 1 ? Colors.green : Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 1 ? Colors.green : Colors.grey[300],
                  ),
                  child: const Center(
                    child: Text('2', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Header
            Text(
              _currentStep == 0 ? 'Create Your Account' : 'Verify Your Identity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep == 0
                  ? 'Start collecting waste and earn money'
                  : 'Complete verification to start accepting requests',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) const SizedBox(height: 16),

            // Step content
            if (_currentStep == 0) _buildStep1() else _buildStep2(),

            const SizedBox(height: 24),

            // Navigation buttons
            Row(
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            _clearError();
                            if (_currentStep == 0) {
                              if (_validateStep1()) {
                                setState(() => _currentStep++);
                              }
                            } else {
                              _signupAsCollector();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 0 ? 'Continue' : 'Complete Signup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Step 1: Account Details
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'John Doe',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'collector@example.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+254712345678',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.phone),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'At least 6 characters',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Enter password again',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.lock),
          ),
        ),
      ],
    );
  }

  /// Step 2: KYC Verification
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ID Photo
        const Text('Government ID Photo'),
        const SizedBox(height: 8),
        if (_idPhotoFile != null)
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_idPhotoFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _idPhotoFile = null),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploadingIdPhoto
                    ? null
                    : () => _pickPhoto(isIdPhoto: true, useCamera: false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploadingIdPhoto
                    ? null
                    : () => _pickPhoto(isIdPhoto: true, useCamera: true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        if (_uploadingIdPhoto)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 16),

        // Selfie Photo
        const Text('Selfie Photo'),
        const SizedBox(height: 8),
        if (_selfiePhotoFile != null)
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selfiePhotoFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _selfiePhotoFile = null),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploadingSelfiePhoto
                    ? null
                    : () => _pickPhoto(isIdPhoto: false, useCamera: false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploadingSelfiePhoto
                    ? null
                    : () => _pickPhoto(isIdPhoto: false, useCamera: true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        if (_uploadingSelfiePhoto)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 16),

        // Bank Account
        TextField(
          controller: _bankAccountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Bank Account Number',
            hintText: '1234567890',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.account_balance),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bankHolderController,
          decoration: InputDecoration(
            labelText: 'Account Holder Name',
            hintText: 'Your Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _serviceRadiusController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Service Radius (km)',
            hintText: '10',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on),
            suffixText: 'km',
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    _serviceRadiusController.dispose();
    super.dispose();
  }
}
