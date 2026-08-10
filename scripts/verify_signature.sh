#!/usr/bin/env bash
# Verifies the release APK is signed with OUR release key (rules C, J8, K1).
# Fails loudly on any debug certificate.
set -euo pipefail

APK="build/app/outputs/flutter-apk/app-release.apk"
KEYSTORE="android/app/keystore/mathbuddies-release.jks"

test -f "$APK" || { echo "::error::Release APK not found at $APK"; exit 1; }
test -f "$KEYSTORE" || { echo "::error::Keystore not found at $KEYSTORE"; exit 1; }

# Locate newest apksigner.
BUILD_TOOLS_DIR="${ANDROID_HOME:-$ANDROID_SDK_ROOT}/build-tools"
APKSIGNER=$(find "$BUILD_TOOLS_DIR" -name apksigner -type f | sort -V | tail -n 1)
test -n "$APKSIGNER" || { echo "::error::apksigner not found in $BUILD_TOOLS_DIR"; exit 1; }
echo "Using apksigner: $APKSIGNER"

VERIFY_OUT=$("$APKSIGNER" verify --verbose --print-certs "$APK")
echo "$VERIFY_OUT"

# Hard fail on any debug certificate (rejection #1 lesson).
if echo "$VERIFY_OUT" | grep -qi "Android Debug"; then
  echo "::error::APK is signed with an ANDROID DEBUG certificate - Amazon will reject it!"
  exit 1
fi

# Parse the V2 signer SHA-256 (note the "V2 Signer:" prefix - rule J8).
APK_SHA=$(echo "$VERIFY_OUT" | grep "V2 Signer: certificate SHA-256 digest:" | head -n 1 | sed 's/.*digest: *//' | tr -d '[:space:]:' | tr 'A-F' 'a-f')
test -n "$APK_SHA" || { echo "::error::Could not parse V2 signer SHA-256 from apksigner output"; exit 1; }

# Keystore's own SHA-256 for the release alias.
KS_SHA=$(keytool -list -v \
  -keystore "$KEYSTORE" \
  -storepass "$SIGNING_STORE_PASSWORD" \
  -alias "$SIGNING_KEY_ALIAS" 2>/dev/null \
  | grep -i "SHA256:" | head -n 1 | sed 's/.*SHA256: *//' | tr -d '[:space:]:' | tr 'A-F' 'a-f')
test -n "$KS_SHA" || { echo "::error::Could not read keystore SHA-256"; exit 1; }

echo "APK  V2 SHA-256: $APK_SHA"
echo "KEY  Cert SHA-256: $KS_SHA"

if [ "$APK_SHA" != "$KS_SHA" ]; then
  echo "::error::Signature MISMATCH - APK was not signed with the release keystore!"
  exit 1
fi

echo "SIGNATURE VERIFIED: release APK is signed with the private release key."
