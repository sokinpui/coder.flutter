import 'package:flutter/material.dart';

class HoverAnimatedButton extends StatefulWidget {
  const HoverAnimatedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
    this.hoverScale = 1.08,
    this.hoverColor,
    this.borderRadius,
    this.padding,
    this.cursor = SystemMouseCursors.click,
    this.tooltipWaitDuration = const Duration(seconds: 1),
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final double hoverScale;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final MouseCursor cursor;
  final Duration tooltipWaitDuration;

  @override
  State<HoverAnimatedButton> createState() => _HoverAnimatedButtonState();
}

class _HoverAnimatedButtonState extends State<HoverAnimatedButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.94 : (_isHovered ? widget.hoverScale : 1.0);

    Widget result = MouseRegion(
      cursor: widget.onTap != null ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.hoverColor ?? Colors.transparent)
                  : Colors.transparent,
              borderRadius: widget.borderRadius,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(
        message: widget.tooltip!,
        waitDuration: widget.tooltipWaitDuration,
        child: result,
      );
    }

    return result;
  }
}
