import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'account_details_page.dart'; // thêm import tương đối nếu cần
import 'add_court_page.dart'; // import trang thêm sân
import 'edit_court_page.dart';
import 'owner_court_detail_page.dart';


class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  String? _role; // 'owner' or 'renter' (null = treat as renter)

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _role = prefs.getString('user_role') ?? 'renter');
  }

  // callback để truyền xuống AccountPage: khi quay lại từ login/register hoặc logout sẽ gọi để refresh UI
  void _onRoleChanged() => _loadRole();

  @override
  Widget build(BuildContext context) {
    final isOwner = _role == 'owner';

    // define pages per role
    final pages = isOwner
        ? <Widget>[
            const OwnerManageCourtsPage(),
            const OwnerBookingsPage(),
            const OwnerStatsPage(),
            AccountPage(onRoleChanged: _onRoleChanged),
          ]
        : <Widget>[
            const HomeContent(),
            const SearchPage(),
            const BookingsPage(),
            AccountPage(onRoleChanged: _onRoleChanged),
          ];

    // bottom items per role
    final items = isOwner
        ? <TabItem>[
            const TabItem(
              icon: Icons.store_mall_directory,
              title: 'Quản lý sân',
            ),
            const TabItem(icon: Icons.book_online, title: 'Quản lý đặt sân'),
            const TabItem(icon: Icons.bar_chart, title: 'Thống kê'),
            const TabItem(icon: Icons.person, title: 'Tài khoản'),
          ]
        : <TabItem>[
            const TabItem(icon: Icons.home, title: 'Trang chủ'),
            const TabItem(icon: Icons.search, title: 'Tìm kiếm'),
            const TabItem(icon: Icons.history, title: 'Lịch sử'),
            const TabItem(icon: Icons.person, title: 'Tài khoản'),
          ];

    final safeIndex = _currentIndex < pages.length ? _currentIndex : 0;

    // build icon+label data to generate TabItem dynamically
    final barItems = isOwner
        ? [
            {'icon': Icons.store_mall_directory, 'label': 'Quản lý sân'},
            {'icon': Icons.book_online, 'label': 'Quản lý đặt sân'},
            {'icon': Icons.bar_chart, 'label': 'Thống kê'},
            {'icon': Icons.person, 'label': 'Tài khoản'},
          ]
        : [
            {'icon': Icons.home, 'label': 'Trang chủ'},
            {'icon': Icons.search, 'label': 'Tìm kiếm'},
            {'icon': Icons.history, 'label': 'Lịch sử'},
            {'icon': Icons.person, 'label': 'Tài khoản'},
          ];

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),

      // ConvexAppBar nhưng "responsive": nếu không đủ chỗ sẽ ẩn title,
      // nếu đủ chỗ sẽ hiển thị title đầy đủ. (Giải pháp dùng LayoutBuilder để
      // mô phỏng hành vi Flexible cho các item của ConvexAppBar.)
      bottomNavigationBar: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemCount = barItems.length;
            final widthPerItem = totalWidth / itemCount;

            // threshold để hiển thị title — điều chỉnh nếu cần
            const minWidthForTitle = 88.0;
            final showTitle = widthPerItem >= minWidthForTitle;

            // nếu title dài mà vẫn muốn giữ, có thể cắt ngắn với ellipsis
            String shortLabel(String label, double maxWidth) {
              // approx char count allowed (very rough): 7 px per char
              final approxChars = (maxWidth / 7).floor();
              if (label.length <= approxChars) return label;
              if (approxChars <= 3) return '';
              return label.substring(0, approxChars - 1) + '…';
            }

            final tabItems = List<TabItem>.generate(itemCount, (i) {
              final item = barItems[i];
              final rawLabel = item['label'] as String;
              final title = showTitle
                  ? shortLabel(rawLabel, widthPerItem - 16)
                  : '';
              return TabItem(icon: item['icon'] as IconData, title: title);
            });

            return ConvexAppBar(
              style: TabStyle.react,
              initialActiveIndex: safeIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: tabItems,
              backgroundColor: Colors.white,
              activeColor: Theme.of(context).primaryColor,
              color: Colors.grey[600],
            );
          },
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chính'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // xóa role khi sign out để UI quay lại mặc định renter/không đăng nhập
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_role');
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Center(child: Text('Xin chào ${user?.email ?? 'người dùng'}')),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Tìm kiếm sân')),
            SizedBox(height: 16),
            Expanded(
              child: Center(child: Text('Kết quả tìm kiếm sẽ hiển thị ở đây')),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch thuê sân')),
      body: const Center(child: Text('Danh sách lịch thuê sẽ hiển thị ở đây')),
    );
  }
}

