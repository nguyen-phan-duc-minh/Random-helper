import 'package:flutter/material.dart';

class ColorPalette {
  final String name;
  final List<Color> colors;

  const ColorPalette({
    required this.name,
    required this.colors,
  });
}

class ColorPalettes {
  static final List<ColorPalette> palettes = [
    // Palette 1: Blue to Pink gradient
    const ColorPalette(
      name: 'Ocean Breeze',
      colors: [
        Color(0xFF87CEEB), // Sky blue
        Color(0xFF6BB6FF), // Light blue
        Color(0xFF4A90E2), // Blue
        Color(0xFF7B68EE), // Medium slate blue
        Color(0xFF9370DB), // Medium purple
        Color(0xFFFF69B4), // Hot pink
      ],
    ),
    // Palette 2: Warm sunset
    const ColorPalette(
      name: 'Sunset',
      colors: [
        Color(0xFFFFD700), // Gold
        Color(0xFFFF8C00), // Dark orange
        Color(0xFFFF1493), // Deep pink
        Color(0xFF8B00FF), // Violet
        Color(0xFF00BFFF), // Deep sky blue
      ],
    ),
    // Palette 3: Rainbow
    const ColorPalette(
      name: 'Rainbow',
      colors: [
        Color(0xFFFF0000), // Red
        Color(0xFFFF8C00), // Orange
        Color(0xFFFFD700), // Yellow
        Color(0xFF00FF00), // Green
        Color(0xFF00CED1), // Dark turquoise
        Color(0xFF0066CC), // Blue
      ],
    ),
    // Palette 4: Purple dream
    const ColorPalette(
      name: 'Purple Dream',
      colors: [
        Color(0xFF191970), // Midnight blue
        Color(0xFF4B0082), // Indigo
        Color(0xFF6A5ACD), // Slate blue
        Color(0xFF9370DB), // Medium purple
        Color(0xFFBA55D3), // Medium orchid
        Color(0xFFFFB6C1), // Light pink
      ],
    ),
    // Palette 5: Fresh mint
    const ColorPalette(
      name: 'Fresh Mint',
      colors: [
        Color(0xFF20B2AA), // Light sea green
        Color(0xFF40E0D0), // Turquoise
        Color(0xFFE0FFFF), // Light cyan
        Color(0xFFFFF8DC), // Cornsilk
        Color(0xFFFFFACD), // Lemon chiffon
        Color(0xFFFFA500), // Orange
      ],
    ),
    // Palette 6: Vibrant
    const ColorPalette(
      name: 'Vibrant',
      colors: [
        Color(0xFFFF0000), // Red
        Color(0xFFFFD700), // Gold
        Color(0xFF00FF00), // Lime
        Color(0xFF0000FF), // Blue
        Color(0xFF8A2BE2), // Blue violet
        Color(0xFFFF1493), // Deep pink
      ],
    ),
    // Palette 7: Soft pastel
    const ColorPalette(
      name: 'Soft Pastel',
      colors: [
        Color(0xFFFFB6C1), // Light pink
        Color(0xFFFFC0CB), // Pink
        Color(0xFFFFE4E1), // Misty rose
        Color(0xFFFFF8DC), // Cornsilk
        Color(0xFFE0FFE0), // Light green
      ],
    ),
    // Palette 8: Cool tones
    const ColorPalette(
      name: 'Cool Tones',
      colors: [
        Color(0xFFD3D3D3), // Light gray
        Color(0xFF87CEEB), // Sky blue
        Color(0xFF00CED1), // Dark turquoise
        Color(0xFF4682B4), // Steel blue
        Color(0xFF191970), // Midnight blue
      ],
    ),
    // Palette 9: Fire
    const ColorPalette(
      name: 'Fire',
      colors: [
        Color(0xFFFF0000), // Red
        Color(0xFFFF4500), // Orange red
        Color(0xFFFF8C00), // Dark orange
        Color(0xFFFFD700), // Gold
        Color(0xFF00FF00), // Green
      ],
    ),
  ];

  static String paletteToJson(List<Color> colors) {
    return colors.map((c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}').join(',');
  }

  static List<Color> jsonToPalette(String json) {
    if (json.isEmpty) return palettes[0].colors;
    return json.split(',').map((hex) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xff')));
      } catch (_) {
        return Colors.blue;
      }
    }).toList();
  }
}

