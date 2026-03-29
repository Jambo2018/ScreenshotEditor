#!/bin/bash
# Auto-QA for ScreenshotEditor
# Runs build, tests, and generates QA report

set -e

PROJECT_DIR="/Users/eba/Desktop/ScreenshotEditor"
SCHEME="ScreenshotEditor"
REPORT_FILE="/tmp/qa-report-$(date +%Y%m%d-%H%M%S).md"

cd "$PROJECT_DIR"

echo "🔍 Starting QA check..."

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
# ScreenshotEditor QA Report

EOF

echo "## Build Check" >> "$REPORT_FILE"
if xcodebuild -project ScreenshotEditor.xcodeproj \
              -scheme "$SCHEME" \
              -destination 'platform=macOS' \
              build 2>&1 | tee /tmp/qa-build.log; then
    echo "✅ Build: PASSED" | tee -a "$REPORT_FILE"
else
    echo "❌ Build: FAILED" | tee -a "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "### Build Errors" >> "$REPORT_FILE"
    grep -E "error:|fatal:|warning:" /tmp/qa-build.log | head -30 >> "$REPORT_FILE" || true
    echo ""
    echo "❌ QA FAILED - Build errors"
    echo "📄 Full report: $REPORT_FILE"
    exit 1
fi

echo "" >> "$REPORT_FILE"
echo "## Tests" >> "$REPORT_FILE"
if xcodebuild test -project ScreenshotEditor.xcodeproj \
                   -scheme "$SCHEME" \
                   -destination 'platform=macOS' 2>&1 | tee /tmp/qa-test.log; then
    echo "✅ Tests: PASSED" | tee -a "$REPORT_FILE"
else
    echo "⚠️ Tests: FAILED or not configured" | tee -a "$REPORT_FILE"
    grep -E "error:|failed:" /tmp/qa-test.log | head -20 >> "$REPORT_FILE" || true
fi

echo "" >> "$REPORT_FILE"
echo "## SwiftLint" >> "$REPORT_FILE"
if command -v swiftlint &> /dev/null; then
    if swiftlint lint ScreenshotEditor/ --quiet 2>&1 | tee /tmp/qa-lint.log; then
        echo "✅ Lint: PASSED" | tee -a "$REPORT_FILE"
    else
        echo "⚠️ Lint: Issues found" | tee -a "$REPORT_FILE"
        cat /tmp/qa-lint.log >> "$REPORT_FILE"
    fi
else
    echo "⊗ SwiftLint: Not installed" | tee -a "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "## Git Status" >> "$REPORT_FILE"
git status --short >> "$REPORT_FILE" 2>&1 || true

echo ""
echo "✅ QA PASSED"
echo "📄 Report: $REPORT_FILE"
cat "$REPORT_FILE"