// AccountPage now accepts an optional onRoleChanged callback to refresh AppShell when user logs in/out or registers
class AccountPage extends StatelessWidget {
  final VoidCallback? onRoleChanged;
  const AccountPage({super.key, this.onRoleChanged});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Cấu hình ứng dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                await Navigator.pushNamed(context, '/settings');
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng chưa được triển khai'),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Hướng dẫn sử dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                await Navigator.pushNamed(context, '/guide');
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng chưa được triển khai'),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(user == null ? 'Đăng nhập' : 'Thông tin tài khoản'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (!context.mounted) return;
              if (user == null) {
                Navigator.pushNamed(
                  context,
                  '/login',
                ).then((_) => onRoleChanged?.call());
              } else {
                // mở trang chỉnh sửa thông tin (nhỏ)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountDetailsPage()),
                ).then((_) => onRoleChanged?.call());
              }
            },
          ),
          const Divider(height: 1),
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_role');
                  onRoleChanged?.call();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Đăng xuất'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// -------------------- Owner pages (stubs) --------------------


class OwnerManageCourtsPage extends StatelessWidget {
  const OwnerManageCourtsPage({super.key});

  // dữ liệu mẫu — thay bằng dữ liệu thật từ server/Firebase khi có
  final List<Map<String, dynamic>> _sampleCourts = const [
    {
      'id': 'c1',
      'name': 'Sân Nhà Thi Đấu A',
      'subtitle': 'Sân cỏ nhân tạo · 2 sân · 50.000đ/giờ',
      'booked': 12,
      'capacity': 20,
      'image':
          'https://suachualaptop24h.com/upload_images/images/2024/08/06/hinh-nen-san-bong-dep-banner.jpg',
    },
    {
      'id': 'c2',
      'name': 'Sân Bóng Đêm Xanh',
      'subtitle': 'Sân cỏ · 1 sân · 70.000đ/giờ',
      'booked': 5,
      'capacity': 10,
      'image': 'https://img.lovepik.com/photo/60217/7284.jpg_wh860.jpg',
    },
    {
      'id': 'c3',
      'name': 'Sân Trung Tâm 3',
      'subtitle': 'Sân mini · 3 sân · 40.000đ/giờ',
      'booked': 18,
      'capacity': 30,
      'image':
          'https://watermark.lovepik.com/photo/20211126/large/lovepik-football-field-aerial-photography-picture_501100180.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sân')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _sampleCourts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final court = _sampleCourts[index];
          return GestureDetector(
            onTap: () {
              // Chuyển sang trang chi tiết sân
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerCourtDetailPage(court: court),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Ảnh
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        court['image'],
                        width: 96,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 64,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.white30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Thông tin sân
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            court['subtitle'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Đã đặt ${court['booked']}/${court['capacity']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Hoạt động',
                                          style:
                                              const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Cột thao tác
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final changed = await Navigator.push<bool?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCourtPage(court: court),
                              ),
                            );
                            if (changed == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật sân (demo)'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Xoá ${court['name']} (demo)'),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Xoá'),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCourtPage()),
          );
        },
        label: const Text('Thêm sân'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class OwnerBookingsPage extends StatefulWidget {
  const OwnerBookingsPage({super.key});

  @override
  State<OwnerBookingsPage> createState() => _OwnerBookingsPageState();
}

class _OwnerBookingsPageState extends State<OwnerBookingsPage> {
  String _filter = 'Tất cả';

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 1,
      'customer': 'Hoang Le Huy',
      'email': 'lehuy0569@gmail.com',
      'court': 'Sân 5 người A',
      'date': '2025-06-17',
      'time': '08:00 - 10:00',
      'price': '210.000 VND/giờ',
      'status': 'Đã hủy',
      'note': 'Không có',
    },
    {
      'id': 2,
      'customer': '1032 Lê Huy Hoàng',
      'email': 'lehuy456@gmail.com',
      'court': 'Sân 5 người B',
      'date': '2025-06-17',
      'time': '18:00 - 20:00',
      'price': '190.000 VND/giờ',
      'status': 'Đã xác nhận',
      'note': 'Không có',
    },
    {
      'id': 3,
      'customer': 'lehuynhhoang',
      'email': 'dnn@gmail.com',
      'court': 'Sân 5 người B',
      'date': '2025-06-17',
      'time': '08:00 - 10:00',
      'price': '190.000 VND/giờ',
      'status': 'Chờ duyệt',
      'note': 'cho xin sân',
    },
  ];

  List<Map<String, dynamic>> get _filteredBookings {
    if (_filter == 'Tất cả') return _bookings;
    return _bookings.where((b) => b['status'] == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Chờ duyệt':
        return Colors.orange;
      case 'Đã xác nhận':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // --- Giữ hàm BUILD FILTER bên trong State (để setState và _filter có scope) ---
  Widget _buildFilterButton(String label) {
    final bool selected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        setState(() => _filter = label);
      },
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  // --- Helper xây widget cho cột Thao tác (đặt trong State để dùng setState/context) ---
  Widget _buildActionCell(Map<String, dynamic> b) {
    final status = b['status'] as String;

    // Đã hủy -> ẩn nút (hiện dấu gạch)
    if (status == 'Đã hủy') {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }

    // Đã xác nhận -> chỉ hiện nút Hủy
    if (status == 'Đã xác nhận') {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            tooltip: 'Hủy đơn đặt sân',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hủy đơn đặt sân'),
                  content: Text(
                      'Bạn có chắc muốn hủy đơn đặt sân của khách hàng "${b['customer']}" không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => b['status'] = 'Đã hủy');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đơn đặt sân đã bị hủy.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Xác nhận hủy'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    }

    // Chờ duyệt -> hiển thị cả Xác nhận + Hủy
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          tooltip: 'Xác nhận đặt sân',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xác nhận đặt sân'),
                content: Text(
                    'Bạn có chắc muốn xác nhận đơn đặt sân của khách hàng "${b['customer']}" không?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => b['status'] = 'Đã xác nhận');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đơn đặt sân đã được xác nhận.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          tooltip: 'Hủy đơn đặt sân',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Hủy đơn đặt sân'),
                content: Text(
                    'Bạn có chắc muốn hủy đơn đặt sân của khách hàng "${b['customer']}" không?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => b['status'] = 'Đã hủy');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đơn đặt sân đã bị hủy.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Xác nhận hủy'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý booking'),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng thống kê (demo)')),
              );
            },
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            label: const Text('Thống kê', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Bộ lọc trạng thái
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterButton('Tất cả'),
                _buildFilterButton('Chờ duyệt'),
                _buildFilterButton('Đã xác nhận'),
                _buildFilterButton('Đã hủy'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Khách hàng')),
                  DataColumn(label: Text('Sân')),
                  DataColumn(label: Text('Ngày đặt')),
                  DataColumn(label: Text('Khung giờ')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Ghi chú')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _filteredBookings.map((b) {
                  return DataRow(cells: [
                    DataCell(Text(b['id'].toString())),
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b['customer'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(b['email'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )),
                    DataCell(Text(b['court'])),
                    DataCell(Text(b['date'])),
                    DataCell(Text(b['time'])),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(b['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b['status'],
                        style: TextStyle(color: _statusColor(b['status']), fontWeight: FontWeight.w600),
                      ),
                    )),
                    DataCell(Text(b['note'])),
                    DataCell(_buildActionCell(b)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerStatsPage extends StatelessWidget {
  const OwnerStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả lập — sau này có thể thay bằng dữ liệu thật từ API
    final totalBooking = 3;
    final pending = 0;
    final confirmed = 1;
    final canceled = 2;
    final revenue = 179000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê booking'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Các ô thống kê đầu ---
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatCard('Tổng booking', totalBooking.toString(),
                      Icons.calendar_today, Colors.blue),
                  _buildStatCard('Chờ duyệt', pending.toString(),
                      Icons.access_time, Colors.orange),
                  _buildStatCard('Đã xác nhận', confirmed.toString(),
                      Icons.check_circle, Colors.green),
                  _buildStatCard('Đã huỷ', canceled.toString(),
                      Icons.cancel, Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              // --- Thống kê theo thời gian ---
              const Text(
                'Thống kê theo thời gian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Flexible(child: _TimeStatItem(title: 'Hôm nay', count: 0)),
                      Flexible(child: _TimeStatItem(title: 'Tháng này', count: 3)),
                      Flexible(child: _TimeStatItem(title: 'Tháng trước', count: 0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Doanh thu ---
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doanh thu',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '$revenue VND',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const Flexible(
                            child: Text(
                              'Tổng doanh thu từ booking đã xác nhận',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Phân bố trạng thái booking ---
              const Text(
                'Phân bố trạng thái booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  _buildStatusBar('Chờ duyệt', pending, Colors.orange),
                  _buildStatusBar('Đã xác nhận', confirmed, Colors.green),
                  _buildStatusBar('Đã huỷ', canceled, Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              // --- Hoạt động gần đây ---
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.blueAccent),
                  title: const Text('Không có hoạt động mới'),
                  subtitle: const Text('Cập nhật gần nhất: 19/06/2025 05:27'),
                  trailing: const Text(
                    '+0.0%',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Hàm dựng ô thống kê ---
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Hàm dựng thanh trạng thái ---
  Widget _buildStatusBar(String title, int value, Color color) {
    final total = 3;
    final percent = total > 0 ? (value / total) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${(percent * 100).toStringAsFixed(1)}%)'),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent.toDouble(), // ✅ ép kiểu double để tránh lỗi
            color: color,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

// --- Widget phụ hiển thị thống kê theo thời gian ---
class _TimeStatItem extends StatelessWidget {
  final String title;
  final int count;

  const _TimeStatItem({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('$count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}


