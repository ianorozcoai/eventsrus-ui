#!/bin/sh
# Writes ios/Flutter/Google.xcconfig from the (public) iOS Google OAuth client id.
# Usage: tool/write_google_xcconfig.sh 1234-abcd.apps.googleusercontent.com
# With no argument, or an empty one, the committed placeholder file is left alone.
set -eu
CLIENT_ID="${1:-}"
if [ -z "$CLIENT_ID" ]; then
  echo "No GOOGLE_IOS_CLIENT_ID given: Google Sign-In stays unconfigured in this build."
  exit 0
fi
PREFIX="${CLIENT_ID%.apps.googleusercontent.com}"
if [ "$PREFIX" = "$CLIENT_ID" ]; then
  echo "GOOGLE_IOS_CLIENT_ID must end with .apps.googleusercontent.com" >&2
  exit 1
fi
cat > "$(dirname "$0")/../ios/Flutter/Google.xcconfig" <<EOF
GOOGLE_IOS_CLIENT_ID = $CLIENT_ID
GOOGLE_IOS_REVERSED_CLIENT_ID = com.googleusercontent.apps.$PREFIX
EOF
echo "Wrote ios/Flutter/Google.xcconfig"
