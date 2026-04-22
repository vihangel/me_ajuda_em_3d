import 'package:flutter/material.dart';

import '../../../core/p3d_models.dart';

IconData categoryIcon(String icon) {
  return switch (icon) {
    'key' => Icons.vpn_key_outlined,
    'miniature' => Icons.smart_toy_outlined,
    'decor' => Icons.weekend_outlined,
    'frame' => Icons.crop_original_outlined,
    'lamp' => Icons.lightbulb_outlined,
    'image' => Icons.image_outlined,
    _ => Icons.category_outlined,
  };
}

Color categoryAccent(String icon) {
  return switch (icon) {
    'key' => const Color(0xFF6B5CF6),
    'miniature' => const Color(0xFFE05297),
    'decor' => const Color(0xFFC76A28),
    'frame' => const Color(0xFF2D9B7F),
    'lamp' => const Color(0xFFD4A017),
    'image' => const Color(0xFF4B7BE5),
    _ => const Color(0xFF5B677A),
  };
}

IconData catalogIcon(String imageTag) {
  return switch (imageTag) {
    'key_name' => Icons.abc_rounded,
    'key_logo' => Icons.business_rounded,
    'key_char' => Icons.face_rounded,
    'mini_char' => Icons.smart_toy_rounded,
    'mini_rpg' => Icons.casino_rounded,
    'decor_vase' => Icons.local_florist_rounded,
    'decor_frame' => Icons.crop_original_rounded,
    'sign_wall' => Icons.text_fields_rounded,
    'sign_door' => Icons.meeting_room_outlined,
    'lamp_litho' => Icons.photo_rounded,
    'lamp_geo' => Icons.lightbulb_rounded,
    _ => Icons.view_in_ar_rounded,
  };
}

Color orderStatusColor(CustomerOrderStatus status, ColorScheme colors) {
  return switch (status) {
    CustomerOrderStatus.received => colors.primary,
    CustomerOrderStatus.reviewing => Colors.amber.shade800,
    CustomerOrderStatus.quoted => Colors.indigo.shade600,
    CustomerOrderStatus.approved => Colors.teal.shade700,
    CustomerOrderStatus.production => Colors.deepOrange.shade600,
    CustomerOrderStatus.ready => Colors.green.shade700,
    CustomerOrderStatus.closed => colors.outline,
  };
}
