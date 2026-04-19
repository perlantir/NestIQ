#!/usr/bin/env sh
# Restore Xcode-compatible @2x / @3x / .5 filenames
# Run from this directory before dragging AppIcon.appiconset into Xcode.

cd "$(dirname "$0")/AppIcon.appiconset" || exit 1

mv "Icon-20-2x.png"        "Icon-20@2x.png"        2>/dev/null
mv "Icon-20-3x.png"        "Icon-20@3x.png"        2>/dev/null
mv "Icon-29-2x.png"        "Icon-29@2x.png"        2>/dev/null
mv "Icon-29-3x.png"        "Icon-29@3x.png"        2>/dev/null
mv "Icon-40-2x.png"        "Icon-40@2x.png"        2>/dev/null
mv "Icon-40-3x.png"        "Icon-40@3x.png"        2>/dev/null
mv "Icon-60-2x.png"        "Icon-60@2x.png"        2>/dev/null
mv "Icon-60-3x.png"        "Icon-60@3x.png"        2>/dev/null
mv "Icon-20-2x-ipad.png"   "Icon-20@2x~ipad.png"   2>/dev/null
mv "Icon-29-2x-ipad.png"   "Icon-29@2x~ipad.png"   2>/dev/null
mv "Icon-40-2x-ipad.png"   "Icon-40@2x~ipad.png"   2>/dev/null
mv "Icon-76-2x.png"        "Icon-76@2x.png"        2>/dev/null
mv "Icon-83-5-2x.png"      "Icon-83.5@2x.png"      2>/dev/null

echo "Done. AppIcon.appiconset is ready to drag into Xcode."
