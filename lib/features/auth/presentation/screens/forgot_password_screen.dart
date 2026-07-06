import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/password_requirements.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_card.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';

/// Forgot-password wizard (one route, cubit-swapped steps) — mirrors
/// dwelleo.sa/forget-password: email → 4-digit code (+ live resend countdown) →
/// set new password. Wired to the VERIFIED live API (see HANDOFF §Forgot Password).
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ForgotPasswordCubit>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _code = '';
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  ForgotPasswordCubit get _cubit => context.read<ForgotPasswordCubit>();

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state.step == FpStep.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar
                    ? 'تم تغيير كلمة المرور. سجّل الدخول.'
                    : 'Password reset. Please sign in.',
              ),
            ),
          );
          context.go(RoutePaths.login);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: const DwelleoAppBar(),
          body: AuthBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Text(
                    _title(ar, state.step),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle(ar, state),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (state.step == FpStep.code) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AuthCard(child: _stepCard(ar, scheme, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _title(bool ar, FpStep step) => switch (step) {
    FpStep.email => ar ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
    FpStep.code => ar ? 'أدخل رمز التحقق' : 'Enter Verification Code',
    FpStep.password ||
    FpStep.done => ar ? 'تعيين كلمة مرور جديدة' : 'Set New Password',
  };

  String _subtitle(bool ar, ForgotPasswordState s) => switch (s.step) {
    FpStep.email =>
      ar
          ? 'أدخل بريدك الإلكتروني لتصلك رمز التحقق'
          : 'Enter your email to receive a verification code',
    FpStep.code =>
      ar ? 'أرسلنا رمزًا من 4 أرقام إلى' : 'We sent a 4-digit code to',
    FpStep.password || FpStep.done =>
      ar
          ? 'أنشئ كلمة مرور قوية لحسابك'
          : 'Create a strong password for your account',
  };

  Widget _stepCard(bool ar, ColorScheme scheme, ForgotPasswordState s) {
    return switch (s.step) {
      FpStep.email => _emailStep(ar, scheme, s),
      FpStep.code => _codeStep(ar, scheme, s),
      FpStep.password || FpStep.done => _passwordStep(ar, scheme, s),
    };
  }

  // ── Step 1: email ──────────────────────────────────────────────────────────
  Widget _emailStep(bool ar, ColorScheme scheme, ForgotPasswordState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ar ? 'البريد الإلكتروني' : 'Email Address'),
        const SizedBox(height: 6),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            _cubit.clearError();
            setState(() {}); // re-evaluate _isEmail → enable the Send button
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.mail_outline),
            hintText: 'your.email@example.com',
            errorText: s.error,
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: ar ? 'إرسال رمز التحقق' : 'Send Verification Code',
          busy: s.busy,
          onPressed: _isEmail(_email.text)
              ? () => _cubit.sendCode(_email.text)
              : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => context.go(RoutePaths.login),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(ar ? 'العودة لتسجيل الدخول' : 'Back to Login'),
          ),
        ),
      ],
    );
  }

  // ── Step 2: code + live resend countdown ───────────────────────────────────
  Widget _codeStep(bool ar, ColorScheme scheme, ForgotPasswordState s) {
    final canResend = s.secondsLeft == 0 && !s.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ar ? 'رمز التحقق' : 'Verification Code'),
        const SizedBox(height: 10),
        _OtpBoxes(
          onChanged: (v) {
            _code = v;
            _cubit.clearError();
            setState(() {});
          },
        ),
        if (s.error != null) ...[
          const SizedBox(height: 8),
          Text(
            s.error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        // Live countdown — real timer, not static text.
        canResend
            ? TextButton(
                onPressed: _cubit.resend,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(ar ? 'إعادة إرسال الرمز' : 'Resend Code'),
              )
            : Text(
                ar
                    ? 'إعادة الإرسال خلال ${s.secondsLeft}ث'
                    : 'Resend code in ${s.secondsLeft}s',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: ar ? 'تحقّق من الرمز' : 'Verify Code',
          busy: s.busy,
          onPressed: _code.length == 4 ? () => _cubit.verify(_code) : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _cubit.changeEmail,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(ar ? 'تغيير البريد' : 'Change Email'),
          ),
        ),
      ],
    );
  }

  // ── Step 3: new password ───────────────────────────────────────────────────
  Widget _passwordStep(bool ar, ColorScheme scheme, ForgotPasswordState s) {
    final valid =
        Validators.isStrongPassword(_password.text) &&
        _confirm.text == _password.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ar ? 'كلمة المرور الجديدة' : 'New Password'),
        const SizedBox(height: 6),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onChanged: (_) {
            _cubit.clearError();
            setState(() {});
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            hintText: ar ? 'أنشئ كلمة مرور قوية' : 'Create a strong password',
          ),
        ),
        if (_password.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          PasswordRequirements(_password.text),
        ],
        const SizedBox(height: 16),
        Text(ar ? 'تأكيد كلمة المرور' : 'Confirm Password'),
        const SizedBox(height: 6),
        TextField(
          controller: _confirm,
          obscureText: _obscureConfirm,
          onChanged: (_) {
            _cubit.clearError();
            setState(() {});
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            hintText: ar ? 'أعد إدخال كلمة المرور' : 'Re-enter your password',
            errorText:
                (_confirm.text.isNotEmpty && _confirm.text != _password.text)
                ? (ar ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match')
                : s.error,
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: ar ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
          busy: s.busy,
          onPressed: valid
              ? () => _cubit.reset(
                  newPassword: _password.text,
                  confirmPassword: _confirm.text,
                )
              : null,
        ),
      ],
    );
  }

  bool _isEmail(String v) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim());
}

/// Primary lime CTA with a busy spinner, full width.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, softWrap: false),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
    );
  }
}

/// Four single-digit boxes with auto-advance/backspace; reports the joined code.
class _OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _OtpBoxes({required this.onChanged});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
