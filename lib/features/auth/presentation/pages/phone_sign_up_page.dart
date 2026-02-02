import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'authentication_code_page.dart';

class PhoneSignUpPage extends StatefulWidget {
  const PhoneSignUpPage({super.key});

  @override
  State<PhoneSignUpPage> createState() => _PhoneSignUpPageState();
}

class _PhoneSignUpPageState extends State<PhoneSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedCountryCode = '+65';

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendCode() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AuthenticationCodePage(
            phoneNumber: '$_selectedCountryCode${_phoneController.text}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppResources.spacingXL),

                // Title with highlighted "User"
                RichText(
                  text: TextSpan(
                    style: AppFonts.largeTitle(color: AppColors.textPrimary),
                    children: [
                      TextSpan(
                        text: 'User ',
                        style: AppFonts.largeTitle(color: AppColors.brandSecondary),
                      ),
                      const TextSpan(text: 'account'),
                    ],
                  ),
                ),
                const SizedBox(height: AppResources.spacingS),
                Text(
                  'Create your User account',
                  style: AppFonts.largeTitle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingXXL),

                // Full Name field
                Text(
                  'Full Name',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: AppFonts.body(color: AppColors.textTertiary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: const BorderSide(color: AppColors.brandPrimary),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppResources.spacingL),

                // Password field
                Text(
                  'Password',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: AppFonts.body(color: AppColors.textTertiary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: const BorderSide(color: AppColors.brandPrimary),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                const SizedBox(height: AppResources.spacingL),

                // Country and Phone fields
                Row(
                  children: [
                    // Country code dropdown
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Country',
                            style: AppFonts.body(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use - use initialValue when form API is updated
                            value: _selectedCountryCode,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: BorderSide(color: AppColors.backgroundGrey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: BorderSide(color: AppColors.backgroundGrey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: const BorderSide(color: AppColors.brandPrimary),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: '+1', child: Text('+1')),
                              DropdownMenuItem(value: '+65', child: Text('+65')),
                              DropdownMenuItem(value: '+44', child: Text('+44')),
                              DropdownMenuItem(value: '+91', child: Text('+91')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCountryCode = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppResources.spacingM),
                    // Phone number field
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone',
                            style: AppFonts.body(color: AppColors.brandPrimary),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter your phone number',
                              hintStyle: AppFonts.body(color: AppColors.textTertiary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: const BorderSide(color: AppColors.brandPrimary),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: const BorderSide(color: AppColors.brandPrimary),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppResources.radiusM),
                                borderSide: const BorderSide(color: AppColors.brandPrimary),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppResources.spacingXXL),

                // Send Code button
                SizedBox(
                  width: double.infinity,
                  height: AppResources.buttonHeightM,
                  child: ElevatedButton(
                    onPressed: _onSendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: Text(
                      'Send Code',
                      style: AppFonts.button(color: AppColors.textOnPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
