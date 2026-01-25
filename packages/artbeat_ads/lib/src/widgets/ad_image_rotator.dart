import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AdImageRotator extends StatefulWidget {
  final List<String> imageUrls;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Duration autoRotateDuration;
  final bool autoRotate;

  const AdImageRotator({
    super.key,
    required this.imageUrls,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.autoRotateDuration = const Duration(seconds: 4),
    this.autoRotate = true,
  });

  @override
  State<AdImageRotator> createState() => _AdImageRotatorState();
}

class _AdImageRotatorState extends State<AdImageRotator> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant AdImageRotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length ||
        oldWidget.autoRotate != widget.autoRotate ||
        oldWidget.autoRotateDuration != widget.autoRotateDuration) {
      _timer?.cancel();
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    if (!widget.autoRotate || widget.imageUrls.length <= 1) {
      return;
    }
    _timer = Timer.periodic(widget.autoRotateDuration, (_) {
      if (!mounted) return;
      final next = (_index + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    final images = widget.imageUrls;
    final content = images.length == 1
        ? _buildImage(images.first)
        : PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            itemCount: images.length,
            itemBuilder: (context, index) => _buildImage(images[index]),
          );

    final child = SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );

    if (widget.borderRadius == null) {
      return child;
    }

    return ClipRRect(borderRadius: widget.borderRadius!, child: child);
  }

  Widget _buildImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, _, __) => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }
}
