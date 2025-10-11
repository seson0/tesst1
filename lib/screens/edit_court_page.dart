import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditCourtPage extends StatefulWidget {
  final Map<String, dynamic> court;
  const EditCourtPage({super.key, required this.court});

  @override
  State<EditCourtPage> createState() => _EditCourtPageState();
}

class _EditCourtPageState extends State<EditCourtPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _wardCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _priceCtrl;

  bool _active = true;
  bool _saving = false;

  // --- Thêm biến cho dropdown ---
  String? _selectedType;
  String? _selectedSizeType;

  final List<String> _courtTypes = [
    'Bóng đá',
    'Bóng rổ',
    'Bóng bàn',
    'Quần vợt',
  ];

  final List<String> _sizeTypes = [
    'Sân 5 người',
    'Sân 7 người',
    'Sân 11 người',
  ];

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    final c = widget.court;
    _nameCtrl = TextEditingController(text: c['name'] ?? '');
    _descCtrl = TextEditingController(text: c['description'] ?? '');
    _addressCtrl = TextEditingController(text: c['address'] ?? '');
    _wardCtrl = TextEditingController(text: c['ward'] ?? '');
    _cityCtrl = TextEditingController(text: c['city'] ?? '');
    _priceCtrl = TextEditingController(text: c['price']?.toString() ?? '');
    _active = (c['active'] ?? true) as bool;

    // 🔹 Lấy giá trị loại sân và loại sân theo số người (nếu có)
    _selectedType = c['type']?.toString();
    _selectedSizeType = c['sizeType']?.toString();

    // Lấy danh sách ảnh
    if (c['imagePaths'] != null && c['imagePaths'] is List) {
      _imagePaths = List<String>.from(c['imagePaths']);
    } else if (c['imagePath'] != null) {
      _imagePaths = [c['imagePath'].toString()];
    } else {
      _imagePaths = [];
    }
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(picked.map((e) => e.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _saveEdit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sân')),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại sân')),
      );
      return;
    }

    if (_selectedSizeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại sân theo số người')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('demo_courts') ?? <String>[];

      final updatedItem = {
        'id': widget.court['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'ward': _wardCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'active': _active,
        'type': _selectedType, // 🔹 loại sân
        'sizeType': _selectedSizeType, // 🔹 loại sân theo số người
        'imagePaths': _imagePaths,
      };

      bool updated = false;
      for (var i = 0; i < stored.length; i++) {
        try {
          final m = jsonDecode(stored[i]) as Map<String, dynamic>;
          if (m['id'] == updatedItem['id']) {
            stored[i] = jsonEncode(updatedItem);
            updated = true;
            break;
          }
        } catch (_) {}
      }

      if (!updated) stored.add(jsonEncode(updatedItem));
      await prefs.setStringList('demo_courts', stored);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thay đổi (demo)')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu: $e')),
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
        title: const Text('Sửa sân'),
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
            // --- Hiển thị nhiều ảnh ---
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePaths.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _imagePaths.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey),
                      ),
                    );
                  }
                  final path = _imagePaths[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // --- Dropdown chọn loại sân ---
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
                labelText: 'Loại sân',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 12),

            // --- Dropdown chọn loại sân theo số người ---
            DropdownButtonFormField<String>(
              value: _selectedSizeType,
              items: _sizeTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'Loại sân theo số người',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _selectedSizeType = value),
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
                onPressed: _saving ? null : _saveEdit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
