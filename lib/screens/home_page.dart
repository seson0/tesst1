import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'account_details_page.dart'; // thêm import tương đối nếu cần
import 'add_court_page.dart'; // import trang thêm sân
import 'edit_court_page.dart';

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
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // mở trang chi tiết quản lý sân (stub)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(court['name'])),
                      body: Center(child: Text('Quản lý: ${court['name']}')),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
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
                              // Flexible cho phép phần badge giãn/thu theo không gian còn lại
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
                                          style: const TextStyle(fontSize: 12),
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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () async {
                            // mở trang sửa sân, truyền dữ liệu sân hiện tại
                            final changed = await Navigator.push<bool?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCourtPage(court: court),
                              ),
                            );
                            if (changed == true) {
                              // nếu sửa thành công, thông báo và (tuỳ cần) refresh UI
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật sân (demo)'),
                                ),
                              );
                              // Nếu bạn load danh sách từ SharedPreferences, gọi setState để refresh ở đây.
                            }
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            // xử lý menu
                            if (v == 'delete') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Xoá ${court['name']} (demo)'),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'manage',
                              child: Text('Quản lý chi tiết'),
                            ),
                            const PopupMenuItem(
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
          // mở trang Thêm sân (form đầy đủ)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCourtPage()),
          ).then((_) {
            // nếu muốn refresh danh sách courts từ prefs, có thể setState ở đây
          });
        },
        label: const Text('Thêm sân'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class OwnerBookingsPage extends StatelessWidget {
  const OwnerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đặt sân')),
      body: const Center(child: Text('Quản lý các đặt sân của chủ sân')),
    );
  }
}

class OwnerStatsPage extends StatelessWidget {
  const OwnerStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: const Center(child: Text('Thống kê doanh thu / lượt đặt (owner)')),
    );
  }
}
