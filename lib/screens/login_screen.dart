
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'service_home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color navyColor = Color(0xFF172B4D);
  static const Color tealColor = Color(0xFF16B8A6);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color textColor = Color(0xFF18233B);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      final role = result['role'] as String;
      final technicianName = result['name'] as String;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceHomePage(
            initialRole: role,
            technicianName: technicianName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.blueGrey.shade300,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: navyColor.withValues(alpha: 0.65),
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.blueGrey.shade100,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.blueGrey.shade100,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: tealColor,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                navyColor,
                                Color(0xFF263F69),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: navyColor.withValues(alpha: 0.20),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_repair_service_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'SECURIS',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: navyColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'SERVICE MANAGEMENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 34),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.blueGrey.shade50,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: navyColor.withValues(alpha: 0.06),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue to your account.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey.shade500,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 30),

                          _fieldLabel('Email Address'),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }

                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 22),

                          _fieldLabel('Password'),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              hint: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),

                          const SizedBox(height: 30),

                          // Sign in button
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navyColor,
                                disabledBackgroundColor:
                                navyColor.withValues(alpha: 0.55),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _isLoading
                                    ? const SizedBox(
                                  key: ValueKey('loading'),
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Row(
                                  key: ValueKey('signin'),
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: tealColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Flexible(
                                child: Text(
                                  'Secure access for Admin and Technician',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'SECURIS  •  SERVICE & REPAIR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
