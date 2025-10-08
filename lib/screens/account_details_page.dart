import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  int _genderIndex = 1; // 0 = Bí mật, 1 = Nam, 2 = Nữ
  bool _saving = false;
  String? _imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (prefs.getString('profile_name') ?? '').isEmpty) {
      _nameCtrl.text = user.displayName ?? '';
    } else {
      _nameCtrl.text =
          prefs.getString('profile_name') ?? (user?.displayName ?? '');
    }
    _phoneCtrl.text = prefs.getString('profile_phone') ?? '';
    _yearCtrl.text = prefs.getString('profile_year') ?? '';
    final g = prefs.getString('profile_gender') ?? 'Nam';
    _genderIndex = (g == 'Nam') ? 1 : (g == 'Nữ' ? 2 : 0);
    _imagePath = prefs.getString('profile_image');
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        final path = picked.path;
        setState(() => _imagePath = path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final year = _yearCtrl.text.trim();
    final gender = _genderIndex == 1
        ? 'Nam'
        : (_genderIndex == 2 ? 'Nữ' : 'Bí mật');

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', name);
      await prefs.setString('profile_phone', phone);
      await prefs.setString('profile_year', year);
      await prefs.setString('profile_gender', gender);
      if (_imagePath != null) {
        await prefs.setString('profile_image', _imagePath!);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.displayName != name) {
        await user.updateDisplayName(name);
        await user.reload();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu thông tin thành công')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final genderLabels = ['Bí mật', 'Nam', 'Nữ'];
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _imagePath != null
                        ? FileImage(File(_imagePath!))
                        : null,
                    child: _imagePath == null
                        ? const Icon(Icons.person, size: 44, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Năm sinh'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Giới tính:'),
                const SizedBox(width: 12),
                ToggleButtons(
                  isSelected: List.generate(3, (i) => i == _genderIndex),
                  onPressed: (i) => setState(() => _genderIndex = i),
                  borderRadius: BorderRadius.circular(8),
                  children: genderLabels
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(t),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
