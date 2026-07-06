import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/lookup/lookup_service.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/auth_card.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../core/widgets/location_picker.dart';
import '../../../../core/widgets/password_requirements.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Sign-up step 2 — "Fill your information" (mirrors dwelleo.sa /register step 2).
/// UI ONLY: collects the personal-info fields and gates "Create Account" on
/// validity. Submission is wired once the real `/auth/register` request/response
/// is captured (see docs/api/REAL_API_SPEC.md). [role] is the account type
/// chosen in step 1 (forwarded as GoRouter extra).
///
/// NOTE: role-specific fields (e.g. company name / license number for
/// developer, agent, broker) must be captured from the live /register form
/// before they are added here — they are intentionally NOT invented.
class SignupFormScreen extends StatefulWidget {
  final String? role;
  const SignupFormScreen({super.key, this.role});

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _district = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();

  String? _city;
  final Set<String> _languages = {};
  bool _agreedTerms = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  double? _locationLat;
  double? _locationLng;

  // Cities loaded from the real backend (/api/v1/lookup).
  List<CityOption> _cities = const [];

  // Phone placeholder follows the selected country (default Saudi).
  String _phoneHint = '5X XXX XXXX';
  String _whatsappHint = '5X XXX XXXX';

  // Selected country dial codes (digits only, no '+'), default Saudi (966).
  // The backend requires phone as "<dial>-<national>" e.g. "20-1024353182".
  String _phoneDial = '966';
  String _whatsappDial = '966';

  // Example national numbers per country ISO code (real formats, common cases).
  static const _phoneExamples = {
    'SA': '5X XXX XXXX',
    'EG': '10 XXXX XXXX',
    'AE': '5X XXX XXXX',
    'KW': 'XXXX XXXX',
    'QA': 'XXXX XXXX',
    'BH': 'XXXX XXXX',
    'OM': 'XXXX XXXX',
    'JO': '7 XXXX XXXX',
    'US': '(201) 555-0123',
    'GB': '7400 123456',
  };
  String _phoneExample(String iso) => _phoneExamples[iso] ?? 'XXXXXXXXX';

  static const _languageOptions = {'ar': 'العربية', 'en': 'English'};

  // Backend language ids (from /api/v1/lookup → languages): English=1, Arabic=2.
  static const _languageIds = {'en': 1, 'ar': 2};

