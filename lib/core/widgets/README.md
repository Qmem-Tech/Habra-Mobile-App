# Core Widgets

This directory contains reusable widgets used throughout the app.

## Responsive & Overflow Prevention

### AppText

Text with overflow-safe defaults (`TextOverflow.ellipsis`, `maxLines: 1`). Use in cards, list items, and constrained layouts to avoid overflow on small devices.

```dart
import 'package:habra_mobile_app/core/widgets/app_text.dart';

// Single-line with ellipsis (default)
AppText('Title that may be long')

// Multi-line (no ellipsis)
AppText.body('Long description...')
```

### AppScrollView & ResponsiveScaffold

See `core/responsive/` for [AppScrollView] and [ResponsiveScaffold]. Use for form-like pages and scrollable bodies to prevent overflow.

## Loaders

### HabraCircularLoader

A unified circular loader with rotating app icon. Can be used for both inline and full-screen loading states.

**Asset Required:**
- `assets/logos/habra_app_logo.png` - App logo for rotation

**Usage:**

**Full-Screen Loading:**
```dart
import 'package:habra_mobile_app/core/widgets/habra_circular_loader.dart';

// In your widget
if (isLoading) {
  return HabraCircularLoader(
    fullScreen: true,
    message: 'Loading data...', // Optional message
    backgroundColor: Colors.black.withOpacity(0.3), // Optional background color
  );
}
```

**Inline Loading:**
```dart
// Default size (60px)
const HabraCircularLoader()

// Custom size
const HabraCircularLoader(size: 40)

// In a button or small space
const HabraCircularLoader(size: 24)
```

**Features:**
- Rotating app logo in white circular container
- Optional message display (full-screen mode only)
- Transparent or semi-transparent background (full-screen mode)
- Customizable size and color
- Fallback to refresh icon if logo not found
- Works for both inline and full-screen scenarios

### PulsingLoader

A pulsing loader using the app icon. Use for smaller loading states (buttons, cards, inline loading).

**Asset Required:**
- `assets/logos/habra_app_logo.png` - App logo for pulsing

**Usage:**
```dart
import 'package:habra_mobile_app/core/widgets/pulsing_loader.dart';

// In your widget
if (isLoading) {
  return PulsingLoader(
    size: 40, // Optional, defaults to 40
    color: AppColors.brandPrimary, // Optional, defaults to brand primary
  );
}
```

**Features:**
- Pulsing/scaling animation
- Opacity animation for smooth effect
- Circular white background with shadow
- Customizable size and color
- Fallback to refresh icon if logo not found

### LoaderHelper

Helper class for showing/hiding full-screen loader programmatically.

**Usage:**
```dart
import 'package:habra_mobile_app/core/widgets/loader_helper.dart';

// Show loader
LoaderHelper.show(context, message: 'Loading...');

// Hide loader
LoaderHelper.hide(context);
```

## Example Usage

### Full-Screen Loading in BlocBuilder
```dart
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    if (state is MyLoading) {
      return HabraCircularLoader(fullScreen: true, message: 'Loading data...');
    }
    // ... rest of UI
  },
)
```

### Inline Loading with PulsingLoader
```dart
ElevatedButton(
  onPressed: isLoading ? null : _handleAction,
  child: isLoading
      ? const PulsingLoader(size: 20)
      : const Text('Submit'),
)
```

### Programmatic Loading
```dart
// Start loading
LoaderHelper.show(context, message: 'Processing...');

try {
  await performOperation();
} finally {
  // Always hide loader
  LoaderHelper.hide(context);
}
```
