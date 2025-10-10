import 'package:flutter/material.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

class OwnerCourtDetailPage extends StatelessWidget {
  final Map<String, dynamic> court;
  const OwnerCourtDetailPage({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu nhiều ảnh
    final List<String> images = court['images'] ?? [
      'https://suachualaptop24h.com/upload_images/images/2024/08/06/hinh-nen-san-bong-dep-banner.jpg',
      'https://img.lovepik.com/photo/60217/7284.jpg_wh860.jpg',
      'https://watermark.lovepik.com/photo/20211126/large/lovepik-football-field-aerial-photography-picture_501100180.jpg',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(court['name'] ?? 'Chi tiết sân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Hiển thị ảnh chính + nút xem nhiều ảnh ---
            GestureDetector(
              onTap: () {
                showImageViewerPager(
                  context,
                  MultiImageProvider(
                    images.map((e) => Image.network(e).image).toList(),
                  ),
                  swipeDismissible: true,
                  doubleTapZoomable: true,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              court['name'] ?? 'Sân không rõ tên',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              court['description'] ?? 'Chưa có mô tả cho sân này.',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24),
            Text(
              '🏷 Giá thuê: ${court['price'] ?? "Chưa có"} VNĐ/giờ',
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              '📍 Địa chỉ: ${court['address'] ?? "Chưa có địa chỉ"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Phường/Xã: ${court['ward'] ?? "Chưa có"}',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24),
            Text(
              'Tình trạng: Đã đặt ${court['booked'] ?? 0}/${court['capacity'] ?? 0} sân',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
