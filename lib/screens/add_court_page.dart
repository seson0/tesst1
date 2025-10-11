import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCourtPage extends StatefulWidget {
  const AddCourtPage({super.key});

  @override
  State<AddCourtPage> createState() => _AddCourtPageState();
}

class _AddCourtPageState extends State<AddCourtPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _active = true;
  bool _saving = false;

  // --- Dropdown loại môn thể thao ---
  String? _selectedType;
  final List<String> _courtTypes = [
    'Bóng đá',
    'Bóng rổ',
    'Bóng bàn',
    'Quần vợt',
  ];

  // --- Dropdown loại sân theo số người ---
  String? _selectedSize;
  final List<String> _courtSizes = [
    'Sân 5 người',
    'Sân 7 người',
    'Sân 11 người',
  ];

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() => _images = picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  Future<void> _saveCourt() async {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sân')),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại môn thể thao')),
      );
      return;
    }

    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại sân theo số người')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('demo_courts') ?? <String>[];

      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'ward': _wardCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'active': _active,
        'type': _selectedType, // 🔹 loại môn thể thao
        'size': _selectedSize, // 🔹 loại sân theo số người
        'imagePaths': _images.map((x) => x.path).toList(),
      };

      existing.add(jsonEncode(item));
      await prefs.setStringList('demo_courts', existing);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu sân (demo)')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _wardCtrl.dispose();
    _cityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sân'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Phần chọn nhiều ảnh ---
            GestureDetector(
              onTap: _pickImages,
              child: _images.isEmpty
                  ? Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Chọn nhiều ảnh sân',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._images.map(
                          (img) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(img.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () {
                                    setState(() =>
                                        _images.removeWhere((x) => x == img));
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Nút thêm ảnh nữa
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.add_a_photo,
                                color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // --- Dropdown chọn loại môn thể thao ---
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _courtTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'Loại môn thể thao',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 12),

            // --- Dropdown chọn loại sân theo số người ---
            DropdownButtonFormField<String>(
              value: _selectedSize,
              items: _courtSizes
                  .map(
                    (size) => DropdownMenuItem(
                      value: size,
                      child: Text(size),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'Loại sân (số người)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _selectedSize = value);
              },
            ),
            const SizedBox(height: 12),

            // --- Các trường nhập liệu khác ---
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên sân'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wardCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Phường/Xã'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Tỉnh/Thành phố'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Giá (vnđ/giờ)'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Kích hoạt sân'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveCourt,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu sân'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
