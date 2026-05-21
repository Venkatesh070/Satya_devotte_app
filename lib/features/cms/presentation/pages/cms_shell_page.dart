import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/routing/hash_route_sync.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/contents/cms_admin_notifications_content.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/controllers/cms_admin_notifications_controller.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/widgets/cms_activity_bell_button.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_orders_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_dashboard_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_deities_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_puja_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_donations_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_festivals_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_notifications_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_users_content.dart';
// import 'package:satya_devotte_app/features/cms/presentation/contents/cms_analytics_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_shlokas_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_admins_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_manage_rituals_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_orders_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_refunds_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_inventory_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/contents/cms_pooja_kit_payments_content.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_order_requests_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/inventory_controller.dart';

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
  // Sidebar groups that the user has manually expanded. Groups that contain
  // the currently selected leaf are always treated as expanded regardless
  // of this set.
  final Set<String> _expandedGroups = <String>{};
  final ScrollController _sidebarScrollController = ScrollController();
  Timer? _notificationsPollTimer;

  @override
  void initState() {
    super.initState();
    CmsShellNavigation.attach(this);
    final auth = Get.find<AuthController>();
    _selectedIndex = _indexFromRoute(Get.currentRoute, auth.isSuperAdmin);
    if (Get.isRegistered<CmsAdminNotificationsController>()) {
      final ctrl = Get.find<CmsAdminNotificationsController>();
      unawaited(ctrl.refreshUnreadCount());
      _notificationsPollTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => unawaited(ctrl.refreshUnreadCount()),
      );
    }
    // Auto-expand any group that owns the resolved selected index so the
    // sidebar reflects the deep-linked tab on first paint.
    final group = _groupLabelForIndex(_selectedIndex);
    if (group != null) _expandedGroups.add(group);
  }

  @override
  void dispose() {
    _notificationsPollTimer?.cancel();
    CmsShellNavigation.detach(this);
    _sidebarScrollController.dispose();
    super.dispose();
  }

  /// Switches CMS tabs without recreating [CmsShellPage] (preserves sidebar scroll).
  void navigateToTab(int index) => _onSelect(index);

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
      final group = _groupLabelForIndex(index);
      if (group != null) _expandedGroups.add(group);
    });
    // Tab switches only update local state so the shell (and sidebar scroll
    // position) are not recreated via Get.offNamed on every menu click.
    if (index == _NavIds.poojaKitRefunds &&
        Get.isRegistered<AdminOrderRequestsController>()) {
      Get.find<AdminOrderRequestsController>().refresh();
    }
    if (index == _NavIds.poojaKitInventory &&
        Get.isRegistered<InventoryController>()) {
      Get.find<InventoryController>().init();
    }
    if (index == _NavIds.activity &&
        Get.isRegistered<CmsAdminNotificationsController>()) {
      unawaited(Get.find<CmsAdminNotificationsController>().loadFirstPage());
    }
    if (kIsWeb) {
      updateCmsHashRoute(_routeFromIndex(index));
    }
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case _NavIds.deities:
        return AppRoutes.cmsDeities;
      case _NavIds.pujas:
        return AppRoutes.cmsRituals;
      case _NavIds.festivals:
        return AppRoutes.cmsFestivals;
      case _NavIds.donations:
        return AppRoutes.cmsDonations;
      case _NavIds.donationsAll:
        return AppRoutes.cmsDonationsAll;
      case _NavIds.notifications:
        return AppRoutes.cmsNotifications;
      case _NavIds.activity:
        return AppRoutes.cmsActivity;
      case _NavIds.users:
        return AppRoutes.cmsUsers;
      case _NavIds.shlokas:
        return AppRoutes.cmsShlokas;
      case _NavIds.admins:
        return AppRoutes.cmsAdmins;
      case _NavIds.poojaKitInventory:
        return AppRoutes.cmsPoojaKitInventory;
      case _NavIds.poojaKitManage:
        return AppRoutes.cmsPoojaKit;
      case _NavIds.poojaKitOrders:
        return AppRoutes.cmsPoojaKitOrders;
      case _NavIds.poojaKitRefunds:
        return AppRoutes.cmsPoojaKitRefunds;
      case _NavIds.poojaKitPayments:
        return AppRoutes.cmsPoojaKitPayments;
      case _NavIds.manageRituals:
        return AppRoutes.cmsManageRituals;
      case _NavIds.dashboard:
      default:
        return AppRoutes.cms;
    }
  }

  void _onToggleGroup(String label) {
    setState(() {
      if (_expandedGroups.contains(label)) {
        _expandedGroups.remove(label);
      } else {
        _expandedGroups.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        final isDashboardRoute = Get.currentRoute == AppRoutes.cms;
        if (_selectedIndex != 0 || !isDashboardRoute) {
          setState(() => _selectedIndex = 0);
          if (!isDashboardRoute) {
            Get.offNamed(AppRoutes.cms);
          }
          return false;
        }
        // Already on dashboard: consume browser back and stay on CMS.
        return false;
      },
      child: w >= 768
          ? _WebLayout(
              selectedIndex: _selectedIndex,
              onSelect: _onSelect,
              expandedGroups: _expandedGroups,
              onToggleGroup: _onToggleGroup,
              sidebarScrollController: _sidebarScrollController,
            )
          : _MobileLayout(
              selectedIndex: _selectedIndex,
              onSelect: _onSelect,
              expandedGroups: _expandedGroups,
              onToggleGroup: _onToggleGroup,
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WEB LAYOUT — left sidebar + content
// ════════════════════════════════════════════════════════════════
class _WebLayout extends StatelessWidget {
  const _WebLayout({
    required this.selectedIndex,
    required this.onSelect,
    required this.expandedGroups,
    required this.onToggleGroup,
    required this.sidebarScrollController,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleGroup;
  final ScrollController sidebarScrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CmsColors.bg,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
            onSelect: onSelect,
            expandedGroups: expandedGroups,
            onToggleGroup: onToggleGroup,
            scrollController: sidebarScrollController,
          ),
          Expanded(
            child: Column(
              children: [
                _WebTopBar(
                  selectedIndex: selectedIndex,
                  onActivityBellTap: () => onSelect(_NavIds.activity),
                ),
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
  const _MobileLayout({
    required this.selectedIndex,
    required this.onSelect,
    required this.expandedGroups,
    required this.onToggleGroup,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleGroup;

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
      drawer: _MobileDrawer(
        selectedIndex: selectedIndex,
        onSelect: onSelect,
        expandedGroups: expandedGroups,
        onToggleGroup: onToggleGroup,
      ),
      body: _buildContent(selectedIndex),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SIDEBAR — matches Figma left nav
// ════════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.expandedGroups,
    required this.onToggleGroup,
    required this.scrollController,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleGroup;
  final ScrollController scrollController;

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
                  'Sathya',
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
              return ListView(
                key: const PageStorageKey<String>('cms-sidebar-nav'),
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                children: [
                  for (final entry in items)
                    ..._renderEntry(
                      entry,
                      selectedIndex: selectedIndex,
                      expandedGroups: expandedGroups,
                      onSelect: onSelect,
                      onToggleGroup: onToggleGroup,
                    ),
                ],
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
    this.indent = false,
    this.onLight = false,
  });
  final _NavEntry item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool indent;
  // When true the item is rendered on a light (white) surface — used for
  // children of an expanded sidebar group. We flip the foreground colors
  // so the icon/label remain readable against the lighter background.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color labelColor;
    if (isSelected) {
      iconColor = Colors.white;
      labelColor = Colors.white;
    } else if (item.isSpecial) {
      iconColor = CmsColors.orange;
      labelColor = CmsColors.orange;
    } else if (onLight) {
      iconColor = const Color(0xFF4B5563); // slate-600
      labelColor = const Color(0xFF111827); // gray-900
    } else {
      iconColor = Colors.white54;
      labelColor = Colors.white60;
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 2, left: indent ? 18 : 0),
      child: Material(
        color: isSelected ? CmsColors.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: onLight
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.08),
          splashColor: onLight
              ? Colors.black.withOpacity(0.08)
              : Colors.white.withOpacity(0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: iconColor,
                  size: indent ? 16 : 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: indent ? 12.5 : 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (item.index == _NavIds.activity) const CmsActivitySidebarBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Expandable group header (e.g. "Pooja Kit") ────────────────────
class _SidebarGroupHeader extends StatelessWidget {
  const _SidebarGroupHeader({
    required this.entry,
    required this.expanded,
    required this.highlight,
    required this.onTap,
    this.onLight = false,
  });

  final _NavEntry entry;
  final bool expanded;
  // True when a child of this group is currently selected. We tint the
  // header slightly so the user knows their selection lives inside it
  // even when the group is collapsed for some reason.
  final bool highlight;
  final VoidCallback onTap;
  // When true the header sits on a white surface (the expanded-group panel)
  // and needs dark-on-light foreground colors.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (highlight) {
      color = CmsColors.orange;
    } else if (entry.isSpecial) {
      color = CmsColors.orange;
    } else if (onLight) {
      color = const Color(0xFF111827); // gray-900
    } else {
      color = Colors.white60;
    }
    final hoverColor = onLight
        ? Colors.black.withOpacity(0.05)
        : Colors.white.withOpacity(0.08);
    final splashColor = onLight
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: highlight ? CmsColors.orange.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: hoverColor,
          splashColor: splashColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(
                  expanded ? entry.activeIcon : entry.icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: (highlight || onLight)
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns: expanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: color,
                    size: 18,
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

// Render either a single sidebar leaf or an expandable group + its visible
// children. Shared by [_Sidebar] and [_MobileDrawer].
List<Widget> _renderEntry(
  _NavEntry entry, {
  required int selectedIndex,
  required Set<String> expandedGroups,
  required ValueChanged<int> onSelect,
  required ValueChanged<String> onToggleGroup,
  VoidCallback? onSelectExtra,
}) {
  if (entry.isGroup) {
    final children = entry.children ?? const <_NavEntry>[];
    final hasSelectedChild = children.any((c) => c.index == selectedIndex);
    // A group is rendered expanded when the user manually expanded it OR
    // when one of its children is the active tab.
    final expanded = hasSelectedChild || expandedGroups.contains(entry.label);

    if (!expanded) {
      return [
        _SidebarGroupHeader(
          entry: entry,
          expanded: false,
          highlight: hasSelectedChild,
          onTap: () => onToggleGroup(entry.label),
        ),
      ];
    }

    // Expanded → render header + children together on a light surface so
    // the active section visually pops out of the dark sidebar.
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarGroupHeader(
                entry: entry,
                expanded: true,
                highlight: hasSelectedChild,
                onTap: () => onToggleGroup(entry.label),
                onLight: true,
              ),
              for (final child in children)
                _SidebarItem(
                  item: child,
                  isSelected: child.index == selectedIndex,
                  indent: true,
                  onLight: true,
                  onTap: () {
                    if (child.index != null) onSelect(child.index!);
                    onSelectExtra?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    ];
  }
  return [
    _SidebarItem(
      item: entry,
      isSelected: entry.index == selectedIndex,
      onTap: () {
        if (entry.index != null) onSelect(entry.index!);
        onSelectExtra?.call();
      },
    ),
  ];
}

// ════════════════════════════════════════════════════════════════
// MOBILE DRAWER
// ════════════════════════════════════════════════════════════════
class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.selectedIndex,
    required this.onSelect,
    required this.expandedGroups,
    required this.onToggleGroup,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleGroup;

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
                      'Sathya',
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
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                children: [
                  for (final entry in items)
                    ..._renderEntry(
                      entry,
                      selectedIndex: selectedIndex,
                      expandedGroups: expandedGroups,
                      onSelect: onSelect,
                      onToggleGroup: onToggleGroup,
                      // Close the drawer when the user taps any leaf, but
                      // leave it open when they just toggle a group header
                      // so they can pick a sub-tab without re-opening it.
                      onSelectExtra: () => Navigator.pop(context),
                    ),
                ],
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
  const _WebTopBar({
    required this.selectedIndex,
    required this.onActivityBellTap,
  });
  final int selectedIndex;
  final VoidCallback onActivityBellTap;

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
          CmsActivityBellButton(onTap: onActivityBellTap),
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
//
// A nav entry is either a selectable leaf (`index` set) or an expandable
// group header (`children` non-empty, `index` null). Indices are the
// single source of truth used by `_pageTitle`, `_buildContent` and the
// route mapping helpers, so adding a new tab no longer depends on its
// position in the sidebar list.
class _NavEntry {
  const _NavEntry({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.index,
    this.children,
    this.isSpecial = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int? index;
  final List<_NavEntry>? children;
  final bool isSpecial;

  bool get isGroup =>
      children != null && children!.isNotEmpty;
}

/// Stable index assignments. Keep these in sync with `_pageTitle`,
/// `_buildContent` and `_indexFromRoute` below.
class _NavIds {
  static const int dashboard = 0;
  static const int deities = 1;
  static const int pujas = 2;
  static const int festivals = 3;
  static const int donations = 4;
  static const int notifications = 5;
  static const int users = 6;
  // Hidden from side menu for now.
  // static const int analytics = 7;
  // Super admin only.
  static const int shlokas = 8;
  static const int admins = 9;
  // Pooja Kit group children.
  static const int poojaKitInventory = 16;
  static const int poojaKitManage = 10;
  static const int poojaKitOrders = 11;
  // Donations group children. `donations` (4) is kept as "Manage Donations"
  // so existing routes / deep links continue to work.
  static const int donationsAll = 12;
  // Top-level "Manage Rituals" tab (distinct from `pujas` which is the
  // historical "Manage Pujas" entry).
  static const int manageRituals = 13;
  // Pooja Kit group child for refunds.
  static const int poojaKitRefunds = 14;
  // Pooja Kit group child for payments.
  static const int poojaKitPayments = 15;
  static const int activity = 17;
}

const String _poojaKitGroupLabel = 'Ecommerce';
const String _donationsGroupLabel = 'Donations';

List<_NavEntry> _navItems(bool isSuperAdmin) => [
  const _NavEntry(
    label: 'Dashboard',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view,
    index: _NavIds.dashboard,
  ),
  const _NavEntry(
    label: 'Manage Deities',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome,
    index: _NavIds.deities,
  ),
  const _NavEntry(
    label: 'Manage Pujas',
    icon: Icons.self_improvement_outlined,
    activeIcon: Icons.self_improvement,
    index: _NavIds.pujas,
  ),
  const _NavEntry(
    label: 'Manage Rituals',
    icon: Icons.local_fire_department_outlined,
    activeIcon: Icons.local_fire_department,
    index: _NavIds.manageRituals,
  ),
  const _NavEntry(
    label: 'Manage Festivals',
    icon: Icons.celebration_outlined,
    activeIcon: Icons.celebration,
    index: _NavIds.festivals,
  ),
  const _NavEntry(
    label: _donationsGroupLabel,
    icon: Icons.volunteer_activism_outlined,
    activeIcon: Icons.volunteer_activism,
    children: [
      _NavEntry(
        label: 'Manage Donations',
        icon: Icons.volunteer_activism_outlined,
        activeIcon: Icons.volunteer_activism,
        index: _NavIds.donations,
      ),
      _NavEntry(
        label: 'All Donations',
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt,
        index: _NavIds.donationsAll,
      ),
    ],
  ),
  const _NavEntry(
    label: _poojaKitGroupLabel,
    icon: Icons.shopping_basket_outlined,
    activeIcon: Icons.shopping_basket,
    children: [
      _NavEntry(
        label: 'Manage Inventory',
        icon: Icons.warehouse_outlined,
        activeIcon: Icons.warehouse,
        index: _NavIds.poojaKitInventory,
      ),
      _NavEntry(
        label: 'Manage Puja Kit',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        index: _NavIds.poojaKitManage,
      ),
      _NavEntry(
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        index: _NavIds.poojaKitOrders,
      ),
      _NavEntry(
        label: 'Replace Requests',
        icon: Icons.assignment_return_outlined,
        activeIcon: Icons.assignment_return,
        index: _NavIds.poojaKitRefunds,
      ),
      _NavEntry(
        label: 'Payments',
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments,
        index: _NavIds.poojaKitPayments,
      ),
    ],
  ),
  const _NavEntry(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    index: _NavIds.notifications,
  ),
  const _NavEntry(
    label: 'Activity',
    icon: Icons.notifications_active_outlined,
    activeIcon: Icons.notifications_active,
    index: _NavIds.activity,
  ),
  const _NavEntry(
    label: 'Users',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    index: _NavIds.users,
  ),
  // Analytics — hidden from side menu for now.
  // const _NavEntry(
  //   label: 'Analytics',
  //   icon: Icons.bar_chart_outlined,
  //   activeIcon: Icons.bar_chart,
  //   index: _NavIds.analytics,
  // ),
  if (isSuperAdmin) ...[
    const _NavEntry(
      label: 'Shlokas',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      index: _NavIds.shlokas,
      isSpecial: true,
    ),
    const _NavEntry(
      label: 'Manage Admins',
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings,
      index: _NavIds.admins,
      isSpecial: true,
    ),
  ],
];

/// Returns the sidebar group label that owns [index], or null if the
/// index belongs to a top-level leaf. Used to auto-expand the matching
/// group when a child tab is selected.
String? _groupLabelForIndex(int index) {
  switch (index) {
    case _NavIds.poojaKitInventory:
    case _NavIds.poojaKitManage:
    case _NavIds.poojaKitOrders:
    case _NavIds.poojaKitRefunds:
    case _NavIds.poojaKitPayments:
      return _poojaKitGroupLabel;
    case _NavIds.donations:
    case _NavIds.donationsAll:
      return _donationsGroupLabel;
    default:
      return null;
  }
}

String _pageTitle(int i) {
  switch (i) {
    case _NavIds.dashboard:
      return 'Dashboard';
    case _NavIds.deities:
      return 'Manage Deities';
    case _NavIds.pujas:
      return 'Manage Pujas';
    case _NavIds.festivals:
      return 'Manage Festivals';
    case _NavIds.donations:
      return 'Manage Donations';
    case _NavIds.donationsAll:
      return 'All Donations';
    case _NavIds.notifications:
      return 'Notifications';
    case _NavIds.activity:
      return 'Activity';
    case _NavIds.users:
      return 'Users';
    // case _NavIds.analytics:
    //   return 'Analytics';
    case _NavIds.shlokas:
      return 'Shlokas';
    case _NavIds.admins:
      return 'Manage Admins';
    case _NavIds.poojaKitInventory:
      return 'Manage Inventory';
    case _NavIds.poojaKitManage:
      return 'Manage Puja Kit';
    case _NavIds.poojaKitOrders:
      return 'Puja Kit Orders';
    case _NavIds.poojaKitRefunds:
      return 'Replace Requests';
    case _NavIds.poojaKitPayments:
      return 'Puja Kit Payments';
    case _NavIds.manageRituals:
      return 'Manage Rituals';
    default:
      return 'Dashboard';
  }
}

Widget _buildContent(int i) {
  switch (i) {
    case _NavIds.dashboard:
      return const CmsDashboardContent();
    case _NavIds.deities:
      return const CmsDeitiesContent();
    case _NavIds.pujas:
      return const CmsRitualsContent();
    case _NavIds.festivals:
      return const CmsFestivalsContent();
    case _NavIds.donations:
      return const CmsDonationsContent();
    case _NavIds.donationsAll:
      return const CmsDonationsAllContent();
    case _NavIds.notifications:
      return const CmsNotificationsContent();
    case _NavIds.activity:
      return const CmsAdminNotificationsContent();
    case _NavIds.users:
      return const CmsUsersContent();
    // case _NavIds.analytics:
    //   return const CmsAnalyticsContent();
    case _NavIds.shlokas:
      return const CmsShlokaContent();
    case _NavIds.admins:
      return const CmsAdminsContent();
    case _NavIds.poojaKitInventory:
      return const CmsPoojaKitInventoryContent();
    case _NavIds.poojaKitManage:
      return const CmsPoojaKitContent();
    case _NavIds.poojaKitOrders:
      return const CmsPoojaKitOrdersContent();
    case _NavIds.poojaKitRefunds:
      return const CmsPoojaKitRefundsContent();
    case _NavIds.poojaKitPayments:
      return const CmsPoojaKitPaymentsContent();
    case _NavIds.manageRituals:
      return const CmsManageRitualsContent();
    default:
      return const CmsDashboardContent();
  }
}

int _indexFromRoute(String route, bool isSuperAdmin) {
  switch (route) {
    case AppRoutes.cmsDeities:
    case AppRoutes.cmsDeityCreate:
    case AppRoutes.cmsDeityEdit:
      return _NavIds.deities;
    case AppRoutes.cmsRituals:
    case AppRoutes.cmsRitualCreate:
    case AppRoutes.cmsRitualEdit:
      return _NavIds.pujas;
    case AppRoutes.cmsFestivals:
    case AppRoutes.cmsFestivalCreate:
      return _NavIds.festivals;
    case AppRoutes.cmsNotifications:
      return _NavIds.notifications;
    case AppRoutes.cmsActivity:
      return _NavIds.activity;
    case AppRoutes.cmsUsers:
      return _NavIds.users;
    case AppRoutes.cmsAnalytics:
      return _NavIds.dashboard;
    case AppRoutes.cmsPoojaKitInventory:
      return _NavIds.poojaKitInventory;
    case AppRoutes.cmsPoojaKit:
      return _NavIds.poojaKitManage;
    case AppRoutes.cmsPoojaKitOrders:
      return _NavIds.poojaKitOrders;
    case AppRoutes.cmsPoojaKitRefunds:
      return _NavIds.poojaKitRefunds;
    case AppRoutes.cmsPoojaKitPayments:
      return _NavIds.poojaKitPayments;
    case AppRoutes.cmsManageRituals:
      return _NavIds.manageRituals;
    case AppRoutes.cmsDonations:
      return _NavIds.donations;
    case AppRoutes.cmsDonationsAll:
      return _NavIds.donationsAll;
    case AppRoutes.cmsShlokas:
      return isSuperAdmin ? _NavIds.shlokas : _NavIds.dashboard;
    case AppRoutes.cmsAdmins:
      return isSuperAdmin ? _NavIds.admins : _NavIds.dashboard;
    case AppRoutes.cmsApproval:
      return _NavIds.dashboard;
    case AppRoutes.cms:
    default:
      return _NavIds.dashboard;
  }
}

/// In-shell tab navigation without `Get.offNamed` (keeps sidebar scroll position).
class CmsShellNavigation {
  static _CmsShellPageState? _shell;

  static void attach(_CmsShellPageState shell) => _shell = shell;

  static void detach(_CmsShellPageState shell) {
    if (_shell == shell) _shell = null;
  }

  /// Returns `true` when the CMS shell is active and the tab was switched.
  static bool openManageAdmins() {
    final shell = _shell;
    if (shell == null) return false;
    shell.navigateToTab(_NavIds.admins);
    return true;
  }

  static bool selectTab(int index) {
    final shell = _shell;
    if (shell == null) return false;
    shell.navigateToTab(index);
    return true;
  }

  static void openFromNotification(AdminNotificationItem n) {
    final shell = _shell;
    if (shell == null) return;
    switch (n.type) {
      case 'NEW_ORDER':
        final id = n.orderId;
        shell.navigateToTab(_NavIds.poojaKitOrders);
        if (id != null && id.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<AdminOrdersController>()) {
              Get.find<AdminOrdersController>().openOrder(id);
            }
          });
        } else if (kIsWeb) {
          updateCmsHashRoute(AppRoutes.cmsPoojaKitOrders);
        }
        break;
      case 'PAYMENT_SUCCESS':
        shell.navigateToTab(_NavIds.donationsAll);
        if (kIsWeb) updateCmsHashRoute(AppRoutes.cmsDonationsAll);
        break;
      case 'REFUND_REQUEST':
      case 'REPLACEMENT_REQUEST':
        shell.navigateToTab(_NavIds.poojaKitRefunds);
        if (kIsWeb) updateCmsHashRoute(AppRoutes.cmsPoojaKitRefunds);
        break;
      default:
        shell.navigateToTab(_NavIds.activity);
        if (kIsWeb) updateCmsHashRoute(AppRoutes.cmsActivity);
    }
  }
}
