// lib/presentation/pages/spin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/wheel_view.dart';
import '../providers/spin_provider.dart';
import '../../domain/entities/item.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class SpinPage extends StatefulWidget {
  final int spinId;
  final String spinName;
  final String? spinColor;
  final int? spinDuration;

  const SpinPage({
    Key? key,
    required this.spinId,
    required this.spinName,
    this.spinColor,
    this.spinDuration,
  }) : super(key: key);

  @override
  _SpinPageState createState() => _SpinPageState();
}

class _SpinPageState extends State<SpinPage> {
  final GlobalKey<WheelViewState> _wheelKey = GlobalKey();
  List<Item> _items = [];
  bool _loading = true;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prov = Provider.of<SpinProvider>(context, listen: false);
    final list = await prov.getItems(widget.spinId);
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _onSpinPressed() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có mục để quay')),
        );
      }
      return;
    }
    final prov = Provider.of<SpinProvider>(context, listen: false);
    try {
      final chosen = await prov.spinOnce(widget.spinId);
      final idx = _items.indexWhere((e) => e.id == chosen.id);
      await _wheelKey.currentState?.spinToIndex(idx >= 0 ? idx : 0);
      if (mounted) {
        setState(() {
          _lastResult = chosen.label;
        });
        
        // Xóa item đã quay được khỏi danh sách
        if (chosen.id != null) {
          await prov.deleteItem(chosen.id!);
          // Reload items để cập nhật danh sách
          await _loadItems();
        }
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kết quả',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chosen.label,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mục này đã được loại bỏ khỏi vòng quay',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.softText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi quay: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.spinName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Hiển thị kết quả ở trên
                    if (_lastResult != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          _lastResult!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Text(
                          'Chạm START để quay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.softText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Mũi tên chỉ vào bánh xe
                    CustomPaint(
                      size: const Size(50, 40),
                      painter: _ArrowPainter(),
                    ),
                    const SizedBox(height: 12),
                    // Bánh xe với nút START ở giữa - căn giữa
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          WheelView(
                            key: _wheelKey,
                            items: _items,
                            themeColor: widget.spinColor,
                            size: AppConstants.defaultWheelSize,
                            spinDuration: widget.spinDuration,
                            onSpinEnd: (index) {
                              // Callback khi quay xong
                            },
                          ),
                          // Nút START có thể click được
                          GestureDetector(
                            onTap: _items.isEmpty ? null : _onSpinPressed,
                            child: Container(
                              width: AppConstants.defaultWheelSize * 0.25,
                              height: AppConstants.defaultWheelSize * 0.25,
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
                                    fontSize: AppConstants.defaultWheelSize * 0.06,
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

// Custom painter cho mũi tên
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E40AF)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final path = Path();
    // Vẽ mũi tên tam giác chỉ xuống - lớn hơn và rõ ràng hơn
    final arrowWidth = size.width * 0.8;
    final arrowHeight = size.height;
    final leftX = (size.width - arrowWidth) / 2;
    final rightX = leftX + arrowWidth;
    
    path.moveTo(size.width / 2, arrowHeight); // Điểm dưới (mũi tên)
    path.lineTo(leftX, 0); // Điểm trên trái
    path.lineTo(rightX, 0); // Điểm trên phải
    path.close();
    
    canvas.drawPath(path, paint);
    // Vẽ border trắng cho mũi tên
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