  late final List<TextEditingController> _all = [
    _fullName,
    _email,
    _phone,
    _whatsapp,
    _district,
    _password,
    _confirm,
    _description,
    _location,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_onChanged);
    }
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await sl<LookupService>().cities();
      if (mounted) setState(() => _cities = cities);
    } catch (_) {
      // Non-fatal: the dropdown stays empty; District is free-text anyway.
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isEmail(String v) => RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v);

  bool get _canSubmit =>
      _fullName.text.trim().isNotEmpty &&
      _isEmail(_email.text.trim()) &&
      _phone.text.trim().isNotEmpty &&
      _languages.isNotEmpty &&
      Validators.isStrongPassword(_password.text) &&
      _confirm.text == _password.text &&
      _agreedTerms;

  /// Formats a phone as the backend requires: `<dial>-<national digits>`
  /// e.g. dial 20 + "102 435 3182" → "20-1024353182". Empty if no digits.
  String _fmtPhone(String dial, String raw) {
    final n = raw.replaceAll(RegExp(r'\D'), '');
    return n.isEmpty ? '' : '$dial-$n';
  }

  /// Assembled from the form + the role chosen in step 1. Field contract is
  /// derived from the LIVE backend (not guessed):
  /// Contract verified against the LIVE register endpoint (validation probe):
  ///   • `user_type`       — must be an ARRAY, e.g. ["buyer"] (server: "user
  ///     type must be an array").
  ///   • `languages_spoken`— required ARRAY of language ids, NOT `languages`
  ///     (server listed `languages_spoken`; ids from /lookup: English=1, Arabic=2).
  ///   • `phone`/`whatsapp`— `<dial>-<number>` e.g. "20-1024353182" (confirmed:
  ///     the format passed and hit the "already taken" uniqueness check).
  ///   • `name`,`email`,`password` required; password needs upper+lower+digit,8+.
  Map<String, dynamic> _payload() {
    final whatsapp = _fmtPhone(_whatsappDial, _whatsapp.text);
    final languageIds = _languages
        .map((k) => _languageIds[k])
        .whereType<int>()
        .toList();
    return {
      'user_type': [if (widget.role != null) widget.role],
      'name': _fullName.text.trim(),
      'email': _email.text.trim(),
      'phone': _fmtPhone(_phoneDial, _phone.text),
      if (whatsapp.isNotEmpty) 'whatsapp': whatsapp,
      if (_city != null) 'city': _city,
      if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
      'languages_spoken': languageIds,
      'password': _password.text,
      'password_confirmation': _confirm.text,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_locationLat != null) 'lat': _locationLat,
      if (_locationLng != null) 'lng': _locationLng,
    };
  }

  /// Searchable intl phone field, default Saudi Arabia (+966), like the site.
  /// The placeholder follows the chosen country (e.g. +20 Egypt → '10 XXXX XXXX').
  Widget _phoneInput(
    TextEditingController c,
    String hint,
    ValueChanged<String> onHint,
    ValueChanged<String> onDial,
  ) => IntlPhoneField(
    controller: c,
    initialCountryCode: 'SA',
    disableLengthCheck: true,
    decoration: InputDecoration(hintText: hint),
    onCountryChanged: (country) {
      onHint(_phoneExample(country.code));
      onDial(country.dialCode); // digits only, e.g. "20"
    },
    onChanged: (_) {}, // controller listener already recomputes validity
  );

  Future<void> _pickLocation() async {
    final picked = await showLocationPicker(context);
    if (picked == null) return;
    setState(() {
      _location.text = picked.address;
      _locationLat = picked.lat;
      _locationLng = picked.lng;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            // Account created + OTP sent → go verify (not straight to search).
            context.go(RoutePaths.signupOtp, extra: state.email);
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                ar ? 'انضم إلى دويليو' : 'Join Dwelleo',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                ar ? 'أكمل معلوماتك' : 'Fill your information',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _ProgressHeader(
                label: ar ? 'الخطوة 2 من 2' : 'Step 2 of 2',
                percentLabel: ar ? '100% مكتمل' : '100% Complete',
              ),
              const SizedBox(height: 20),
              AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'المعلومات الشخصية' : 'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: ar ? 'الاسم الكامل' : 'Full Name',
                      required: true,
                      child: TextField(
                        controller: _fullName,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: ar
                              ? 'أدخل اسمك الكامل'
                              : 'Enter your full name',
                        ),
                      ),
                    ),
                    _Field(
                      label: ar ? 'البريد الإلكتروني' : 'Email Address',
                      required: true,
                      child: TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline),
                          hintText: 'your.email@example.com',
                        ),
                      ),
                    ),
                    _Field(
                      label: ar ? 'رقم الجوال' : 'Phone Number',
                      required: true,
                      child: _phoneInput(
                        _phone,
                        _phoneHint,
                        (h) => setState(() => _phoneHint = h),
                        (d) => _phoneDial = d,
                      ),
                    ),
                    _Field(
                      label: ar ? 'رقم واتساب' : 'WhatsApp Number',
                      child: _phoneInput(
                        _whatsapp,
                        _whatsappHint,
                        (h) => setState(() => _whatsappHint = h),
                        (d) => _whatsappDial = d,
                      ),
                    ),
                    _Field(
                      label: ar ? 'المدينة' : 'City',
                      child: DropdownButtonFormField<String>(
                        initialValue: _city,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: ar ? 'اختر المدينة' : 'Select city',
                        ),
                        items: _cities
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _city = v),
                      ),
                    ),
                    _Field(
                      label: ar ? 'الحي' : 'District',
                      child: TextField(
                        controller: _district,
                        decoration: InputDecoration(
                          hintText: ar ? 'أدخل الحي' : 'Enter district',
                        ),
                      ),
                    ),
                    _Field(
                      label: ar ? 'اللغات المفضّلة' : 'Preferred languages',
                      required: true,
                      child: Wrap(
                        spacing: 8,
                        children: _languageOptions.entries.map((e) {
                          final on = _languages.contains(e.key);
                          return FilterChip(
                            label: Text(e.value),
                            selected: on,
                            onSelected: (sel) => setState(() {
                              sel
                                  ? _languages.add(e.key)
                                  : _languages.remove(e.key);
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    _Field(
                      label: ar ? 'كلمة المرور' : 'Password',
                      required: true,
                      child: TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          hintText: ar
                              ? 'أنشئ كلمة مرور قوية'
                              : 'Create a strong password',
                        ),
                      ),
                    ),
                    // Live policy checklist — lights up per rule as the user types.
                    if (_password.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PasswordRequirements(_password.text),
                      ),
                    _Field(
                      label: ar ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      required: true,
                      errorText:
                          _confirm.text.isNotEmpty &&
                              _confirm.text != _password.text
                          ? (ar
                                ? 'كلمتا المرور غير متطابقتين'
                                : 'Passwords do not match')
                          : null,
                      child: TextField(
                        controller: _confirm,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          hintText: ar
                              ? 'أعد إدخال كلمة المرور'
                              : 'Re-enter your password',
                        ),
                      ),
                    ),
                    _Field(
                      label: ar ? 'الوصف' : 'Description',
                      child: TextField(
                        controller: _description,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: ar
                              ? 'أدخل وصفك هنا'
                              : 'Enter your description here',
                        ),
                      ),
                    ),
                    _Field(
                      label: ar ? 'الموقع' : 'Location',
                      child: TextField(
                        controller: _location,
                        readOnly: true,
                        onTap: _pickLocation,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location),
                            tooltip: ar ? 'استخدم موقعي' : 'Use my location',
                            onPressed: _pickLocation,
                          ),
                          hintText: ar
                              ? 'أدخل موقعك هنا'
                              : 'Enter your location here',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _agreedTerms,
                            onChanged: (v) =>
                                setState(() => _agreedTerms = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: ar ? 'أوافق على ' : 'I agree to the ',
                                ),
                                TextSpan(
                                  text: ar
                                      ? 'شروط الخدمة وسياسة الخصوصية'
                                      : 'Terms of Service and Privacy Policy',
                                  style: TextStyle(color: scheme.primary),
                                ),
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Previous is secondary → smaller footprint.
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            // Phase 1 (role) was reached with go() which replaces
                            // the stack, so pop() is a no-op. Go back explicitly.
                            onPressed: () => context.go(RoutePaths.signupRole),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(ar ? 'السابق' : 'Previous'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Create Account is the primary CTA → more room, one line.
                        Expanded(
                          flex: 3,
                          child: BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, authState) {
                              final loading = authState is AuthLoading;
                              return FilledButton(
                                onPressed: (_canSubmit && !loading)
                                    ? () => context.read<AuthCubit>().register(
                                        _payload(),
                                        email: _email.text.trim(),
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
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          ar ? 'إنشاء حساب' : 'Create Account',
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // "Already have an account? Sign In" → login (mirrors the site).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ar ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                        ),
                        TextButton(
                          onPressed: () => context.go(RoutePaths.login),
                          child: Text(ar ? 'تسجيل الدخول' : 'Sign In'),
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

/// Labelled form row with an optional required-asterisk and inline error.
class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final String? errorText;
  final Widget child;
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : null,
            ),
            // §2/§5: labels muted (onSurfaceVariant ≈ white@60%), 14/400.
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-segment progress bar + percent label for the 2-step sign-up.
class _ProgressHeader extends StatelessWidget {
  final String label;
  final String percentLabel;
  const _ProgressHeader({required this.label, required this.percentLabel});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _bar(accent)),
            const SizedBox(width: 8),
            Expanded(child: _bar(accent)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              percentLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bar(Color color) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
