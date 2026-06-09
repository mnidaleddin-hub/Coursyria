import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onIndexChanged;
  final List<NavigationDestinationData> destinations;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Large Screen: Use Navigation Rail
          return Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onIndexChanged,
                labelType: NavigationRailLabelType.all,
                backgroundColor: AppColors.secondaryNavy,
                selectedIconTheme: const IconThemeData(color: AppColors.accentTeal),
                unselectedIconTheme: const IconThemeData(color: Colors.white54),
                selectedLabelTextStyle: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
                unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
                destinations: destinations.map((d) => NavigationRailDestination(
                  icon: d.iconWidget ?? Icon(d.icon),
                  selectedIcon: d.selectedIconWidget ?? Icon(d.selectedIcon),
                  label: Text(d.label),
                )).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
              Expanded(child: child),
            ],
          );
        } else {
          // Mobile: Just return the child, the parent Scaffold will handle the BottomBar
          return child;
        }
      },
    );
  }
}


class NavigationDestinationData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget? iconWidget;
  final Widget? selectedIconWidget;

  NavigationDestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.iconWidget,
    this.selectedIconWidget,
  });
}
