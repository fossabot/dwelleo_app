import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_card.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Sign-up step 3 — OTP / Verification Code (HANDOFF §3). Four boxes, Resend,
/// Verify (disabled until 4 digits), Back to Login. The verify/resend endpoints
/// are PENDING a live capture (see AuthRemoteDataSource).
class VerificationCodeScreen extends StatefulWidget {
  final String email;
  const VerificationCodeScreen({super.key, required this.email});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  static const _len = 4;
  late final List<TextEditingController> _boxes = List.generate(
    _len,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(_len, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _boxes.map((c) => c.text).join();
  bool get _complete => _code.length == _len;

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < _len - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ar
                      ? 'تم التحقق. سجّل الدخول للمتابعة.'
                      : 'Verified. Please sign in to continue.',
                ),
              ),
            );
            context.go(RoutePaths.login);
          } else if (state is AuthNotice) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
                ar ? 'رمز التحقق' : 'Verification Code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                ar
                    ? 'أدخل الرمز المكوّن من 4 أرقام المُرسل إلى ${widget.email}'
                    : 'Enter the 4-digit code sent to ${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AuthCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _len; i++) ...[
                          _OtpBox(
                            controller: _boxes[i],
                            focusNode: _nodes[i],
                            onChanged: (v) => _onChanged(i, v),
                          ),
                          if (i < _len - 1) const SizedBox(width: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => context.read<AuthCubit>().resendOtp(
                          email: widget.email,
                        ),
                        child: Text(ar ? 'إعادة إرسال الرمز' : 'Resend Code'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final loading = state is AuthLoading;
                        return FilledButton(
                          onPressed: (_complete && !loading)
                              ? () => context.read<AuthCubit>().verifyOtp(
                                  email: widget.email,
                                  code: _code,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(ar ? 'تحقق من الرمز' : 'Verify Code'),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.login),
                      child: Text(
                        ar ? '← العودة لتسجيل الدخول' : '← Back to Login',
                      ),
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

/// A single OTP digit box; active (focused) box shows an accent border via the
/// theme's focusedBorder.
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(counterText: '', hintText: ''),
      ),
    );
  }
}
