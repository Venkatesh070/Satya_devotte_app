import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_dashboard_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_rituals_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_festivals_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_notifications_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_users_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_analytics_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_approval_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_shlokas_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_admins_content.dart';

// ── Design tokens matching Figma ─────────────────────────────────
class CmsColors {
  static const bg = Color(0xFFFFF8F0); // warm cream background
  static const orange = Color(0xFFF5A623); // primary orange
  static const orangeDark = Color(0xFFE8590A); // darker orange
  static const white = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2D2D2D);
  static const textSecond = Color(0xFF888888);
  static const border = Color(0xFFEEEEEE);
  static const green = Color(0xFF4CAF50);
  static const red = Color(0xFFE53935);
  static const sidebarBg = Color(0xFF1A1A2E);
}

class CmsShellPage extends StatefulWidget {
  const CmsShellPage({super.key});
  @override
  State<CmsShellPage> createState() => _CmsShellPageState();
}

class _CmsShellPageState extends State<CmsShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 768
        ? _WebLayout(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          )
        : _MobileLayout(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          );
  }
}

// ════════════════════════════════════════════════════════════════
// WEB LAYOUT — left sidebar + content
// ════════════════════════════════════════════════════════════════
class _WebLayout extends StatelessWidget {
  const _WebLayout({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CmsColors.bg,
      body: Row(
        children: [
          _Sidebar(selectedIndex: selectedIndex, onSelect: onSelect),
          Expanded(
            child: Column(
              children: [
                _WebTopBar(selectedIndex: selectedIndex),
                Expanded(child: _buildContent(selectedIndex)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MOBILE LAYOUT — matches Figma mobile screens
// ════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: CmsColors.bg,
      appBar: AppBar(
        backgroundColor: CmsColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pageTitle(selectedIndex),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  auth.isSuperAdmin ? 'S' : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _MobileDrawer(selectedIndex: selectedIndex, onSelect: onSelect),
      body: _buildContent(selectedIndex),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SIDEBAR — matches Figma left nav
// ════════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Container(
      width: 220,
      color: CmsColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo area ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Row(
              children: [
                // Satya app logo — same image used on mobile
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/appLogo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: CmsColors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sathya CMS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── Role chip ───────────────────────────────────────
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: auth.isSuperAdmin
                      ? CmsColors.orange.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: auth.isSuperAdmin
                        ? CmsColors.orange.withOpacity(0.4)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  auth.isSuperAdmin ? '⭐ Super Admin' : '👤 Admin',
                  style: TextStyle(
                    color: auth.isSuperAdmin
                        ? CmsColors.orange
                        : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Nav items ───────────────────────────────────────
          Expanded(
            child: Obx(() {
              final items = _navItems(auth.isSuperAdmin);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _SidebarItem(
                  item: items[i],
                  isSelected: selectedIndex == i,
                  onTap: () => onSelect(i),
                ),
              );
            }),
          ),

          // ── Logout ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await Get.find<AuthController>().signOut();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Get.offAllNamed(AppRoutes.login);
                  });
                },
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? CmsColors.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.08),
          splashColor: Colors.white.withOpacity(0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? Colors.white
                      : item.isSpecial
                      ? CmsColors.orange
                      : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : item.isSpecial
                        ? CmsColors.orange
                        : Colors.white60,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MOBILE DRAWER
// ════════════════════════════════════════════════════════════════
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Drawer(
      backgroundColor: CmsColors.sidebarBg,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: CmsColors.sidebarBg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Satya app logo — same image used on mobile
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/appLogo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CmsColors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.self_improvement,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Sathya CMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CmsColors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      auth.isSuperAdmin ? '⭐ Super Admin' : '👤 Admin',
                      style: const TextStyle(
                        color: CmsColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = _navItems(auth.isSuperAdmin);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _SidebarItem(
                  item: items[i],
                  isSelected: selectedIndex == i,
                  onTap: () {
                    onSelect(i);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Get.find<AuthController>().signOut();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAllNamed(AppRoutes.login);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WEB TOP BAR
// ════════════════════════════════════════════════════════════════
class _WebTopBar extends StatelessWidget {
  const _WebTopBar({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: CmsColors.white,
        border: Border(bottom: BorderSide(color: CmsColors.border)),
      ),
      child: Row(
        children: [
          Text(
            _pageTitle(selectedIndex),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CmsColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Search bar
          Container(
            width: 220,
            height: 36,
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: const Row(
              children: [
                SizedBox(width: 10),
                Icon(Icons.search, size: 16, color: Color(0xFFAAAAAA)),
                SizedBox(width: 6),
                Text(
                  'Search...',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Notification bell
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CmsColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CmsColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 18,
              color: CmsColors.textSecond,
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Obx(
            () => Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CmsColors.orange,
                  child: Text(
                    auth.isSuperAdmin ? 'S' : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  auth.isSuperAdmin ? 'Sathya' : 'Admin',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CmsColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// NAV ITEMS DATA
// ════════════════════════════════════════════════════════════════
class _NavItem {
  const _NavItem(
    this.label,
    this.icon,
    this.activeIcon, {
    this.isSpecial = false,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSpecial;
}

List<_NavItem> _navItems(bool isSuperAdmin) => [
  const _NavItem('Dashboard', Icons.grid_view_outlined, Icons.grid_view),
  const _NavItem(
    'Manage Poojas',
    Icons.self_improvement_outlined,
    Icons.self_improvement,
  ),
  const _NavItem(
    'Manage Festivals',
    Icons.celebration_outlined,
    Icons.celebration,
  ),
  const _NavItem(
    'Notifications',
    Icons.notifications_outlined,
    Icons.notifications,
  ),
  const _NavItem('Users', Icons.people_outline, Icons.people),
  const _NavItem('Analytics', Icons.bar_chart_outlined, Icons.bar_chart),
  if (isSuperAdmin) ...[
    const _NavItem(
      'Approvals',
      Icons.check_circle_outline,
      Icons.check_circle,
      isSpecial: true,
    ),
    const _NavItem(
      'Shlokas',
      Icons.menu_book_outlined,
      Icons.menu_book,
      isSpecial: true,
    ),
    const _NavItem(
      'Manage Admins',
      Icons.admin_panel_settings_outlined,
      Icons.admin_panel_settings,
      isSpecial: true,
    ),
  ],
];

String _pageTitle(int i) {
  const titles = [
    'Dashboard',
    'Manage Poojas',
    'Manage Festivals',
    'Notifications',
    'Users',
    'Analytics',
    'Approvals',
    'Shlokas',
    'Manage Admins',
  ];
  return i < titles.length ? titles[i] : 'Dashboard';
}

Widget _buildContent(int i) {
  switch (i) {
    case 0:
      return const CmsDashboardContent();
    case 1:
      return const CmsRitualsContent();
    case 2:
      return const CmsFestivalsContent();
    case 3:
      return const CmsNotificationsContent();
    case 4:
      return const CmsUsersContent();
    case 5:
      return const CmsAnalyticsContent();
    case 6:
      return const CmsApprovalContent();
    // case 7:
    //   return const CmsShlokaContent();
    // case 8:
    //   return const CmsAdminsContent();
    default:
      return const CmsDashboardContent();
  }
}
