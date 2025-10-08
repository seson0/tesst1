import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    final isOwner = _role == 'owner';

    // define pages per role
    final pages = isOwner
        ? <Widget>[
            const OwnerManageCourtsPage(),
            const OwnerBookingsPage(),
            const OwnerStatsPage(),
            const AccountPage(),
          ]
        : <Widget>[
            const HomeContent(),
            const SearchPage(),
            const BookingsPage(),
            const AccountPage(),
          ];

    // bottom items per role
    final items = isOwner
        ? <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_mall_directory),
              label: 'Quản lý sân',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: 'Quản lý đặt sân',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Thống kê',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ]
        : <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Lịch sử',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ];

    final safeIndex = _currentIndex < pages.length ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        initialActiveIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: isOwner
            ? [
                const TabItem(
                  icon: Icons.store_mall_directory,
                  title: 'Quản lý sân',
                ),
                const TabItem(icon: Icons.book_online, title: 'Đặt sân'),
                const TabItem(icon: Icons.bar_chart, title: 'Thống kê'),
                const TabItem(icon: Icons.person, title: 'Tài khoản'),
              ]
            : [
                const TabItem(icon: Icons.home, title: 'Trang chủ'),
                const TabItem(icon: Icons.search, title: 'Tìm kiếm'),
                const TabItem(icon: Icons.history, title: 'Lịch sử'),
                const TabItem(icon: Icons.person, title: 'Tài khoản'),
              ],
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

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

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
                Navigator.pushNamed(context, '/login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã đăng nhập: ${user.email}')),
                );
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
