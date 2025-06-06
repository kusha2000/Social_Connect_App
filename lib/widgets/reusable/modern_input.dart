import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_connect/utils/app_constants/colors.dart';

class ModernInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const ModernInput({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  }) : super(key: key);

  @override
  State<ModernInput> createState() => _ModernInputState();
}

class _ModernInputState extends State<ModernInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    _updateTextState();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    _updateTextState();
  }

  void _updateTextState() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  bool get _shouldFloatLabel => _isFocused || _hasText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.border,
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floating Label
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(
              left: widget.prefixIcon != null ? 56 : 20,
              top: _shouldFloatLabel ? 8 : 0,
              right: widget.suffixIcon != null ? 56 : 20,
            ),
            height: _shouldFloatLabel ? 24 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _shouldFloatLabel ? 1.0 : 0.0,
              child: Text(
                widget.labelText,
                style: TextStyle(
                  color:
                      _isFocused ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Input Field Container
          Container(
            child: Stack(
              children: [
                // Main TextFormField
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  onTap: widget.onTap,
                  readOnly: widget.readOnly,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(
                      left: widget.prefixIcon != null ? 56 : 20,
                      right: widget.suffixIcon != null ? 56 : 20,
                      top: _shouldFloatLabel ? 8 : 20,
                      bottom: 16,
                    ),
                    border: InputBorder.none,
                    hintText: _shouldFloatLabel ? widget.hintText : null,
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 16,
                    ),
                    counterText: '',
                    // Show label as placeholder when not floating
                    labelText: _shouldFloatLabel ? null : widget.labelText,
                    labelStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),

                // Prefix Icon
                if (widget.prefixIcon != null)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),

                // Suffix Icon
                if (widget.suffixIcon != null)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: widget.suffixIcon!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
