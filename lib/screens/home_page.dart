import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'account_details_page.dart'; // thêm import tương đối nếu cần

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

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        initialActiveIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: items,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sân')),
      body: const Center(child: Text('Danh sách và quản lý sân (owner)')),
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
