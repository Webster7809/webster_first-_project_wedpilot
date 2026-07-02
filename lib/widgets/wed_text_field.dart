import 'package:flutter/material.dart';

class WedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? fillColor;

  const WedTextField({
    super.key,
    this.label = '',
    this.hint,
    this.helperText,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.borderRadius = 12,
    this.fillColor,
  });

  @override
  State<WedTextField> createState() => _WedTextFieldState();
}

class _WedTextFieldState extends State<WedTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: InputDecoration(
        hintText: widget.hint,
        helperText: widget.helperText,
        filled: widget.fillColor != null,
        fillColor: widget.fillColor,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153))
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 38),
        suffixIcon: widget.isPassword
            ? IconButton(
                iconSize: 18,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffix,
      ),
    );

    if (widget.label.isEmpty) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
