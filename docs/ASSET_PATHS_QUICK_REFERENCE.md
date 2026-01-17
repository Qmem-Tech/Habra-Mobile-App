# Asset Paths Quick Reference

## 📍 Required Asset Locations

Place your downloaded assets from Figma in these exact locations:

### Logos
```
assets/logos/app_logo.png          ← Main app logo (hexagonal design)
assets/logos/splash_logo.png       ← Splash screen logo
```

### Onboarding Illustrations
```
assets/images/onboarding/onboarding_1_music_festival.png    ← "Discover Your Community"
assets/images/onboarding/onboarding_2_coffee_shop.png       ← "Support Local Businesses"
assets/images/onboarding/onboarding_3_grow_together.png    ← "Grow Together"
```

### Icons
```
assets/icons/ic_close.png          ← Close/Skip icon for onboarding
```

## ✅ Quick Checklist

- [ ] Create `assets/` folder in project root
- [ ] Create subfolders: `images/onboarding/`, `icons/`, `logos/`
- [ ] Download assets from Figma
- [ ] Rename files to match exactly (case-sensitive!)
- [ ] Place files in correct directories
- [ ] Run `flutter pub get`
- [ ] Test app

## 🔍 Verify in Code

All assets are referenced in:
- `lib/core/resources/app_assets.dart`

You can search for `AppAssets.` to see all asset references.

## 📝 File Naming Rules

- Use lowercase with underscores: `onboarding_1_music_festival.png`
- No spaces in file names
- Case-sensitive (must match exactly)
- Use `.png` extension (or `.svg` for logos if vector)

---

**See `ASSETS_GUIDE.md` for detailed instructions.**
