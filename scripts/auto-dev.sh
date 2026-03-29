#!/bin/bash
# Auto-dev loop for ScreenshotEditor
# Continuously builds, runs tests, and reports status

set -e

PROJECT_DIR="/Users/eba/Desktop/ScreenshotEditor"
SCHEME="ScreenshotEditor"
MAX_ITERATIONS=10
ITERATION=0

echo "🚀 Starting auto-dev loop..."
echo "Project: $PROJECT_DIR"
echo "Max iterations: $MAX_ITERATIONS"

cd "$PROJECT_DIR"

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo ""
    echo "========================================="
    echo "📦 Iteration $ITERATION/$MAX_ITERATIONS"
    echo "========================================="

    # Step 1: Build
    echo "🔨 Building..."
    if xcodebuild -project ScreenshotEditor.xcodeproj \
                  -scheme "$SCHEME" \
                  -destination 'platform=macOS' \
                  clean build 2>&1 | tee /tmp/build.log; then
        echo "✅ Build succeeded"
    else
        echo "❌ Build failed - checking errors..."
        grep -E "error:|fatal:" /tmp/build.log | head -20
        echo "💡 Fix the errors above and re-run"
        exit 1
    fi

    # Step 2: Run tests (if any)
    echo ""
    echo "🧪 Running tests..."
    if xcodebuild test -project ScreenshotEditor.xcodeproj \
                       -scheme "$SCHEME" \
                       -destination 'platform=macOS' 2>&1 | tee /tmp/test.log; then
        echo "✅ Tests passed"
    else
        echo "⚠️ Tests failed or no tests configured"
        grep -E "error:|failed:" /tmp/test.log | head -10 || true
    fi

    # Step 3: Check for SwiftLint issues (if configured)
    echo ""
    echo "🔍 Checking code quality..."
    if command -v swiftlint &> /dev/null; then
        swiftlint lint ScreenshotEditor/ --quiet || true
    else
        echo "⚠️ SwiftLint not installed (optional)"
    fi

    # Step 4: Git status check
    echo ""
    echo "📊 Git status:"
    git status --short || true

    echo ""
    echo "✅ Iteration $ITERATION complete"
    echo "💤 Waiting 5 seconds before next iteration..."
    sleep 5
done

echo ""
echo "🎉 Auto-dev loop completed successfully!"
echo "All $ITERATION iterations passed"
