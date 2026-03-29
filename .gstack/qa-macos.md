# macOS 应用自动化 QA 流程

## 适用范围
ScreenshotEditor (macOS SwiftUI 应用)

## 测试运行命令
```bash
# 运行单元测试
xcodebuild test \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS,name=My Mac' \
  2>&1 | tee /tmp/qa_tests.txt
```

## 测试文件
- `ScreenshotEditorTests/ImageExporterTests.swift` - 图片导出逻辑测试
- `ScreenshotEditorTests/AppStateTests.swift` - 应用状态管理测试
- `ScreenshotEditorTests/ScreenshotEditorUITests.swift` - UI 测试

## 自动化流程

### 1. 测试 → 修复循环
当测试失败时：
1. 解析错误信息，定位失败原因
2. 读取对应的源代码文件
3. 应用最小修复
4. 重新运行测试验证
5. 提交修复：`git commit -m "fix(qa): 修复 {问题描述}"`

### 2. 测试覆盖范围检查
每次代码变更后，确保：
- 新增函数有对应测试
- 修改的条件分支有测试覆盖
- 错误处理路径有测试

### 3. 构建验证
```bash
# 确保项目能成功构建
xcodebuild build \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS'
```

## 常见问题修复

### 测试 Scheme 未配置测试
问题：`Scheme ScreenshotEditor is not currently configured for the test action`

修复：需要在 Xcode 中配置
1. 打开 `ScreenshotEditor.xcodeproj`
2. Product → Scheme → Edit Scheme
3. 选择 Test
4. 点击 + 添加 `ScreenshotEditorTests`

### 测试导入失败
问题：`@testable import ScreenshotEditor` 失败

修复：检查 Build Settings → Enable Testability

## /ship 前自动触发
在运行 `/ship` 之前，自动执行：
1. 运行所有测试
2. 如有失败，自动修复
3. 验证修复后测试通过
4. 生成 QA 报告

## QA 报告格式
```markdown
## QA 报告 - {日期}

### 测试结果
- 通过：N
- 失败：M (已自动修复 K 个)

### 修复记录
1. {问题} → {修复方式} (commit: {SHA})

### 构建状态
- ✅ 构建成功 / ❌ 构建失败

### 健康评分
{0-100 分}
```
