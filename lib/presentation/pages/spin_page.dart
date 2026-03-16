// lib/presentation/pages/spin_page.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/wheel_view.dart';
import '../providers/spin_provider.dart';
import '../../domain/entities/item.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/theme.dart';

class SpinPage extends StatefulWidget {
  final int spinId;
  final String spinName;
  final String? spinColor;
  final int? spinDuration;

  const SpinPage({
    super.key,
    required this.spinId,
    required this.spinName,
    this.spinColor,
    this.spinDuration,
  });

  @override
  _SpinPageState createState() => _SpinPageState();
}

class _SpinPageState extends State<SpinPage> {
  final GlobalKey<WheelViewState> _wheelKey = GlobalKey();
  final Random _rnd = Random();
  List<Item> _items = [];
  List<Item> _wheelItems = [];
  bool _loading = true;
  String? _lastResult;
  bool _isRestoring = false;
  bool _isShuffling = false;
  bool _isSpinning = false;
  bool _removeAfterSpin = true; // Mặc định: giống behavior hiện tại
  int? _multiSpinTotal;
  int? _multiSpinIndex;
  int? _overrideWheelDurationMs;

  TextStyle _resultTextStyle(String text) {
    final len = text.trim().length;
    double size;
    if (len <= 10) {
      size = 28;
    } else if (len <= 16) {
      size = 24;
    } else if (len <= 24) {
      size = 20;
    } else {
      size = 18;
    }
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    );
  }

  Widget _buildResultPill(BuildContext context) {
    final text = _lastResult?.trim();
    final hasResult = text != null && text.isNotEmpty;
    final showProgress =
        _isSpinning && _multiSpinTotal != null && _multiSpinIndex != null;
    const double sideSlotWidth = 64; // chừa chỗ cho icon/progress để chữ không đè

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasResult
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Text nằm đúng tâm tuyệt đối, chừa chỗ 2 bên để không đè icon/progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: sideSlotWidth),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: hasResult
                    ? Text(
                        text,
                        key: ValueKey('result:$text'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: _resultTextStyle(text),
                      )
                    : Text(
                        'Bấm START để quay',
                        key: const ValueKey('result:empty'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ThemeColors.getSoftText(context),
                        ),
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: sideSlotWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasResult
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.grey.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    hasResult
                        ? Icons.verified_rounded
                        : Icons.auto_awesome_rounded,
                    size: 18,
                    color: hasResult ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: sideSlotWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: showProgress
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          '${_multiSpinIndex!}/${_multiSpinTotal!}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _pickWeightedIndex(List<Item> items) {
    final total = items.fold<int>(
      0,
      (p, e) => p + (e.weight > 0 ? e.weight : 1),
    );
    if (total <= 0) return 0;
    final r = _rnd.nextInt(total);
    var acc = 0;
    for (int i = 0; i < items.length; i++) {
      acc += (items[i].weight > 0 ? items[i].weight : 1);
      if (r < acc) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prov = Provider.of<SpinProvider>(context, listen: false);
    final list = await prov.getItems(widget.spinId);
    if (mounted) {
      setState(() {
        _items = list;
        _wheelItems = list;
        _loading = false;
      });
    }
  }

  Future<void> _onRestoreOrClearPressed() async {
    final prov = Provider.of<SpinProvider>(context, listen: false);
    try {
      if (_removeAfterSpin) {
        setState(() {
          _isRestoring = true;
        });
        final count = await prov.restoreItems(widget.spinId);

        if (mounted) {
          // Clear thông báo cũ trước
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          if (count > 0) {
            // Xóa kết quả hiển thị
            setState(() {
              _lastResult = null;
            });

            // Reload items để hiển thị lại
            await _loadItems();

            // Hiển thị thông báo thành công ngay
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã khôi phục $count mục'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            // Không có gì để khôi phục
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có mục nào bị loại để khôi phục'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Xóa lịch sử quay?'),
            content: const Text(
              'Thao tác này chỉ xóa lịch sử trong trang Lịch sử.\n'
              'Danh sách mục trong vòng quay sẽ không thay đổi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        setState(() {
          _isRestoring = true;
        });

        if (confirmed == true) {
          await prov.clearHistory(widget.spinId);
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa lịch sử quay'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _onShufflePressed() async {
    // Hiển thị thông báo ngay lập tức khi bấm
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã trộn danh sách'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    }

    final prov = Provider.of<SpinProvider>(context, listen: false);
    try {
      setState(() {
        _isShuffling = true;
      });

      await prov.shuffleItems(widget.spinId);

      if (mounted) {
        // Reload items để hiển thị lại theo thứ tự mới
        await _loadItems();

        // Xóa kết quả hiển thị
        setState(() {
          _lastResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShuffling = false;
        });
      }
    }
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

    // Kiểm tra xem vòng quay có đang quay không
    if (_isSpinning || _wheelKey.currentState?.isSpinning() == true) {
      // Đang quay thì không làm gì cả
      return;
    }

    final prov = Provider.of<SpinProvider>(context, listen: false);
    try {
      // Đánh dấu đang quay
      setState(() {
        _isSpinning = true;
      });

      final chosen = await prov.spinOnceWithMode(
        widget.spinId,
        removeAfterSpin: _removeAfterSpin,
      );
      final idx = _wheelItems.indexWhere((e) => e.id == chosen.id);
      await _wheelKey.currentState?.spinToIndex(idx >= 0 ? idx : 0);

      // Đánh dấu quay xong
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
      }
      if (mounted) {
        setState(() {
          _lastResult = chosen.label;
        });

        // Xóa item đã quay được khỏi danh sách (nếu đang bật chế độ loại)
        if (_removeAfterSpin && chosen.id != null) {
          await prov.deleteItem(chosen.id!);
          // Reload items để cập nhật danh sách
          await _loadItems();
        }

        if (!mounted) return;
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
                    color: AppColors.primary.withValues(alpha:0.1),
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
                if (_removeAfterSpin)
                  Text(
                    'Mục này đã được loại bỏ khỏi vòng quay',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softText,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Mục vẫn còn trong vòng quay',
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
      // Đánh dấu quay xong (hoặc lỗi)
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi quay: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _onMultiSpinPressed() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có mục để quay')),
        );
      }
      return;
    }

    if (_isSpinning || _wheelKey.currentState?.isSpinning() == true) return;

    final config = await _showMultiSpinDialog();
    if (config == null) return;
    if (config.count <= 0) return;

    await _runMultiSpin(config);
  }

  Future<_MultiSpinConfig?> _showMultiSpinDialog() async {
    int value = 6;
    bool animateEach = true;

    return showDialog<_MultiSpinConfig>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            // Nếu N lớn thì mặc định chuyển sang chế độ nhanh
            if (value > 8 && animateEach == true) {
              animateEach = false;
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Quay nhiều lần'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chọn số lần quay (N)',
                    style: TextStyle(color: AppColors.softText),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: value > 1
                            ? () => setLocal(() => value -= 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: value < 100
                            ? () => setLocal(() => value += 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [2, 3, 5, 10, 20].map((n) {
                      return ChoiceChip(
                        label: Text('$n'),
                        selected: value == n,
                        onSelected: (_) => setLocal(() => value = n),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Chọn hiệu ứng (để N lớn không phải đợi quá lâu)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.motion_photos_on_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Hiệu ứng',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Từng lượt'),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Nhanh'),
                              ),
                            ],
                            selected: {animateEach},
                            onSelectionChanged: (s) {
                              final next = s.first;
                              // Tránh user chọn "Từng lượt" với N lớn (rất lâu + dễ lag)
                              if (next && value > 12) {
                                setLocal(() => animateEach = false);
                                return;
                              }
                              setLocal(() => animateEach = next);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          animateEach
                              ? 'Từng lượt: đẹp nhất khi N ≤ 12'
                              : 'Nhanh: xoay theo nhịp, vẫn đủ N kết quả',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.getSoftText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _removeAfterSpin
                        ? 'Đang bật “Loại mục sau khi trúng” (có thể hết mục trước khi đủ N)'
                        : 'Đang bật “Không loại mục” (có thể trúng lặp lại)',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _MultiSpinConfig(count: value, animateEach: animateEach),
                  ),
                  child: const Text('Bắt đầu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runMultiSpin(_MultiSpinConfig config) async {
    final prov = Provider.of<SpinProvider>(context, listen: false);
    final results = <String>[];
    final picked = <Item>[];
    final pool = List<Item>.from(_items);
    final wheelSnapshot = List<Item>.from(_wheelItems);
    final int spinMs = widget.spinDuration ?? AppConstants.defaultSpinDuration;

    Set<int> buildAnimateSet(int n) {
      if (config.animateEach) {
        return {for (int i = 1; i <= n; i++) i};
      }
      // Nhanh: xoay theo nhịp cân đối, tối đa 6 lần xoay
      final k = n <= 6 ? n : min(6, max(3, (n / 4).ceil()));
      final set = <int>{};
      for (int j = 0; j < k; j++) {
        final t = 1 + ((n - 1) * j / (k - 1)).round();
        set.add(t);
      }
      set.add(1);
      set.add(n);
      return set;
    }
    final animateSet = buildAnimateSet(config.count);

    setState(() {
      _isSpinning = true;
      _multiSpinTotal = config.count;
      _multiSpinIndex = 0;
      // Luôn dùng đúng thời gian đã set cho mỗi lượt xoay
      _overrideWheelDurationMs = spinMs;
      // Khi quay nhiều lần + chế độ loại mục, giữ wheel ổn định để tránh "nhảy vòng"
      _wheelItems = wheelSnapshot;
    });

    try {
      for (int i = 1; i <= config.count; i++) {
        if (pool.isEmpty) break;

        final pickedIndex = _pickWeightedIndex(pool);
        final chosen = pool[pickedIndex];
        picked.add(chosen);
        results.add(chosen.label);

        // Nếu bật loại mục, loại khỏi pool (đúng logic)
        if (_removeAfterSpin) {
          pool.removeAt(pickedIndex);
        }

        // Animate: từng lượt hoặc theo nhịp cân đối
        final bool shouldAnimate = animateSet.contains(i);
        if (shouldAnimate) {
          final idx = wheelSnapshot.indexWhere((e) => e.id == chosen.id);
          await _wheelKey.currentState?.spinToIndex(
            idx >= 0 ? idx : 0,
            durationMs: spinMs,
            minTurns: config.animateEach ? 3 : 2,
            maxTurns: config.animateEach ? 4 : 3,
            clockwise: true,
          );
          // pause nhẹ cho mắt kịp theo
          await Future<void>.delayed(
            Duration(milliseconds: config.animateEach ? 140 : 120),
          );
        } else {
          // tua nhanh nhưng vẫn "có nhịp"
          await Future<void>.delayed(const Duration(milliseconds: 110));
        }

        if (!mounted) return;
        setState(() {
          _lastResult = chosen.label;
          _multiSpinIndex = i;
        });
      }

      // Ghi lịch sử đúng số lần (không block UI từng lượt)
      for (final it in picked) {
        if (it.id == null) continue;
        await prov.repository.saveResult(
          widget.spinId,
          it.id!,
          it.label,
          wasRemoved: _removeAfterSpin,
        );
      }

      // Nếu chế độ loại mục: cập nhật DB 1 lần (đỡ lag) thay vì delete từng item
      if (_removeAfterSpin) {
        await prov.repository.replaceItems(widget.spinId, pool);
      }

      if (mounted && results.isNotEmpty) {
        setState(() {
          _lastResult = results.last;
        });
      }

      if (_removeAfterSpin) {
        await _loadItems();
      }

      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không quay được lần nào')),
        );
        return;
      }
      if (_removeAfterSpin && results.length < config.count) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã quay ${results.length}/${config.count} lần (hết mục)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _showMultiResultsBottomSheet(results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi quay: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _multiSpinTotal = null;
          _multiSpinIndex = null;
          _overrideWheelDurationMs = null;
          // Sau khi quay xong, đồng bộ wheel theo items hiện tại
          _wheelItems = _items;
        });
      }
    }
  }

  void _showMultiResultsBottomSheet(List<String> results) {
    final text = results.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Kết quả quay nhiều lần',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tổng: ${results.length} lần',
                  style: TextStyle(color: AppColors.softText, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: SelectableText(text),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép kết quả')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Share.share(text, subject: 'Kết quả quay - ${widget.spinName}');
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Chia sẻ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Chế độ quay',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Text(
                                    'Còn ${_items.length} mục',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ThemeColors.getTextPrimary(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('Không loại'),
                                  icon: Icon(Icons.all_inclusive),
                                ),
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('Loại sau khi trúng'),
                                  icon: Icon(Icons.remove_circle_outline),
                                ),
                              ],
                              selected: {_removeAfterSpin},
                              onSelectionChanged: (_isSpinning || _isRestoring || _isShuffling)
                                  ? null
                                  : (selection) {
                                      setState(() {
                                        _removeAfterSpin = selection.first;
                                      });
                                    },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  _removeAfterSpin ? Icons.info_outline : Icons.lightbulb_outline,
                                  size: 16,
                                  color: ThemeColors.getSoftText(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _removeAfterSpin
                                        ? 'Mỗi lần trúng sẽ loại mục khỏi vòng quay (có thể hết mục).'
                                        : 'Mục sẽ không bị loại (có thể trúng lặp lại).',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ThemeColors.getSoftText(context),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Kết quả nhỏ gọn nằm giữa
                    _buildResultPill(context),
                    const SizedBox(height: 16),
                    // Mũi tên chỉ thẳng vào bánh xe
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
                            items: _wheelItems,
                            themeColor: widget.spinColor,
                            size: AppConstants.defaultWheelSize,
                            spinDuration: _overrideWheelDurationMs ?? widget.spinDuration,
                            onSpinEnd: (index) {
                              // Callback khi quay xong
                            },
                          ),
                          // Nút START có thể click được
                          GestureDetector(
                            onTap: (_items.isEmpty || _isSpinning)
                                ? null
                                : _onSpinPressed,
                            child: Container(
                              width: AppConstants.defaultWheelSize * 0.25,
                              height: AppConstants.defaultWheelSize * 0.25,
                              decoration: BoxDecoration(
                                color: _isSpinning
                                    ? Colors.grey.shade300
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'START',
                                  style: TextStyle(
                                    fontSize:
                                        AppConstants.defaultWheelSize * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: _isSpinning
                                        ? Colors.grey.shade600
                                        : const Color(0xFF1E40AF),
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
                    // Các nút hành động - gọn gàng, sạch & bắt mắt
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _CompactActionButton(
                            icon: Icons.shuffle,
                            label: 'Trộn',
                            onPressed: _items.length > 1 &&
                                    !_isShuffling &&
                                    !_isRestoring &&
                                    !_isSpinning
                                ? _onShufflePressed
                                : null,
                            isLoading: _isShuffling,
                            color: AppColors.primary,
                            style: _ActionButtonStyle.outline,
                          ),
                          _CompactActionButton(
                            icon: _removeAfterSpin
                                ? Icons.refresh
                                : Icons.delete_sweep_outlined,
                            label: _removeAfterSpin ? 'Khôi phục mục' : 'Xóa lịch sử',
                            onPressed: !_isRestoring && !_isShuffling && !_isSpinning
                                ? _onRestoreOrClearPressed
                                : null,
                            isLoading: _isRestoring,
                            color: _removeAfterSpin ? AppColors.success : AppColors.error,
                            style: _removeAfterSpin
                                ? _ActionButtonStyle.filled
                                : _ActionButtonStyle.outline,
                          ),
                          _CompactActionButton(
                            icon: Icons.repeat_rounded,
                            label: 'Quay N lần',
                            onPressed: !_isRestoring && !_isShuffling && !_isSpinning
                                ? _onMultiSpinPressed
                                : null,
                            isLoading: false,
                            color: AppColors.primary,
                            style: _ActionButtonStyle.filled,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

enum _ActionButtonStyle { filled, outline }

class _MultiSpinConfig {
  final int count;
  final bool animateEach;
  const _MultiSpinConfig({required this.count, required this.animateEach});
}

// Widget button gọn gàng, đẹp cho các action
class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final _ActionButtonStyle style;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    required this.color,
    this.style = _ActionButtonStyle.filled,
  });

  Color _darker(Color c) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness * 0.88).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final bool isOutline = style == _ActionButtonStyle.outline;
    final bg = isOutline ? Colors.transparent : color;
    final fg = isOutline ? color : Colors.white;
    final border = Border.all(
      color: isOutline ? color.withValues(alpha: 0.65) : color.withValues(alpha: 0.20),
      width: 1.2,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              gradient: !isOutline
                  ? LinearGradient(
                      colors: [color, _darker(color)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: border,
              boxShadow: !isOutline
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                else
                  Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
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
