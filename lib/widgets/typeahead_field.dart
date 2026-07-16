import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';
import 'highlighted_text.dart';
import 'wed_text_field.dart';

typedef TypeaheadSuggestionsCallback<T> = FutureOr<List<T>> Function(
  String query,
);
typedef TypeaheadItemBuilder<T> = Widget Function(
  BuildContext context,
  T option,
  String query,
  bool isHighlighted,
);

/// A search field that shows a live dropdown of matching suggestions as the
/// user types — built on Flutter's own [RawAutocomplete], which already
/// provides keyboard navigation (arrow keys + Enter), touch selection, and
/// dismiss-on-blur/dismiss-on-select for free, uniformly across Android,
/// iOS, and Web.
///
/// [suggestionsCallback] may be synchronous (filtering an already-loaded
/// list) or asynchronous (a network call) — pass [debounceDuration] to
/// delay/coalesce calls for the latter; local sources should leave it at
/// [Duration.zero].
class TypeaheadField<T extends Object> extends StatefulWidget {
  const TypeaheadField({
    super.key,
    required this.suggestionsCallback,
    required this.displayStringForOption,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.itemBuilder,
    this.debounceDuration = Duration.zero,
    this.minQueryLength = 0,
    this.maxSuggestions = 8,
    this.label = '',
    this.hint,
    this.prefixIcon = Icons.search_rounded,
    this.fillColor,
    this.borderRadius = 12.0,
    this.optionsMaxHeight = 280.0,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.mostSpace,
    this.autofocus = false,
    this.onChanged,
    this.showClearButton = true,
  });

  final TypeaheadSuggestionsCallback<T> suggestionsCallback;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TypeaheadItemBuilder<T>? itemBuilder;
  final Duration debounceDuration;
  final int minQueryLength;
  final int maxSuggestions;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Color? fillColor;
  final double borderRadius;
  final double optionsMaxHeight;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final bool showClearButton;

  @override
  State<TypeaheadField<T>> createState() => _TypeaheadFieldState<T>();
}

class _TypeaheadFieldState<T extends Object> extends State<TypeaheadField<T>> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;
  List<T> _lastOptions = const [];
  late final Future<List<T>?> Function(String) _debouncedFetch;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _debouncedFetch = _debounce<List<T>, String>(
      (query) async => await widget.suggestionsCallback(query),
      widget.debounceDuration,
    );
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  Future<List<T>> _optionsBuilder(TextEditingValue value) async {
    final query = value.text;
    if (query.length < widget.minQueryLength) {
      _lastOptions = const [];
      return _lastOptions;
    }
    try {
      final result = await _debouncedFetch(query);
      if (result == null) {
        // Superseded by a newer keystroke — keep the last good list on
        // screen instead of flashing the dropdown empty.
        return _lastOptions;
      }
      _lastOptions = result.take(widget.maxSuggestions).toList();
    } catch (_) {
      // A suggestions-source failure (e.g. a dropped network call) must
      // never break the field — fall back to the last successful list.
    }
    return _lastOptions;
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _optionsBuilder,
      displayStringForOption: widget.displayStringForOption,
      onSelected: widget.onSelected,
      optionsViewOpenDirection: widget.optionsViewOpenDirection,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return WedTextField(
          controller: controller,
          focusNode: focusNode,
          label: widget.label,
          hint: widget.hint,
          prefixIcon: widget.prefixIcon,
          fillColor: widget.fillColor,
          borderRadius: widget.borderRadius,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          suffix: widget.showClearButton && controller.text.isNotEmpty
              ? IconButton(
                  iconSize: 18,
                  tooltip: 'Clear',
                  icon: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                  onPressed: () {
                    controller.clear();
                    widget.onChanged?.call('');
                    setState(() {});
                  },
                )
              : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionsList = options.toList();
        final query = _controller.text;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxHeight: widget.optionsMaxHeight),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: AppShadows.md,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: optionsList.length,
                itemBuilder: (context, index) {
                  final option = optionsList[index];
                  final isHighlighted =
                      AutocompleteHighlightedOption.of(context) == index;
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      color: isHighlighted
                          ? AppColors.forestGreen.withAlpha(18)
                          : Colors.transparent,
                      child: widget.itemBuilder != null
                          ? widget.itemBuilder!(context, option, query, isHighlighted)
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: HighlightedText(
                                text: widget.displayStringForOption(option),
                                query: query,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Debounce helper ─────────────────────────────────────────────────────────
//
// A cancel-and-replace Timer + Completer, matching the pattern Flutter's own
// docs recommend for debouncing an async RawAutocomplete.optionsBuilder
// (see flutter/examples/api/lib/material/autocomplete/autocomplete.3.dart).
// A superseded call resolves to `null`, which _optionsBuilder above maps to
// "keep showing the last good options" rather than a flash of emptiness.

typedef _Debounceable<S, P> = Future<S?> Function(P parameter);

_Debounceable<S, P> _debounce<S, P>(
  _Debounceable<S, P> function,
  Duration duration,
) {
  _DebounceTimer? debounceTimer;
  return (P parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer(duration);
    try {
      await debounceTimer!.future;
    } on _CancelException {
      return null;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer(Duration duration) {
    _timer = Timer(duration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() => _completer.complete();

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

class _CancelException implements Exception {
  const _CancelException();
}
