import 'package:flutter/material.dart';

/// Text widget with overflow-safe defaults to avoid layout overflow across devices.
///
/// By default uses [TextOverflow.ellipsis] and [maxLines: 1]. Override with
/// [maxLines] and [overflow] for multi-line or custom behavior.
///
/// Prefer this over raw [Text] in cards, list items, and constrained layouts.
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
  });

  /// Multi-line [AppText] (no ellipsis, no maxLines limit).
  factory AppText.body(
    String data, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    bool softWrap = true,
  }) {
    return AppText(
      data,
      key: key,
      style: style,
      textAlign: textAlign,
      maxLines: null,
      overflow: null,
      softWrap: softWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
