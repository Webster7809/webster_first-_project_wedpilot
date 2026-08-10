import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_text_styles.dart';

/// Text input for the whole app.
///
/// Shape, fill and border states come from `inputDecorationTheme`; this widget
/// only adds the label, the password visibility toggle, and an error message
/// that grows/fades in rather than snapping the layout.
class WedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;

  /// Externally-supplied error. Takes precedence over the [validator] result.
  final String? errorText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;

  /// Overrides the prefix icon's color. Leave null for the muted default.
  final Color? prefixIconColor;

  /// Inline text prefix (e.g. a currency code). Ignored when [prefixIcon] is
  /// set — the two occupy the same slot.
  final String? prefixText;

  /// Trailing widget. Ignored when [isPassword] is true — the visibility
  /// toggle owns that slot.
  final Widget? suffix;

  /// Null means unlimited/auto-grow (e.g. a chat composer).
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;

  /// Overrides the themed corner radius. Leave null to follow the theme.
  final double? borderRadius;

  /// Overrides the themed fill. Leave null to follow the theme.
  final Color? fillColor;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const WedTextField({
    super.key,
    this.label = '',
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.prefixIconColor,
    this.prefixText,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.borderRadius,
    this.fillColor,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.focusNode,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  @override
  State<WedTextField> createState() => _WedTextFieldState();
}

class _WedTextFieldState extends State<WedTextField> {
  bool _obscure = true;
  String? _validationError;

  /// Runs the caller's validator, records the message so we can render it
  /// ourselves, and returns it unchanged so `Form.validate()` behaves exactly
  /// as it did before.
  String? _runValidator(String? value) {
    final result = widget.validator?.call(value);
    if (result != _validationError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _validationError = result);
      });
    }
    return result;
  }

  InputBorder? _border(BuildContext context, InputBorder? themed) {
    if (widget.borderRadius == null) return themed;
    final side = themed is OutlineInputBorder ? themed.borderSide : BorderSide.none;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius!),
      borderSide: side,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).inputDecorationTheme;
    // The field's fill already follows the active theme (see AppTheme's
    // inputDecorationTheme) — every color read here must too, via the
    // ColorScheme rather than a hardcoded AppColors constant, or a dark theme
    // ends up with dark ink on that same dark fill: unreadable text the
    // couple is actively typing into.
    final colors = Theme.of(context).colorScheme;
    final message = widget.errorText ?? _validationError;
    final hasError = message != null && message.isNotEmpty;

    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator == null ? null : _runValidator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofocus: widget.autofocus,
      style: AppTextStyles.body.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        helperText: widget.helperText,
        // The message is rendered below by [_ErrorMessage]; this only puts the
        // field into its error state so the border turns red.
        errorText: hasError ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        fillColor: widget.fillColor,
        border: _border(context, theme.border),
        enabledBorder: _border(context, theme.enabledBorder),
        focusedBorder: _border(context, theme.focusedBorder),
        errorBorder: _border(context, theme.errorBorder),
        focusedErrorBorder: _border(context, theme.focusedErrorBorder),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                size: 20, color: widget.prefixIconColor ?? colors.onSurfaceVariant)
            : null,
        prefixText: widget.prefixIcon == null ? widget.prefixText : null,
        prefixStyle: AppTextStyles.body.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                iconSize: 20,
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffix,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: AppTextStyles.label.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
        ],
        field,
        _ErrorMessage(message: hasError ? message : null),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String? message;

  const _ErrorMessage({this.message});

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 180);

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: AnimatedOpacity(
        duration: duration,
        opacity: message == null ? 0 : 1,
        child: message == null
            ? const SizedBox(width: double.infinity, height: 0)
            : Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  message!,
                  // Theme.of(context).colorScheme.error, not the fixed
                  // AppColors.error — the light-theme red is under 3:1 on the
                  // dark theme's near-black background.
                  style: AppTextStyles.caption
                      .copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
      ),
    );
  }
}
