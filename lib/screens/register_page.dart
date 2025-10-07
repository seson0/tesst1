import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { owner, renter }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  UserRole? _selectedRole = UserRole.renter;
  bool _loading = false;
  String? _error;

  String _roleLabel(UserRole role) =>
      role == UserRole.owner ? 'Làm chủ sân' : 'Người thuê sân';

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Vui lòng điền email và mật khẩu');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    if (_selectedRole == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn vai trò')));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/login',
        arguments: {
          'fromRegister': true,
          'role': _selectedRole == UserRole.owner ? 'owner' : 'renter',
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Role selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn là:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<UserRole>(
                    title: Text(_roleLabel(UserRole.owner)),
                    value: UserRole.owner,
                    groupValue: _selectedRole,
                    onChanged: (v) => setState(() => _selectedRole = v),
                  ),
                  RadioListTile<UserRole>(
                    title: Text(_roleLabel(UserRole.renter)),
                    value: UserRole.renter,
                    groupValue: _selectedRole,
                    onChanged: (v) => setState(() => _selectedRole = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                ),
              ),

              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
