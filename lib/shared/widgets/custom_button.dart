import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled && !widget.isLoading
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.enabled && !widget.isLoading
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.enabled && !widget.isLoading
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.enabled && !widget.isLoading ? widget.onTap : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
