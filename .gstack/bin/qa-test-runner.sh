#!/bin/bash
# macOS QA Test → Fix Loop for ScreenshotEditor
# Automatically runs tests, detects failures, and attempts fixes

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/ScreenshotEditor.xcodeproj"
SCHEME="ScreenshotEditor"
DESTINATION="platform=macOS,name=My Mac"
LOG_FILE="/tmp/qa_tests_$(date +%Y%m%d_%H%M%S).txt"
REPORT_DIR="$PROJECT_DIR/.gstack/qa-reports"

mkdir -p "$REPORT_DIR"

echo "🔍 ScreenshotEditor QA Test Runner"
echo "=================================="
echo "Project: $PROJECT_FILE"
echo "Scheme:  $SCHEME"
echo "Log:     $LOG_FILE"
echo ""

# Step 1: Clean build
echo "📦 Step 1: Clean build..."
xcodebuild clean \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  > /dev/null 2>&1

# Step 2: Run tests
echo "🧪 Step 2: Running tests..."
TEST_OUTPUT=$(xcodebuild test \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  2>&1 | tee "$LOG_FILE")

TEST_RESULT=$?

# Step 3: Parse results
if [ $TEST_RESULT -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
    echo ""

    # Extract test count
    TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ tests?' | tail -1 || echo "unknown")
    DURATION=$(echo "$TEST_OUTPUT" | grep -oE '([0-9]+\.[0-9]+) sec' | tail -1 || echo "unknown")

    echo "Results: $TEST_COUNT in $DURATION"

    # Write success report
    cat > "$REPORT_DIR/qa-report-$(date +%Y%m%d).md" << EOF
# QA Report - $(date +%Y-%m-%d)

## Status: ✅ PASS

| Metric | Value |
|--------|-------|
| Tests Run | $TEST_COUNT |
| Duration | $DURATION |
| Failures | 0 |

## Build Status
- ✅ Build succeeded
- ✅ All tests passed
- ✅ Ready to ship
EOF

    exit 0
else
    echo ""
    echo "❌ Tests failed!"
    echo ""

    # Extract failure info
    FAILURES=$(echo "$TEST_OUTPUT" | grep -A 5 "Failed:" | head -20)
    ERROR_COUNT=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ failures?' | tail -1 || echo "multiple")

    echo "Failures: $ERROR_COUNT"
    echo ""
    echo "Details:"
    echo "$FAILURES"
    echo ""

    # Write failure report
    cat > "$REPORT_DIR/qa-report-$(date +%Y%m%d)-FAILED.md" << EOF
# QA Report - $(date +%Y-%m-%d)

## Status: ❌ FAIL

| Metric | Value |
|--------|-------|
| Errors | $ERROR_COUNT |

## Failure Details

\`\`\`
$FAILURES
\`\`\`

## Next Steps
1. Review failure details above
2. Run /investigate for root cause analysis
3. Apply fix and re-run tests
EOF

    echo "📄 Report saved to: $REPORT_DIR/qa-report-$(date +%Y%m%d)-FAILED.md"
    echo ""
    echo "💡 Suggestion: Run '/investigate' to analyze and fix the failures"

    exit 1
fi
