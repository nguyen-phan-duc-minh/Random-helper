// lib/presentation/widgets/wheel_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/item.dart';
import '../../core/constants.dart';
import '../../core/color_palettes.dart';

typedef OnSpinEnd = void Function(int index);

class WheelView extends StatefulWidget {
  final List<Item> items;
  final String? themeColor;
  final double size;
  final OnSpinEnd? onSpinEnd;
  final int? spinDuration; // Thời gian quay tùy chỉnh

  const WheelView({
    Key? key,
    required this.items,
    this.themeColor,
    this.size = 320,
    this.onSpinEnd,
    this.spinDuration,
  }) : super(key: key);

  @override
  WheelViewState createState() => WheelViewState();
}

class WheelViewState extends State<WheelView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  Future<void> spinToIndex(int targetIndex) async {
    final n = widget.items.length;
    if (n == 0) return;
    final segmentAngle = 2 * pi / n;
    final midAngleOfSegment = (targetIndex * segmentAngle) + segmentAngle / 2;
    final fullTurns = AppConstants.minFullTurns +
        Random().nextInt(
          AppConstants.maxFullTurns - AppConstants.minFullTurns + 1,
        );
    final targetRotation = -pi / 2 - midAngleOfSegment + fullTurns * 2 * pi;

    final start = _rotation;
    final end = targetRotation;

    // Sử dụng spinDuration tùy chỉnh nếu có, nếu không thì dùng random
    int duration;
    if (widget.spinDuration != null) {
      duration = widget.spinDuration!;
    } else {
      duration = AppConstants.minSpinDuration +
          Random().nextInt(
            AppConstants.maxSpinDuration - AppConstants.minSpinDuration + 1,
          );
    }

    _controller.duration = Duration(milliseconds: duration);
    _anim =
        Tween<double>(begin: start, end: end).animate(
            CurvedAnimation(parent: _controller, curve: Curves.decelerate),
          )
          ..addListener(() {
            setState(() {
              _rotation = _anim.value;
            });
          })
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              final normalized = (_rotation % (2 * pi) + 2 * pi) % (2 * pi);
              final pointerAngle = (-pi / 2 - normalized) % (2 * pi);
              var idx = (((pointerAngle + 2 * pi) % (2 * pi)) / segmentAngle)
                  .floor();
              idx = (idx % n + n) % n;
              if (widget.onSpinEnd != null) widget.onSpinEnd!(idx);
            }
          });

    _controller.reset();
    await _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForIndex(int i) {
    final item = widget.items[i];
    if (item.color != null) {
      try {
        return Color(int.parse(item.color!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }
    
    // Sử dụng palette màu từ themeColor (JSON string)
    List<Color> palette;
    if (widget.themeColor != null && widget.themeColor!.contains(',')) {
      // Nếu là JSON palette
      palette = ColorPalettes.jsonToPalette(widget.themeColor!);
    } else {
      // Fallback về palette mặc định
      palette = ColorPalettes.palettes[0].colors;
    }
    
    // Chọn màu từ palette dựa trên index
    final paletteIndex = i % palette.length;
    return palette[paletteIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: _rotation,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _WheelPainter(
                items: widget.items,
                colorForIndex: _colorForIndex,
              ),
            ),
          ),
          // Nút START ở giữa (không click được, để spin_page xử lý)
          IgnorePointer(
            child: Container(
              width: widget.size * 0.25,
              height: widget.size * 0.25,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'START',
                  style: TextStyle(
                    fontSize: widget.size * 0.06,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                    letterSpacing: 1.2,
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

class _WheelPainter extends CustomPainter {
  final List<Item> items;
  final Color Function(int) colorForIndex;
  _WheelPainter({required this.items, required this.colorForIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 2; // Trừ đi border ngoài
    final paint = Paint()..style = PaintingStyle.fill;
    final n = items.length;
    if (n == 0) return;
    final sweep = 2 * pi / n;

    for (int i = 0; i < n; i++) {
      final start = i * sweep;
      paint.color = colorForIndex(i);
      // Vẽ segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      
      // Vẽ border trắng dày giữa các segment (đường thẳng từ tâm ra ngoài)
      final borderAngle = start;
      final borderEndX = center.dx + radius * cos(borderAngle);
      final borderEndY = center.dy + radius * sin(borderAngle);
      final borderLinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white;
      canvas.drawLine(center, Offset(borderEndX, borderEndY), borderLinePaint);
      
      final label = items[i].label;
      // Tính toán màu chữ dựa trên độ sáng của màu nền
      final bgColor = colorForIndex(i);
      final luminance = bgColor.computeLuminance();
      // Nếu màu nền sáng thì dùng chữ đen, nếu tối thì dùng chữ trắng
      final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;
      
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: textColor,
            fontSize: 16, // Tăng font size
            fontWeight: FontWeight.bold,
            shadows: textColor == Colors.white ? [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: radius * 0.6);
      final angle = start + sweep / 2;
      final tx = center.dx + (radius * 0.7) * cos(angle);
      final ty = center.dy + (radius * 0.7) * sin(angle);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(angle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    
    // Vẽ border tròn ngoài cùng
    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    canvas.drawCircle(center, radius, outerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.items != items;
}
