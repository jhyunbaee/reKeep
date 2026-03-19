import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rekeep/constants/colors.dart';

class BottomMenuBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomMenuBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuItem(const Icon(FontAwesomeIcons.houseChimney), "홈", 0),
          _buildMenuItem(const Icon(FontAwesomeIcons.sackDollar), "자산", 1),
          _buildMenuItem(const Icon(FontAwesomeIcons.chartSimple), "분석", 2),
          _buildMenuItem(const Icon(FontAwesomeIcons.ellipsis), "더보기", 3),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Widget icon, String label, int index) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.secondary,
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
