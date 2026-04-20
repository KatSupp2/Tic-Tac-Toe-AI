import 'package:flutter/material.dart';
import 'auth_service.dart';

// Color scheme matching main.dart
const Color kBg        = Color(0xFF0F0305);
const Color kBgCard    = Color(0xFF1A0508);
const Color kBgDeep    = Color(0xFF2A0A10);
const Color kBorder    = Color(0xFF6B1A22);
const Color kCrimson   = Color(0xFF8B0000);
const Color kGold      = Color(0xFFC8A800);
const Color kTextLight = Color(0xFFF0E6E6);
const Color kTextMuted = Color(0xFF8A5A5A);
const Color kTextBody  = Color(0xFFC8A0A0);
const Color kLose      = Color(0xFFFF6060);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  Future<void> _handleAuth() async {
    _clearError();

    setState(() => _isLoading = true);

    String? error;
    if (_isLogin) {
      error = await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      error = await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (error == null && mounted) {
      // Success - navigate to game
      Navigator.of(context).pushReplacementNamed('/game');
    } else if (mounted) {
      setState(() => _errorMessage = error);
    }
  }

  void _toggleAuthMode() {
    _clearError();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isLogin = !_isLogin;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.2,
            colors: [Color(0xFF2A0A0F), kBg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 50),
                _buildForm(),
                const SizedBox(height: 30),
                _buildAuthButton(),
                const SizedBox(height: 20),
                _buildToggleButton(),
                const SizedBox(height: 20),
                _buildGuestButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kGold, width: 2),
          ),
          child: const Icon(
            Icons.games,
            size: 40,
            color: kGold,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'WELCOME BACK' : 'CREATE ACCOUNT',
          style: const TextStyle(
            color: kGold,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Sign in to continue' : 'Join the AI challenge',
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border.all(color: kLose, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: kLose, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: kLose,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildTextField(
          controller: _emailController,
          label: 'EMAIL',
          hint: 'your@email.com',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'PASSWORD',
          hint: 'Enter your password',
          icon: Icons.lock_outlined,
          isPassword: true,
          obscure: _obscurePassword,
          onToggleObscure: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        if (!_isLogin) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'CONFIRM PASSWORD',
            hint: 'Re-enter your password',
            icon: Icons.lock_outlined,
            isPassword: true,
            obscure: _obscureConfirmPassword,
            onToggleObscure: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kGold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8),
            color: kBgCard,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscure,
            style: const TextStyle(
              color: kTextLight,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: kTextMuted,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: kGold, size: 20),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: onToggleObscure,
                      child: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: kTextMuted,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kGold, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleAuth,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(
                      colors: [kGold.withOpacity(0.3), kGold.withOpacity(0.3)],
                    )
                  : const LinearGradient(
                      colors: [kCrimson, kGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kGold),
                      ),
                    )
                  : Text(
                      _isLogin ? 'SIGN IN' : 'SIGN UP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _toggleAuthMode,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _isLogin
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              TextSpan(
                text: _isLogin ? 'SIGN UP' : 'SIGN IN',
                style: const TextStyle(
                  color: kGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _playAsGuest,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(
                      colors: [kTextMuted.withOpacity(0.3), kTextMuted.withOpacity(0.3)],
                    )
                  : const LinearGradient(
                      colors: [kBgDeep, kBgCard],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'PLAY AS GUEST',
                style: TextStyle(
                  color: kTextLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _playAsGuest() {
    Navigator.of(context).pushReplacementNamed('/game-guest');
  }
}