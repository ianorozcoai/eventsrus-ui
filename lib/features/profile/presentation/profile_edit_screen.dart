import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/state/auth_controller.dart';
import '../data/models/user_profile.dart';
import '../data/user_api.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobileNumber.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _state.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await context.read<UserApi>().getProfile();
      if (!mounted) return;
      _firstName.text = profile.firstName;
      _lastName.text = profile.lastName;
      _email.text = profile.email;
      _mobileNumber.text = profile.mobileNumber;
      _addressLine1.text = profile.addressLine1 ?? '';
      _addressLine2.text = profile.addressLine2 ?? '';
      _city.text = profile.city ?? '';
      _state.text = profile.state ?? '';
      _postalCode.text = profile.postalCode ?? '';
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final response = await context.read<UserApi>().updateProfile(UserProfile(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            mobileNumber: _mobileNumber.text.trim(),
            addressLine1: _addressLine1.text.trim(),
            addressLine2: _addressLine2.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            postalCode: _postalCode.text.trim(),
          ));
      if (!mounted) return;
      // The backend reissues a token since email (the JWT subject) may have
      // changed - the cached session must be updated to match, or the next
      // API call could fail to resolve the user.
      await context.read<AuthController>().applyAuthResponse(response);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _firstName,
                          decoration: const InputDecoration(labelText: 'First name'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastName,
                          decoration: const InputDecoration(labelText: 'Last name'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: _requiredEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mobileNumber,
                          decoration: const InputDecoration(labelText: 'Mobile number'),
                          keyboardType: TextInputType.phone,
                          validator: _required,
                        ),
                        const SizedBox(height: 24),
                        Text('Address', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressLine1,
                          decoration: const InputDecoration(labelText: 'Address line 1'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressLine2,
                          decoration: const InputDecoration(labelText: 'Address line 2'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _state,
                          decoration: const InputDecoration(labelText: 'Province/State'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _postalCode,
                          decoration: const InputDecoration(labelText: 'Postal code'),
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requiredEmail(String? value) {
    final required = _required(value);
    if (required != null) return required;
    return value!.contains('@') ? null : 'Enter a valid email';
  }
}
