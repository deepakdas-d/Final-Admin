import 'package:admin/Auth/sigin.dart';
import 'package:admin/Controller/sign_up_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import 'package:get/get.dart';

class Signup extends StatelessWidget {
  final SignupController controller = Get.put(SignupController());

  Signup({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => Signin());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet
                        ? screenWidth * 0.1
                        : 16.0, // Reduced horizontal padding
                    vertical: 10.0, // Reduced vertical padding
                  ),
                  child: Form(
                    // Wrap your Column with a Form widget
                    key: controller.signupFormKey, // Assign the GlobalKey
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top spacing
                        SizedBox(
                          height: screenHeight * 0.05,
                        ), // Smaller top spacing
                        // Logo/Brand section (Adjusted for smaller size)
                        _buildLogoSection(context, isTablet),

                        SizedBox(
                          height: screenHeight * 0.02,
                        ), // Reduced spacing
                        // Welcome text section
                        _buildWelcomeSection(context),

                        SizedBox(
                          height: screenHeight * 0.03,
                        ), // Reduced spacing
                        // Form section for signup fields
                        _buildFormSection(controller, context),

                        SizedBox(
                          height: screenHeight * 0.03,
                        ), // Reduced spacing
                        // Sign up button
                        _buildSignUpButton(controller),

                        SizedBox(
                          height: screenHeight * 0.03,
                        ), // Reduced spacing
                        // Login link
                        _buildLoginLink(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the logo/brand section.
  Widget _buildLogoSection(BuildContext context, bool isTablet) {
    return Center(
      child: Container(
        // Minimized size for the logo container
        width: isTablet ? 150 : 120, // Smaller width
        height: isTablet ? 200 : 130, // Smaller height
        child: Image.asset(
          'assets/images/logo.png', // Assuming you have a 'logo.png' in your assets
          fit: BoxFit.contain,
          // Image dimensions are implicitly controlled by the container's size
          alignment: Alignment.center,
        ),
      ),
    );
  }

  /// Builds the welcome text section.
  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        Text(
          "LET'S GET STARTED",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF030047),
            fontSize: 28, // Slightly reduced font size
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6), // Reduced spacing
        Text(
          'Create your account to get started',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 14, // Slightly reduced font size
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the form section containing text fields.
  Widget _buildFormSection(SignupController controller, BuildContext context) {
    return Column(
      children: [
        // Email field
        _buildTextField(
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            final email = value.trim();
            final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
            if (!gmailRegex.hasMatch(email)) {
              return 'Please enter a valid @gmail.com email';
            }
            return null;
          },
          controller: controller.emailController,
          label: "Email",
          hint: "Enter your email",
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 12), // Reduced spacing
        // Phone number field
        _buildTextField(
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            final phone = value.trim();
            final phoneRegex = RegExp(r'^\d{10}$'); // Exactly 10 digits
            if (!phoneRegex.hasMatch(phone)) {
              return 'Phone number must be exactly 10 digits';
            }
            return null;
          },
          controller: controller.phoneController,
          label: "Phone Number",
          hint: "Enter your phone number",
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        const SizedBox(height: 12), // Reduced spacing
        // Password field
        Obx(
          () => _buildTextField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required.';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long.';
              }
              return null;
            },
            controller: controller.passwordController,
            label: "Password",
            hint: "Create a password",
            prefixIcon: Icons.lock_outline,
            obscureText: !controller.isPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.isPasswordVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
            textInputAction: TextInputAction.next,
          ),
        ),

        const SizedBox(height: 12), // Reduced spacing
        // Confirm Password field
        Obx(
          () => _buildTextField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm password is required.';
              }
              if (value != controller.passwordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
            controller: controller.confirmPasswordController,
            label: "Confirm Password",
            hint: "Confirm your password",
            prefixIcon: Icons.lock_reset_outlined,
            obscureText: !controller.isConfirmPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.isConfirmPasswordVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: controller.toggleConfirmPasswordVisibility,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.signUp(),
          ),
        ),
      ],
    );
  }

  /// Reusable text field builder for consistent styling.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13, // Slightly reduced font size for labels
            fontWeight: FontWeight.w600,
            color: Color(0xFF030047),
          ),
        ),
        const SizedBox(height: 6), // Reduced spacing
        TextFormField(
          validator: validator, // Assign the validator here
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ), // Slightly reduced hint font size
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey.shade600,
              size: 18,
            ), // Smaller icon size
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                10,
              ), // Slightly smaller border radius
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 145, 28, 28),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              // Add focused error border for better UX
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, // Reduced content padding
              vertical: 14, // Reduced content padding
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
          ), // Slightly reduced input font size
        ),
      ],
    );
  }

  /// Builds the Sign Up button.
  Widget _buildSignUpButton(SignupController controller) {
    return Obx(
      () => SizedBox(
        height: 50, // Reduced button height
        child: ElevatedButton(
          onPressed: controller.isLoading.value == true
              ? null
              : controller.signUp, // Call signUp, which now validates
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 145, 28, 28),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color.fromARGB(255, 71, 0, 8).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                10,
              ), // Slightly smaller button radius
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: controller.isLoading.value == true
              ? const SizedBox(
                  width: 18, // Smaller progress indicator
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ), // Slightly reduced font size
                ),
        ),
      ),
    );
  }

  /// Builds the "Already have an account?" login link.
  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            fontSize: 14, // Slightly reduced font size
          ),
        ),
        TextButton(
          onPressed: () => Get.offAll(() => Signin()),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Login",
            style: TextStyle(
              color: Color.fromARGB(255, 145, 28, 28),
              fontSize: 14, // Slightly reduced font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
