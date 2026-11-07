
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page Header
        SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            width: double.infinity,
            color: AppColors.primary,
            child: Builder(
              builder: (headerContext) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'حجوزاتي',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: IconButton(
                        onPressed: () {
                          _openDrawer(headerContext);
                        },
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Page Content
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 70,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد حجوزات حالياً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ستظهر هنا الدورات التي قمت بحجزها',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
