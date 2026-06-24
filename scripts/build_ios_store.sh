#!/usr/bin/env bash
# Build an App Store / TestFlight IPA with Supabase and other keys baked in.
# Usage (from Habra-Mobile-App/):
#   ./scripts/build_ios_store.sh
#   ./scripts/build_ios_store.sh path/to/custom_defines.json

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFINES_FILE="${1:-dart_defines.json}"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "error: $DEFINES_FILE not found." >&2
  echo "Copy dart_defines.example.json to dart_defines.json and fill in your keys." >&2
  exit 1
fi

echo "Building release IPA with --dart-define-from-file=$DEFINES_FILE"
flutter build ipa --release --dart-define-from-file="$DEFINES_FILE"

echo ""
echo "Done. Upload the IPA with Apple Transporter or Xcode Organizer:"
echo "  open build/ios/ipa"
