import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key, required this.title, required this.subTitle});
  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          ClipOval(
            child: Container(
              width: 100,
              height: 100,
              color: Colors.white,
              child: Image.asset(
                'assets/images/logo_app.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 24,
                color: Colors.grey.shade200,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subTitle,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade100,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ), // مساحة إضافية لضمان التداخل البصري الجميل
        ],
      ),
    );
  }
}
