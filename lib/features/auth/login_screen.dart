import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../home/home_screen.dart';
// import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ciController = TextEditingController(text: '3000003');
  final _passController = TextEditingController(text: 'password123');
  final _ciFocusNode = FocusNode();
  final _passFocusNode = FocusNode();

  late final AuthService _authService;
  late final AnimationController _ambientController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _selectedDemoCi = '3000003';

  static const _demoAccounts = [
    _DemoAccount(label: 'Conserje', ci: '3000003', icon: Icons.support_agent_rounded),
    _DemoAccount(label: 'Propietario', ci: '4000004', icon: Icons.key_rounded),
    _DemoAccount(label: 'Inquilino', ci: '5000005', icon: Icons.home_rounded),
    _DemoAccount(label: 'Admin', ci: '2000002', icon: Icons.admin_panel_settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService(apiClient: ApiClient());
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _ciController.addListener(_syncSelectedDemo);
  }

  @override
  void dispose() {
    _ciController.removeListener(_syncSelectedDemo);
    _ciController.dispose();
    _passController.dispose();
    _ciFocusNode.dispose();
    _passFocusNode.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _syncSelectedDemo() {
    final current = _ciController.text.trim();
    if (_selectedDemoCi != current) {
      setState(() => _selectedDemoCi = current);
    }
  }

  bool get _isCupertino {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      await HapticFeedback.heavyImpact();
      return;
    }

    await HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(
        _ciController.text.trim(),
        _passController.text,
      );
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      await HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = _formatError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // void _navigateToForgotPassword() {
  //   HapticFeedback.selectionClick();
  //   FocusScope.of(context).unfocus();
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (_) => ForgotPasswordScreen(
  //         initialCi: _ciController.text.trim(),
  //       ),
  //     ),
  //   );
  // }

  String _formatError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw.isEmpty ? 'No se pudo iniciar sesión. Intenta nuevamente.' : raw;
  }

  void _fillDemo(String ci) {
    HapticFeedback.selectionClick();
    setState(() {
      _ciController.text = ci;
      _passController.text = 'password123';
      _selectedDemoCi = ci;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark ? const Color(0xFF070B14) : const Color(0xFFEEF4FF),
        body: Stack(
          children: [
            _AmbientLiquidBackground(
              animation: _ambientController,
              isDark: isDark,
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: _isCupertino
                      ? const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        )
                      : const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isDark, textPrimary, textSecondary),
                        const SizedBox(height: 24),

                        // Tarjeta de Login con efecto Liquid Glass (BackdropFilter + Container semitransparente)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? const Color(0x55000000)
                                    : const Color(0x1A0F172A),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  color: isDark
                                      ? const Color(0x1EFFFFFF)
                                      : const Color(0xA6FFFFFF),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? const [
                                            Color(0x2BFFFFFF),
                                            Color(0x14FFFFFF),
                                            Color(0x0AFFFFFF),
                                          ]
                                        : const [
                                            Color(0xD9FFFFFF),
                                            Color(0xA6FFFFFF),
                                            Color(0x7AFFFFFF),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0x40FFFFFF)
                                        : const Color(0xE6FFFFFF),
                                    width: 1.3,
                                  ),
                                ),
                                child: AutofillGroup(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildErrorBanner(isDark),
                                        _LiquidTextField(
                                          controller: _ciController,
                                          focusNode: _ciFocusNode,
                                          isDark: isDark,
                                          label: 'Cédula de Identidad (CI)',
                                          hint: 'Ej. 3000003',
                                          icon: Icons.badge_outlined,
                                          keyboardType: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [AutofillHints.username],
                                          onFieldSubmitted: (_) =>
                                              _passFocusNode.requestFocus(),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Ingresa tu Cédula de Identidad';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _LiquidTextField(
                                          controller: _passController,
                                          focusNode: _passFocusNode,
                                          isDark: isDark,
                                          label: 'Contraseña',
                                          hint: '••••••••',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [AutofillHints.password],
                                          onFieldSubmitted: (_) => _handleLogin(),
                                          suffixIcon: IconButton(
                                            tooltip: _obscurePassword
                                                ? 'Mostrar contraseña'
                                                : 'Ocultar contraseña',
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              size: 20,
                                              color: textSecondary,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Ingresa tu contraseña';
                                            }
                                            if (value.length < 4) {
                                              return 'Mínimo 4 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 22),
                                        _LiquidPrimaryButton(
                                          label: 'Iniciar Sesión',
                                          isLoading: _isLoading,
                                          isCupertino: _isCupertino,
                                          onPressed: _isLoading ? null : _handleLogin,
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: TextButton(
                                            onPressed: 
                                            // _isLoading
                                                // ? 
                                                null,
                                                // : _navigateToForgotPassword,
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              foregroundColor: isDark
                                                  ? const Color(0xFF93C5FD)
                                                  : const Color(0xFF1D4ED8),
                                            ),
                                            child: const Text(
                                              '¿Olvidaste tu contraseña?',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildDemoSection(isDark, textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark ? const Color(0x1EFFFFFF) : const Color(0xB3FFFFFF),
                border: Border.all(
                  color: isDark ? const Color(0x38FFFFFF) : const Color(0xE6FFFFFF),
                ),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x552563EB),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Gestión de Condominios',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Accede con tu Cédula de Identidad',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: _errorMessage == null
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark
                    ? const Color(0x40EF4444)
                    : const Color(0xCCFEE2E2),
                border: Border.all(
                  color: isDark
                      ? const Color(0x66F87171)
                      : const Color(0x66EF4444),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFFECACA)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _errorMessage = null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDemoSection(bool isDark, Color textSecondary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x99FFFFFF),
            border: Border.all(
              color: isDark ? const Color(0x33FFFFFF) : const Color(0xCCFFFFFF),
            ),
          ),
          child: Column(
            children: [
              Text(
                'ACCESO RÁPIDO DEMO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _demoAccounts.map((account) {
                  final selected = _selectedDemoCi == account.ci;
                  return _LiquidRoleChip(
                    label: account.label,
                    icon: account.icon,
                    selected: selected,
                    isDark: isDark,
                    onTap: () => _fillDemo(account.ci),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoAccount {
  final String label;
  final String ci;
  final IconData icon;

  const _DemoAccount({
    required this.label,
    required this.ci,
    required this.icon,
  });
}

class _AmbientLiquidBackground extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;

  const _AmbientLiquidBackground({
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(animation.value);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF060A14), Color(0xFF0F172A), Color(0xFF091326)]
                  : const [Color(0xFFEAF2FF), Color(0xFFF6F8FC), Color(0xFFDCEAFE)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90 + (t * 28),
                left: -60 + (t * 20),
                child: _GlowOrb(
                  size: 290,
                  color: isDark
                      ? const Color(0x552563EB)
                      : const Color(0x6660A5FA),
                ),
              ),
              Positioned(
                top: 180 - (t * 24),
                right: -85 + (t * 16),
                child: _GlowOrb(
                  size: 250,
                  color: isDark
                      ? const Color(0x440EA5E9)
                      : const Color(0x5538BDF8),
                ),
              ),
              Positioned(
                bottom: -100 + (t * 20),
                left: 30 - (t * 24),
                child: _GlowOrb(
                  size: 270,
                  color: isDark
                      ? const Color(0x446366F1)
                      : const Color(0x4D818CF8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 52, sigmaY: 52),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _LiquidTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  const _LiquidTextField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark ? const Color(0x1AFFFFFF) : const Color(0x99FFFFFF);
    final borderColor = isDark ? const Color(0x28FFFFFF) : const Color(0x66CBD5E1);
    const focusColor = Color(0xFF2563EB);
    final labelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        hintStyle: TextStyle(color: labelColor.withAlpha(150), fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: labelColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: focusColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
        ),
      ),
    );
  }
}

class _LiquidPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isCupertino;
  final VoidCallback? onPressed;

  const _LiquidPrimaryButton({
    required this.label,
    required this.isLoading,
    required this.isCupertino,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1.0 : 0.72,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          ),
          border: Border.all(color: const Color(0x55FFFFFF), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D2563EB),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: isLoading
                  ? (isCupertino
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        ))
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidRoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LiquidRoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? (isDark ? const Color(0x553B82F6) : const Color(0x262563EB))
        : (isDark ? const Color(0x16FFFFFF) : const Color(0x99FFFFFF));

    final borderColor = selected
        ? const Color(0xFF3B82F6)
        : (isDark ? const Color(0x28FFFFFF) : const Color(0x66CBD5E1));

    final fgColor = selected
        ? (isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8))
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: bgColor,
            border: Border.all(color: borderColor, width: selected ? 1.3 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}