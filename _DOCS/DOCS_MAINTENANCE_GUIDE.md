# 📚 Documentation Maintenance Guide

*Hướng dẫn duy trì và cập nhật tài liệu*

---

## 🔄 Quy Trình Cập Nhật Tài Liệu

### Khi Nào Cần Cập Nhật?

| Trigger | Docs cần update |
|---------|-----------------|
| Thêm feature mới | `02-FEATURES/`, `07-API/`, `CHANGELOG.md` |
| Fix bug quan trọng | `CHANGELOG.md`, doc liên quan |
| Thay đổi database | `08-DATABASE/DATABASE_SCHEMA.md` |
| Thay đổi API | `07-API/API_REFERENCE.md` |
| Release version mới | `INDEX.md`, `00-START-HERE.md`, `CHANGELOG.md` |
| Thay đổi kiến trúc | `01-ARCHITECTURE/` |

---

## 🛠️ Công Cụ Tự Động

### 1. Check Docs Status

```bash
cd D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app
node scripts/docs-auto-updater.js --check
```

Output:
- Danh sách docs cần update
- Health check issues
- Recent commits

### 2. Auto-Update Version

```bash
node scripts/docs-auto-updater.js --update
```

Tự động update:
- Version number trong INDEX.md
- Version trong 00-START-HERE.md
- Last Updated date

### 3. Generate Changelog

```bash
node scripts/docs-auto-updater.js --changelog
```

Tự động:
- Đọc git commits
- Phân loại (features, fixes)
- Generate changelog section

---

## 📖 Xem Tài Liệu

### Option 1: VS Code (Đơn Giản)

1. Mở file `.md` trong VS Code
2. Press `Ctrl+Shift+V` để preview

### Option 2: Local Web Server

```bash
cd _DOCS
python -m http.server 8080
```

Mở: http://localhost:8080/docs-viewer.html

### Option 3: Tích Hợp vào Admin Dashboard

Docs có thể được serve qua API:
- Endpoint: `GET /api/docs/:path`
- Frontend: React Markdown renderer

---

## 📝 Quy Tắc Viết Tài Liệu

### File Naming

```
✅ FEATURE_NAME_COMPLETE.md
✅ SYSTEM_ARCHITECTURE.md
✅ API_REFERENCE.md

❌ feature.md (quá ngắn)
❌ my-feature.md (dùng underscore)
❌ Feature Name.md (có space)
```

### Structure Template

```markdown
# 📄 [Title]

*Mô tả ngắn về nội dung*

---

## 🎯 Overview
[Giới thiệu tổng quan]

## ✨ Features / Content
[Nội dung chính]

## 🔧 Technical Details
[Chi tiết kỹ thuật]

## 📚 Related Documentation
[Links đến docs liên quan]

---
*Last Updated: [Date]*
```

### Emoji Guidelines

| Category | Emoji |
|----------|-------|
| Start/Overview | 🎯 🚀 📖 |
| Features | ✨ 🆕 |
| Architecture | 🏗️ 📐 |
| Database | 🗄️ 💾 |
| API | 🔌 📡 |
| Deployment | 🚀 📦 |
| Warning | ⚠️ ❌ |
| Success | ✅ ✓ |
| Code | 💻 🔧 |
| Info | ℹ️ 💡 |

---

## 🔄 CI/CD Integration

### GitHub Actions (Optional)

```yaml
# .github/workflows/docs.yml
name: Documentation

on:
  push:
    paths:
      - 'lib/**'
      - 'pubspec.yaml'

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check Docs Status
        run: node scripts/docs-auto-updater.js --check
      
      - name: Update Version
        run: node scripts/docs-auto-updater.js --update
      
      - name: Commit Changes
        run: |
          git config user.name 'GitHub Action'
          git config user.email 'action@github.com'
          git add _DOCS/
          git commit -m "docs: auto-update documentation" || exit 0
          git push
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
node scripts/docs-auto-updater.js --check

# Check if important files changed
if git diff --cached --name-only | grep -E "(lib/|pubspec.yaml)"; then
  echo "⚠️ Code changed. Consider updating docs!"
fi
```

---

## 📊 Documentation Metrics

### Coverage Goals

| Area | Target | Current |
|------|--------|---------|
| Architecture | 100% | ✅ |
| Core Features | 100% | ✅ |
| API Endpoints | 90% | ✅ |
| Database Tables | 100% | ✅ |
| Deployment | 100% | ✅ |

### Quality Checklist

- [ ] Có emoji để dễ scan
- [ ] Có table of contents (cho file dài)
- [ ] Có code examples
- [ ] Có related links
- [ ] Updated date
- [ ] Không có broken links

---

## 🆘 FAQ

### Q: Ai chịu trách nhiệm update docs?

**A:** Developer làm feature đó chịu trách nhiệm update docs tương ứng. Review docs là một phần của code review.

### Q: Docs lưu ở đâu?

**A:** Tất cả trong `_DOCS/` folder. KHÔNG tạo docs ở root folder.

### Q: Khi nào chạy docs-auto-updater?

**A:** 
- Trước mỗi release
- Sau khi merge PR lớn
- Hàng tuần (maintenance)

### Q: Làm sao để tìm docs cần update?

**A:** Chạy `node scripts/docs-auto-updater.js --check`

---

## 📞 Support

- **Questions:** Hỏi trong team chat
- **Issues:** Tạo issue với label `documentation`
- **Suggestions:** PR welcome!

---

*Documentation is a feature, not an afterthought.*
