import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.user,
    required this.onMyOrders,
    required this.onLogout,
  });

  final User user;
  final VoidCallback onMyOrders;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Who's logged in
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.caramel,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24, color: AppColors.latte),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.restaurant_menu_rounded,
              label: 'Menu',
              selected: true, // we're on the menu right now
              onTap: () => Navigator.of(context).pop(), // just close the drawer
            ),
            _DrawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'My orders',
              onTap: onMyOrders,
            ),
            const Spacer(), // pushes Log out to the bottom
            const Divider(indent: 24, endIndent: 24, color: AppColors.latte),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: const Color(0xFFB3261E),
              onTap: onLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        selected: selected,
        selectedTileColor: AppColors.latte, // highlight the current page
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
