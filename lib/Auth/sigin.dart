import 'package:admin/Auth/signup.dart';
import 'package:admin/Controller/sign_in_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// Change StatelessWidget to GetView<SigninController>
class Signin extends GetView<SigninController> {
  const Signin({super.key});

  @override
  Widget build(BuildContext context) {
    // You no longer need Get.put(SigninController()) here.
    // The controller is automatically available via the 'controller' getter.
    final controller = Get.put(SigninController()); // REMOVE THIS LINE

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
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
                  horizontal: isTablet ? screenWidth * 0.1 : 16.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top spacing
                    SizedBox(height: screenHeight * 0.05),

                    // Logo/Brand section
                    _buildLogoSection(context, isTablet),

                    SizedBox(height: screenHeight * 0.02),

                    // Welcome text section
                    _buildWelcomeSection(context),

                    SizedBox(height: screenHeight * 0.03),

                    // Form section
                    // Use 'controller' directly from GetView
                    _buildFormSection(controller),

                    SizedBox(height: screenHeight * 0.03),

                    // Sign in button
                    // Use 'controller' directly from GetView
                    _buildSignInButton(controller),

                    SizedBox(height: screenHeight * 0.03),

                    // Sign up link
                    _buildSignUpLink(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isTablet) {
    return Center(
      child: Container(
        width: isTablet ? 150 : 120,
        height: isTablet ? 200 : 130,
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF030047),
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue to your account',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection(SigninController controller) {
    return Column(
      children: [
        // Email or Phone field
        _buildTextField(
          controller: controller.emailOrPhoneController,
          label: "Email or Phone Number",
          hint: "Enter your email or phone",
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 12),

        // Password field
        Obx(
          () => _buildTextField(
            controller: controller.passwordController,
            label: "Password",
            hint: "Enter your password",
            prefixIcon: Icons.lock_outline,
            obscureText: !controller.isPasswordVisible.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.isPasswordVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
                size: 18,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.handleSignIn(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF030047),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 18),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSignInButton(SigninController controller) {
    return Obx(
      () => SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: controller.isLoading.value == true
              ? null
              : controller.handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 145, 28, 28),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color.fromARGB(255, 71, 0, 8).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: controller.isLoading.value == true
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.offAll(() => Signup());
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: Color.fromARGB(255, 145, 28, 28),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
