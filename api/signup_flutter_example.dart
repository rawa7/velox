// Flutter Signup Example
// This file demonstrates how to implement user registration

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// MODEL CLASSES
// ============================================================================

class SignupRequest {
  final String name;
  final String phone;
  final String address;
  final String password;
  final String? email;
  final String? instagram;
  final String? facebook;

  SignupRequest({
    required this.name,
    required this.phone,
    required this.address,
    required this.password,
    this.email,
    this.instagram,
    this.facebook,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'password': password,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (instagram != null && instagram!.isNotEmpty) 'instagram': instagram,
      if (facebook != null && facebook!.isNotEmpty) 'facebook': facebook,
    };
  }
}

class User {
  final int userId;
  final String name;
  final String phone;
  final String address;
  final String? email;
  final String? instagram;
  final String? facebook;
  final int usertype;
  final int isActive;

  User({
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
    this.instagram,
    this.facebook,
    required this.usertype,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      email: json['email'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      usertype: json['usertype'],
      isActive: json['is_active'],
    );
  }
}

class SignupResponse {
  final bool success;
  final String message;
  final User? user;

  SignupResponse({
    required this.success,
    required this.message,
    this.user,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      success: json['success'],
      message: json['message'],
      user: json['success'] && json['data'] != null
          ? User.fromJson(json['data'])
          : null,
    );
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

class SignupService {
  static const String baseUrl = 'https://veloxshoppingiq.com/api';

  static Future<SignupResponse> signup(SignupRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      final jsonData = json.decode(response.body);
      return SignupResponse.fromJson(jsonData);
    } catch (e) {
      return SignupResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}

// ============================================================================
// SIGNUP SCREEN
// ============================================================================

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = SignupRequest(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      instagram: _instagramController.text.trim().isNotEmpty
          ? _instagramController.text.trim()
          : null,
      facebook: _facebookController.text.trim().isNotEmpty
          ? _facebookController.text.trim()
          : null,
    );

    final response = await SignupService.signup(request);

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success!'),
          content: Text(response.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to login screen
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new account to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),

                // Required Fields Section
                Text(
                  'Required Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    hintText: 'Enter your full name',
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: '+1234567890',
                  ),
                  validator: _validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address *',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    hintText: 'Enter your address',
                  ),
                  validator: _validateAddress,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    hintText: 'Re-enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 32),

                // Optional Fields Section
                Text(
                  'Optional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                    hintText: 'your.email@example.com',
                  ),
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // Instagram Field
                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'Instagram (Optional)',
                    prefixIcon: Icon(Icons.camera_alt),
                    border: OutlineInputBorder(),
                    hintText: '@username',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                // Facebook Field
                TextFormField(
                  controller: _facebookController,
                  decoration: InputDecoration(
                    labelText: 'Facebook (Optional)',
                    prefixIcon: Icon(Icons.facebook),
                    border: OutlineInputBorder(),
                    hintText: 'facebook.com/yourprofile',
                  ),
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: 32),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSignup,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SIMPLE USAGE EXAMPLE
// ============================================================================

void simpleSignupExample() async {
  // Create signup request
  final request = SignupRequest(
    name: 'John Doe',
    phone: '+1234567890',
    address: '123 Main Street, New York',
    password: 'securePass123',
    email: 'john@example.com', // Optional
  );

  // Call signup API
  final response = await SignupService.signup(request);

  if (response.success) {
    print('Signup successful!');
    print('User ID: ${response.user!.userId}');
    print('Name: ${response.user!.name}');
    print('Phone: ${response.user!.phone}');
    // Navigate to home screen or login screen
  } else {
    print('Signup failed: ${response.message}');
    // Show error message to user
  }
}

