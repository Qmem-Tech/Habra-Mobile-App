# Business Address Input

The app supports 4 ways to add a business address:

## 1. Use Current Location
- Requests location permission
- Gets GPS coordinates
- Reverse geocodes to street, city, state, ZIP
- Fills all address fields automatically

## 2. Search Address
- User types a full address (e.g. "123 Main St, Washington DC")
- Taps **Search**
- Geocodes the address and fills the fields

**Optional: Google Places Autocomplete**  
For real-time address suggestions as the user types, add:
```yaml
dependencies:
  google_places_autocomplete: ^2.1.2
```
Then enable **Places API** in Google Cloud Console and add `GOOGLE_PLACES_API_KEY` to `ios/Runner/Info.plist`.  
Note: The package requires min Android SDK 28 and iOS 17.

## 3. Pick on Map
- Opens a full-screen map
- User taps to set a pin (or drags the marker)
- Reverse geocodes to fill address fields
- "Use this address" confirms the selection

## 4. Paste Google Maps Link
- User copies a Google Maps link (e.g. from sharing)
- Taps **Paste link**
- App reads from clipboard and parses coordinates
- Reverse geocodes to fill address fields

**Supported link formats:**
- `https://www.google.com/maps/place/.../@lat,lng,...`
- `https://www.google.com/maps/?q=lat,lng`
- `https://www.google.com/maps/search/?query=lat,lng`
- `...!3dlat!4dlng...`

## Where It's Used
- **Business Location Step 2** (new business flow)
- **Add Location** (new location for existing brand)
- **Edit Business** (edit business profile)
