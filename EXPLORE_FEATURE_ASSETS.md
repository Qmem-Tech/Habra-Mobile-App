# Explore Feature - Assets

This document lists the image assets used for the Explore feature.

## Business Images

Located in `assets/images/businesses/`:

1. `cultural_night_hero.png` - Used for businesses (rotated)
2. `cultural_night.png` - Used for businesses (rotated)
3. `teddy_afro_concert.png` - Used for businesses (rotated)

These 3 images are rotated/repeated across all businesses in the app.

## Deal Images

Located in `assets/images/deals/`:

1. `cultural_night_hero.png` - Used for deals (rotated)
2. `cultural_night.png` - Used for deals (rotated)
3. `teddy_afro_concert.png` - Used for deals (rotated)

These 3 images are rotated/repeated across all deals in the app.

## Implementation

The mock data uses helper methods `_getBusinessImage(index)` and `_getDealImage(index)` to cycle through the available images. The images are assigned based on the index modulo the number of available images, ensuring all images are used in a rotating pattern.

## Notes

- Images are automatically rotated/repeated across multiple businesses and deals

- The app uses error builders to handle missing images gracefully (shows placeholder icons)

- All images should be optimized for mobile display
- Recommended dimensions:
  - Business cards: 280x140px
  - Deal cards: 280x120px
  - Business list items: 80x80px
  - Business detail hero: Full width, ~250px height





























