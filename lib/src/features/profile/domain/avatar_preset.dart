import 'package:flutter/material.dart';

class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<Color> colors;
}

const kAvatarPresets = <AvatarPreset>[
  AvatarPreset(
    id: 'gold-crown',
    label: 'Crown',
    icon: Icons.workspace_premium_rounded,
    colors: [Color(0xFFFFC857), Color(0xFFF59E0B)],
  ),
  AvatarPreset(
    id: 'purple-star',
    label: 'Star',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  ),
  AvatarPreset(
    id: 'green-leaf',
    label: 'Leaf',
    icon: Icons.spa_rounded,
    colors: [Color(0xFF15803D), Color(0xFF4ADE80)],
  ),
  AvatarPreset(
    id: 'blue-wave',
    label: 'Wave',
    icon: Icons.waves_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF22D3EE)],
  ),
  AvatarPreset(
    id: 'orange-fire',
    label: 'Fire',
    icon: Icons.local_fire_department_rounded,
    colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
  ),
  AvatarPreset(
    id: 'pink-heart',
    label: 'Heart',
    icon: Icons.favorite_rounded,
    colors: [Color(0xFFDB2777), Color(0xFFFB7185)],
  ),
  AvatarPreset(
    id: 'rocket-sky',
    label: 'Rocket',
    icon: Icons.rocket_launch_rounded,
    colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
  ),
  AvatarPreset(
    id: 'night-moon',
    label: 'Moon',
    icon: Icons.nightlight_round,
    colors: [Color(0xFF111827), Color(0xFF6D28D9)],
  ),
  AvatarPreset(
    id: 'diamond-teal',
    label: 'Diamond',
    icon: Icons.diamond_rounded,
    colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
  ),
  AvatarPreset(
    id: 'lucky-bolt',
    label: 'Bolt',
    icon: Icons.bolt_rounded,
    colors: [Color(0xFF65A30D), Color(0xFFFACC15)],
  ),
];

AvatarPreset? avatarPresetById(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }

  for (final preset in kAvatarPresets) {
    if (preset.id == id) {
      return preset;
    }
  }

  return null;
}

String profileInitials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    final word = parts.first;
    final end = word.length >= 2 ? 2 : 1;
    return word.substring(0, end).toUpperCase();
  }

  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}
