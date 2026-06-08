import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
    this.textColor = Colors.black,
    this.gradientColors = const [AppColors.white, AppColors.white],
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.borderRadius = 20,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;
  final List<Color> gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final Color textColor;
  final double borderRadius;
  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !widget.isLoading;
    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: canTap ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: canTap ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: canTap ? () => setState(() => _isPressed = false) : null,
        onTap: canTap ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: widget.gradientBegin,
                end: widget.gradientEnd,
                colors: widget.gradientColors,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const ChakraLoadingIndicator(size: 22, color: Colors.white)
                  : Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
