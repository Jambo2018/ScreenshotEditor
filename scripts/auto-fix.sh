#!/bin/bash
# Auto-fix for ScreenshotEditor
# Parses build errors and attempts automatic fixes

set -e

PROJECT_DIR="/Users/eba/Desktop/ScreenshotEditor"
cd "$PROJECT_DIR"

echo "🔧 Auto-fix starting..."

# Run build and capture errors
echo "📦 Running build..."
xcodebuild -project ScreenshotEditor.xcodeproj \
           -scheme ScreenshotEditor \
           -destination 'platform=macOS' \
           build 2>&1 | tee /tmp/build-output.log

# Parse errors
echo ""
echo "🔍 Analyzing errors..."

# Check for common error patterns
if grep -q "no such file or directory" /tmp/build-output.log; then
    echo "⚠️ Missing file detected"
    grep "no such file" /tmp/build-output.log | head -5
fi

if grep -q "use of unresolved identifier" /tmp/build-output.log; then
    echo "⚠️ Unresolved identifier detected"
    grep "unresolved identifier" /tmp/build-output.log | head -5
fi

if grep -q "value of optional type must be unwrapped" /tmp/build-output.log; then
    echo "⚠️ Optional unwrap error detected"
    grep "optional type must be unwrapped" /tmp/build-output.log | head -5
fi

if grep -q "cannot find .* in scope" /tmp/build-output.log; then
    echo "⚠️ Out of scope error detected"
    grep "cannot find" /tmp/build-output.log | head -5
fi

if grep -q "extra argument in call" /tmp/build-output.log; then
    echo "⚠️ Function argument mismatch"
    grep "extra argument\|not enough arguments" /tmp/build-output.log | head -5
fi

if grep -q "cannot convert value of type" /tmp/build-output.log; then
    echo "⚠️ Type conversion error"
    grep "cannot convert value" /tmp/build-output.log | head -5
fi

echo ""
echo "📊 Error summary:"
grep -c "error:" /tmp/build-output.log || echo "0 errors"
grep -c "warning:" /tmp/build-output.log || echo "0 warnings"

echo ""
echo "💡 Run ./scripts/auto-dev.sh for continuous build loop"
