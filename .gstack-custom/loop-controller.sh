#!/bin/bash
# ScreenshotEditor - 迭代开发循环控制器
# 用法：./loop-controller.sh [start|next|status|qa|ship]

set -e

PROJECT_DIR="$HOME/Desktop/ScreenshotEditor"
STATE_FILE="$PROJECT_DIR/ITERATION_STATE.json"
TODO_FILE="$PROJECT_DIR/TODO.md"
QA_REPORTS_DIR="$PROJECT_DIR/.gstack/qa-reports"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 获取下一个待办任务
get_next_task() {
    grep -E "^\- \[ \]" "$TODO_FILE" | head -1 | sed 's/.*- \[ \] \*\*//' | sed 's/\*\*.*//'
}

# 标记任务为完成
mark_task_complete() {
    local task="$1"
    sed -i '' "s/\- \[ \] \*\*$task/\- [x] **$task/" "$TODO_FILE"
    log_success "标记任务完成：$task"
}

# 运行 QA 测试
run_qa() {
    log_info "运行 QA 测试..."
    cd "$PROJECT_DIR"
    
    mkdir -p "$QA_REPORTS_DIR"
    local report_file="$QA_REPORTS_DIR/qa-report-$(date +%Y%m%d-%H%M%S).md"
    
    # 运行测试
    if ./.gstack/bin/qa-test-runner.sh > "$report_file" 2>&1; then
        log_success "QA 测试通过"
        echo '{"status": "PASS", "timestamp": "'$(date -Iseconds)'"}' > "$QA_REPORTS_DIR/last-qa-result.json"
        return 0
    else
        log_error "QA 测试失败，查看报告：$report_file"
        echo '{"status": "FAIL", "timestamp": "'$(date -Iseconds)'", "report": "'$report_file'"}' > "$QA_REPORTS_DIR/last-qa-result.json"
        return 1
    fi
}

# 提交更改
commit_changes() {
    local message="$1"
    cd "$PROJECT_DIR"
    
    git add -A
    if git diff --cached --quiet; then
        log_warning "没有更改需要提交"
        return 0
    fi
    
    git commit -m "feat: $message"
    local commit_hash=$(git rev-parse --short HEAD)
    log_success "已提交：$commit_hash - $message"
    
    # 更新状态文件
    # (这里简化处理，实际应该用 jq 更新 JSON)
}

# 显示状态
show_status() {
    echo "=== ScreenshotEditor 迭代状态 ==="
    echo ""
    echo "📋 待办任务:"
    grep -E "^\- \[ \]" "$TODO_FILE" | head -5 | sed 's/^\- \[ \] /  ○ /' | sed 's/\*\*/  /' | sed 's/\*\*//'
    echo ""
    echo "✅ 已完成:"
    grep -E "^\- \[x\]" "$TODO_FILE" | head -5 | sed 's/^\- \[x\] /  ✓ /' | sed 's/\*\*/  /' | sed 's/\*\*//'
    echo ""
    
    if [ -f "$QA_REPORTS_DIR/last-qa-result.json" ]; then
        echo "🧪 上次 QA:"
        cat "$QA_REPORTS_DIR/last-qa-result.json"
    fi
}

# 主流程
case "${1:-status}" in
    start)
        log_info "开始迭代开发流程..."
        show_status
        ;;
    next)
        task=$(get_next_task)
        if [ -z "$task" ]; then
            log_success "所有任务已完成！🎉"
        else
            log_info "下一个任务：$task"
        fi
        ;;
    qa)
        run_qa
        ;;
    ship)
        log_info "准备发布..."
        if run_qa; then
            commit_changes "准备发布"
            log_success "发布完成"
        else
            log_error "QA 失败，无法发布"
            exit 1
        fi
        ;;
    status|*)
        show_status
        ;;
esac
