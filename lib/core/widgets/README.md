# Core Widgets

This directory contains reusable widgets used throughout the app.

## Loaders

### FullScreenLoader

A full-screen loader with rotating app icon and loading dots. Use for full-screen loading states.

**Asset Required:**
- `assets/logos/habra_app_logo.png` - App logo for rotation

**Usage:**
```dart
import 'package:habra_mobile_app/core/widgets/full_screen_loader.dart';

// In your widget
if (isLoading) {
  return FullScreenLoader(
    message: 'Loading data...', // Optional message
    backgroundColor: Colors.black.withOpacity(0.3), // Optional background color
  );
}
```

**Features:**
- Rotating app logo in white circular container
- Three animated loading dots below the logo
- Optional message display
- Transparent or semi-transparent background
- Fallback to refresh icon if logo not found

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
      return FullScreenLoader(message: 'Loading data...');
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
