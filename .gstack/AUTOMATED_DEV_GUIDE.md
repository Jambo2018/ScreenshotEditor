# ScreenshotEditor 自动化开发指南

## 概述

这个项目配置了完整的 gstack 多角色自动化开发流程。AI 可以扮演不同角色协同工作，你只需要做最终决策。

## 可用角色

| 角色 | 命令 | 职责 |
|------|------|------|
| 🧑‍💼 **CEO/产品** | `/plan-ceo-review` | 产品方向、范围决策、优先级 |
| 🎨 **设计师** | `/plan-design-review` | UI/UX 审查、视觉一致性 |
| 👨‍💻 **工程师** | `/plan-eng-review` | 架构设计、代码质量、测试覆盖 |
| 🤖 **自动审查** | `/autoplan` | 同时运行以上 3 个角色 |
| 🧪 **QA 工程师** | `/qa` | 测试 → 修复 → 验证循环 |
| 🐛 **调试专家** | `/investigate` | 根因分析、系统调试 |
| 🚀 **发布工程师** | `/ship` | 完整发布流程 |
| 🔒 **安全专家** | `/cso` | OWASP 安全审计 |
| 📝 **技术作者** | `/document-release` | 自动更新文档 |

## 快速开始

### 开发新功能

```bash
# 1. 理解需求
/office-hours

# 2. 自动审查（可选但推荐）
/autoplan

# 3. 实现功能
[编写代码]

# 4. 自动测试修复
/qa

# 5. 发布
/ship

# 6. 更新文档
/document-release
```

### 修复 Bug

```bash
# 1. 根因分析
/investigate

# 2. 应用修复
[AI 自动修复]

# 3. 验证
/qa

# 4. 发布
/ship
```

### 代码审查

```bash
# 1. 代码审查
/review

# 2. 深度审查（可选）
/plan-eng-review

# 3. 发布
/ship
```

## 自动化工作流详解

### `/ship` 前的自动流程

当你运行 `/ship` 时，以下流程自动执行：

```
1. ✅ 预检查
   - 检测当前分支
   - 合并主分支代码
   - 检查冲突

2. ✅ 测试（/qa）
   - 运行所有 XCTest
   - 如有失败，自动修复
   - 重新验证修复
   - 生成 QA 报告

3. ✅ 代码审查
   - 运行预发布审查清单
   - 检查 SQL 安全、LLM 信任边界
   - 自动修复可修复的问题

4. ✅ 版本更新
   - 自动决定版本级别（PATCH/MINOR）
   - 更新 VERSION 文件
   - 生成 CHANGELOG

5. ✅ 提交
   - 按逻辑分割提交
   - 确保每个提交可独立编译

6. ✅ 推送
   - 推送到远程
   - 创建 Pull Request

7. ✅ 文档同步
   - 更新 README/ARCHITECTURE 等
   - 标记已完成的 TODO
```

### 测试 → 修复循环

`/qa` 技能自动执行：

```
1. 运行测试套件
   ↓
2. 分析失败
   ├─ 断言失败 → 修复逻辑
   ├─ 编译错误 → 修复导入/语法
   ├─ 运行时崩溃 → 修复 nil/边界
   └─ 超时 → 修复异步代码
   ↓
3. 应用最小修复
   ↓
4. 重新测试
   ↓
5. 如果仍失败 → 返回步骤 2（最多 3 次）
   ↓
6. 生成报告
   ↓
7. 添加回归测试
```

## 配置文件

### `.gstack/bin/qa-test-runner.sh`
自动化测试运行脚本，处理：
- 清理构建
- 运行测试
- 解析结果
- 生成报告

### `.gstack/qa-macos-skill.md`
macOS 专用 QA 技能定义

### `.gstack/qa-macos.md`
QA 流程和最佳实践文档

### `CLAUDE.md`
项目级别的开发指南（已更新自动化流程）

## 最佳实践

### 1. 小步提交
AI 会自动将大改动分解为多个小提交，每个提交：
- 逻辑完整
- 独立编译
- 包含测试

### 2. 测试优先
新增代码时，AI 会自动：
- 识别未测试的代码路径
- 生成对应的测试
- 验证测试通过

### 3. 自动修复
测试失败时，AI 会：
- 尝试自动修复（最多 3 次）
- 如果无法修复，向你报告
- 添加回归测试防止再犯

### 4. 文档同步
代码变更后，`/document-release` 自动：
- 检查 README 是否需要更新
- 更新 ARCHITECTURE 如果架构变化
- 标记 TODOS.md 中已完成的项目

## 手动触发 vs 自动触发

| 场景 | 推荐方式 |
|------|----------|
| 日常开发 | 写完代码直接 `/ship` |
| 新功能 | 先 `/autoplan` 审查，再实现，最后 `/ship` |
| Bug 修复 | `/investigate` → 修复 → `/qa` → `/ship` |
| 发布前 | `/ship` 自动处理一切 |

## 配置自动化程度

可以通过修改 `/ship` 技能的行为来调整自动化程度：

```bash
# 在 .gstack/config 中设置
gstack-config set auto_qa true      # /ship 前自动运行 /qa
gstack-config set auto_review true  # /ship 前自动运行 /review
gstack-config set auto_fix true     # 测试失败自动修复
```

## 退出自动化

任何时候想要手动控制：

```bash
# 停止当前自动化流程
Ctrl+C

# 查看当前状态
git status
.gstack/bin/qa-test-runner.sh

# 手动运行特定步骤
xcodebuild test -project ScreenshotEditor.xcodeproj -scheme ScreenshotEditor
```

## 故障排查

### 测试失败
```bash
# 查看详细错误
cat .gstack/qa-reports/qa-report-*.md

# 手动运行测试
xcodebuild test -project ScreenshotEditor.xcodeproj -scheme ScreenshotEditor
```

### 构建失败
```bash
# 清理重新构建
xcodebuild clean build -project ScreenshotEditor.xcodeproj -scheme ScreenshotEditor
```

### 自动化卡住
```bash
# 检查进程
ps aux | grep xcodebuild

# 杀掉卡住的进程
killall xcodebuild

# 清理临时文件
rm -rf /tmp/qa_tests*.txt
```

## 示例会话

### 完整的功能开发会话

```
用户：添加导出为 JPEG 的功能

AI: 让我先理解需求...
运行：/office-hours

AI: 开始审查产品方案...
运行：/plan-ceo-review

AI: 审查设计方案...
运行：/plan-design-review

AI: 审查工程方案...
运行：/plan-eng-review

[AI 实现功能]

AI: 运行测试...
运行：/qa

AI: 测试通过！准备发布...
运行：/ship

AI: 更新文档...
运行：/document-release

✅ 完成！PR: https://github.com/.../pull/123
```

## 总结

这个项目的目标是让你能够：

1. **专注于需求** — AI 处理实现细节
2. **信任质量** — 自动测试保证代码正确
3. **快速迭代** — 自动化流程减少等待
4. **减少认知负担** — 多角色 AI 帮你考虑周全

你只需要：
- 描述需求
- 审查 AI 的输出
- 做关键的品味决策

其余的交给自动化流程！
