# Responsive & Overflow Prevention

Central utilities to avoid overflow and layout issues across devices and screen sizes.

## ScreenUtils (BuildContext extensions)

```dart
import 'package:habra_mobile_app/core/responsive/responsive.dart';

// Screen dimensions
context.screenWidth;
context.screenHeight;
context.usableHeight;
context.safePaddingTop;
context.safePaddingBottom;

// Scaled values (use instead of fixed sizes)
context.wp(0.5);   // 50% of width
context.hp(0.2);   // 20% of height
context.sw(16);    // scale by width (design 375)
context.sh(48);    // scale by height (design 812)
context.sp(14);    // scaled font size

// Breakpoints
context.isSmallPhone;
context.isTablet;
context.screenSize; // ScreenSize.small | .medium | .large
```

## AppScrollView

Use instead of raw `SingleChildScrollView` for forms and variable-height pages. Handles keyboard dismiss and consistent padding.

```dart
body: AppScrollView(
  padding: EdgeInsets.all(AppResources.spacingM),
  child: Column(children: [...]),
)
```

## ResponsiveScaffold

Scaffold that optionally wraps `body` in `AppScrollView` when `scrollable: true`.

```dart
ResponsiveScaffold(
  appBar: AppBar(...),
  scrollable: true,
  body: Column(children: [...]),
)
```

## AppText (core/widgets/app_text.dart)

`AppText` defaults to `overflow: ellipsis` and `maxLines: 1`. Use `AppText.body()` for multi-line.

## Guidelines

1. Prefer `AppScrollView` or `SingleChildScrollView` for form-like and variable-content pages.
2. Use `Flexible` / `Expanded` in `Column`/`Row` so children can shrink; avoid unbounded height.
3. Use `AppText` or `overflow: TextOverflow.ellipsis` for text in cards and list items.
4. Use `ScreenUtils.wp` / `hp` / `sp` for responsive dimensions instead of fixed values where appropriate.
