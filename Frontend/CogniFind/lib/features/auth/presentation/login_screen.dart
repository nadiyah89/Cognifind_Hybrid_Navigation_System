import 'package:flutter/material.dart';

import 'package:cognifind/features/auth/presentation/register_screen.dart';
import 'package:cognifind/features/navigation/presentation/navigation_screen.dart';
import 'package:cognifind/features/auth/services/auth_service.dart';
import 'package:cognifind/core/storage/token_storage.dart';


/// Login Screen UI
/// This screen allows users to log in using email and password
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {

  /// Form key used to validate input fields
  final _formKey = GlobalKey<FormState>();

  /// Controllers to read email and password text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Auth service for calling backend APIs
  final AuthService _authService = AuthService();

  /// Loading state for login button
  bool _isSubmitting = false;

  /// Remember me checkbox state
  bool _rememberMe = false;

  ///hide/show
  bool _obscurePassword = true;

  /// Dispose controllers when screen is removed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  /// LOGIN FUNCTION
  ///
  /// This function:
  /// 1. Validates form
  /// 2. Calls backend login API
  /// 3. Navigates to NavigationScreen on success
  Future<void> _submit() async {

    /// Validate form first
    if (!_formKey.currentState!.validate()) return;

    /// Show loading spinner
    setState(() => _isSubmitting = true);

    try {

      /// Call backend login API
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      /// Print response in console for debugging
      print(response);

      /// Save JWT token
      await TokenStorage.saveToken(response["token"]);

      if (!mounted) return;

      /// Navigate to main navigation screen after login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NavigationScreen(),
        ),
      );

    } catch (e) {

      /// Show error message if login fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    } finally {

      /// Stop loading spinner
      setState(() => _isSubmitting = false);
    }
  }



  /// Navigate to Register Screen
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }



  /// UI of the login screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                /// App Icon
                const Icon(
                  Icons.navigation,
                  size: 80,
                  color: Colors.indigo,
                ),

                const SizedBox(height: 12),

                /// App title
                const Text(
                  'Welcome to Cognifind',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                /// Login Form
                Form(
                  key: _formKey,

                  child: Column(
                    children: [

                      /// Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,

                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      /// Password field
                      TextFormField(
                        controller: _passwordController,

                        /// controls visibility
                        obscureText: _obscurePassword,

                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),

                          /// show/hide password icon
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

                          border: const OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      /// Remember Me checkbox
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,

                        value: _rememberMe,

                        title: const Text('Remember me'),

                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _rememberMe = value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// Login Button
                SizedBox(
                  height: 48,

                  child: ElevatedButton(

                    onPressed: _isSubmitting ? null : _submit,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Navigate to Register screen
                TextButton(
                  onPressed: _goToRegister,
                  child: const Text("New here? Create an account"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}