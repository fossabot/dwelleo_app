import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_card.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Login (Welcome Back). Mirrors dwelleo.sa's login page and is wired to
/// [AuthCubit]; the actual `/auth/login` token parsing is PENDING a captured
/// live response (see AuthRemoteDataSource).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;

  // Server-side auth error → red field borders + inline message (cleared on edit).
  bool _showError = false;
  String _errorMsg = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_showError) setState(() => _showError = false);
  }

  void _todo(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  /// Field label per §2: 14 / 400, muted (onSurfaceVariant ≈ white@60%).
  Widget _label(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _fieldIcon(BuildContext context, String asset) => Padding(
    padding: const EdgeInsets.all(14),
    child: SvgPicture.asset(
      asset,
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go(RoutePaths.home);
          } else if (state is AuthFailure) {
            setState(() {
              _showError = true;
              _errorMsg = state.message;
            });
          }
        },
        child: _buildScaffold(context, ar, scheme),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, bool ar, ColorScheme scheme) {
    return Scaffold(
      appBar: const DwelleoAppBar(),
      body: AuthBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                ar ? 'مرحبًا بعودتك' : 'Welcome Back',
                textAlign: TextAlign.center,
                // §2: 36 / weight 700.
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                ar
                    ? 'سجّل الدخول للمتابعة إلى دويليو'
                    : 'Sign in to continue to Dwelleo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, ar ? 'البريد الإلكتروني' : 'Email Address'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearError(),
                      decoration: InputDecoration(
                        prefixIcon: _fieldIcon(context, AppSvg.inputEmail),
                        hintText: 'your.email@example.com',
                        // Red border (no duplicate text — message sits under password).
                        error: _showError ? const SizedBox.shrink() : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(context, ar ? 'كلمة المرور' : 'Password'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      onChanged: (_) => _clearError(),
                      decoration: InputDecoration(
                        prefixIcon: _fieldIcon(context, AppSvg.inputPassword),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        hintText: '••••••••',
                        errorText: _showError ? _errorMsg : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember Me (local UI state only).
                        InkWell(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(
                                      () => _rememberMe = v ?? false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(ar ? 'تذكرني' : 'Remember Me'),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(RoutePaths.forgotPassword),
                          child: Text(
                            ar ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Sign In is disabled (grey) until both fields are non-empty,
                    // and shows a spinner while the request is in flight.
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final loading = authState is AuthLoading;
                        return ListenableBuilder(
                          listenable: Listenable.merge([_email, _password]),
                          builder: (context, _) {
                            final canSubmit =
                                _email.text.trim().isNotEmpty &&
                                _password.text.isNotEmpty &&
                                !loading;
                            return FilledButton(
                              onPressed: canSubmit
                                  ? () => context.read<AuthCubit>().login(
                                      email: _email.text.trim(),
                                      password: _password.text,
                                    )
                                  : null,
                              child: loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(ar ? 'تسجيل الدخول' : 'Sign In'),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(ar ? 'أو' : 'OR'),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _todo('Google'),
                      icon: SvgPicture.asset(
                        AppSvg.google,
                        width: 20,
                        height: 20,
                      ),
                      label: Text(
                        ar ? 'المتابعة عبر Google' : 'Continue with Google',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ar ? 'ليس لديك حساب؟' : "Don't have an account?"),
                        TextButton(
                          onPressed: () => context.go(RoutePaths.signupRole),
                          child: Text(ar ? 'إنشاء حساب' : 'Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
