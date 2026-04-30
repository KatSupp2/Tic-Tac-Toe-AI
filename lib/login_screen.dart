import 'package:flutter/material.dart';
import 'auth_service.dart';

const Color kBg        = Color(0xFFFAF8F5);
const Color kBgCard    = Color(0xFFFFFFFF);
const Color kBgSec    = Color(0xFFF2EDE9);
const Color kBorder    = Color(0xFFE0D5CF);
const Color kNavy      = Color(0xFF1C1C2E);
const Color kGold      = Color(0xFFB8960C);
const Color kGoldLight = Color(0xFFF5EDD0);
const Color kTextDark  = Color(0xFF1C1C2E);
const Color kTextMuted = Color(0xFF9E8E8E);
const Color kTextBody  = Color(0xFF5C4F4F);
const Color kError     = Color(0xFFC0392B);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _errorMessage = null);

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
      Navigator.of(context).pushReplacementNamed('/splash');
    } else if (mounted) {
      setState(() => _errorMessage = error);
    }
  }

  void _toggleAuthMode() {
    _clearError();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _fadeCtrl
      ..reset()
      ..forward();
    setState(() {
      _isLogin = !_isLogin;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  void _playAsGuest() =>
      Navigator.of(context).pushReplacementNamed('/game-guest');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Subtle warm-radial backdrop
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6, -0.8),
                  radius: 1.1,
                  colors: [Color(0xFFFFF8ED), kBg],
                ),
              ),
            ),
          ),

          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGoldLight.withOpacity(0.45),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8DDD5).withOpacity(0.5),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildCard(),
                    const SizedBox(height: 20),
                    _buildToggleButton(),
                    const SizedBox(height: 16),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildGuestButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Monogram badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: kNavy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.games_rounded,
            size: 34,
            color: Color(0xFFF5EDD0),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _isLogin ? 'Welcome Back' : 'Create Account',
          style: const TextStyle(
            color: kTextDark,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue your journey'
              : 'Join the AI challenge today',
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 14,
            letterSpacing: 0.2,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C2E).withOpacity(0.07),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF1C1C2E).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              obscure: _obscureConfirmPassword,
              onToggleObscure: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _buildAuthButton(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kError.withOpacity(0.06),
        border: Border.all(color: kError.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: kError, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: kError,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
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
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextBody,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kBgSec,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscure,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
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
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: kGold, size: 19),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: isPassword
                  ? GestureDetector(
                onTap: onToggleObscure,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: kTextMuted,
                    size: 19,
                  ),
                ),
              )
                  : null,
              suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isLoading ? null : _handleAuth,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: _isLoading
                ? LinearGradient(
              colors: [kNavy.withOpacity(0.5), kNavy.withOpacity(0.5)],
            )
                : const LinearGradient(
              colors: [Color(0xFF1C1C2E), Color(0xFF3D3450)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isLoading
                ? []
                : [
              BoxShadow(
                color: kNavy.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(kGoldLight),
              ),
            )
                : Text(
              _isLogin ? 'Sign In' : 'Create Account',
              style: const TextStyle(
                color: Color(0xFFF5EDD0),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
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
                    ? "Don't have an account?  "
                    : 'Already have an account?  ',
                style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 13.5,
                  letterSpacing: 0.1,
                ),
              ),
              TextSpan(
                text: _isLogin ? 'Sign up' : 'Sign in',
                style: const TextStyle(
                  color: kGold,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: kBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              color: kTextMuted.withOpacity(0.8),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: kBorder, thickness: 1)),
      ],
    );
  }

  Widget _buildGuestButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isLoading ? null : _playAsGuest,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: kBgCard,
            border: Border.all(color: kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kTextDark.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.person_outline_rounded, color: kTextBody, size: 18),
              SizedBox(width: 8),
              Text(
                'Continue as Guest',
                style: TextStyle(
                  color: kTextBody,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}