import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/features/courses/models/course_model.dart';

class CourseDetailsImage extends StatelessWidget {
  const CourseDetailsImage({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final image = course.image;
    final isNetworkImage =
        image != null &&
        (image.startsWith('http://') || image.startsWith('https://'));

    return SizedBox(
      height: 230,
      width: double.infinity,
      child: isNetworkImage
          ? CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          : Image.asset(
              image ?? 'assets/images/english2_course.png',
              fit: BoxFit.cover,
              errorBuilder: _buildError,
            ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => _buildPlaceholder();

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.school_outlined,
        size: 60,
        color: AppColors.primary,
      ),
    );
  }
}
