# Auto-dev loop — runs until build and QA pass

Continuously builds, tests, and validates until all checks pass.
Auto-fixes common issues when possible.

## Usage

```bash
# Full auto-dev loop (build → test → lint → repeat)
./scripts/auto-dev.sh

# Single QA pass
./scripts/auto-qa.sh

# With gstack skill
/auto-dev
```

## What it does

1. **Build** - Runs `xcodebuild` with clean build
2. **Test** - Runs XCTest suite
3. **Lint** - Runs SwiftLint (if installed)
4. **Report** - Shows git status and generates QA report

## Configuration

Edit `scripts/auto-dev.sh`:
- `MAX_ITERATIONS` - Max loops before stopping (default: 10)
- `sleep 5` - Delay between iterations

## Auto-fix behaviors

The script will:
- Parse build errors and suggest fixes
- Identify missing files in Xcode project
- Flag Swift syntax errors with line numbers

For automatic fixes, pair with `/fix` skill.

## Example output

```
🚀 Starting auto-dev loop...
=========================================
📦 Iteration 1/10
=========================================
🔨 Building...
✅ Build succeeded
🧪 Running tests...
✅ Tests passed
🔍 Checking code quality...
✅ Lint: PASSED
✅ Iteration 1 complete
```

## Stopping

- Press `Ctrl+C` to stop mid-loop
- Set `MAX_ITERATIONS=1` for single pass
- Script exits on first build failure
