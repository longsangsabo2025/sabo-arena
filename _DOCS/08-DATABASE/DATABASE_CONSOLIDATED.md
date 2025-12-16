# 🗄️ DATABASE & SCHEMA

*Tổng hợp từ 8 tài liệu nguồn*

---

## 📋 Mục Lục

- 1. [Kiến Trúc & Architecture](#kiến-trúc--architecture)
- 2. [Implementation & Code](#implementation--code)
- 3. [Database & Schema](#database--schema)
- 4. [Bug Fixes & Issues](#bug-fixes--issues)
- 5. [Tài Liệu Nguồn](#tài-liệu-nguồn)

---

## 🏗️ Kiến Trúc & Architecture

### 📄 APPBAR_MIGRATION_STATUS.md

**Key Points:**
## ✅ Đã hoàn thành (10/~80 màn hình)
### 1. PostDetailScreen ✅
- **File**: `lib/presentation/post_detail_screen/post_detail_screen.dart`
- **Method**: `AppBarTheme.buildAppBar()`
- **Features**: Gradient title, lazy loading posts
### 2. OtherUserProfileScreen ✅
- **File**: `lib/presentation/other_user_profile_screen/other_user_profile_screen.dart`
- **Method**: `CustomAppBar()`
- **Features**: Simple title
### 3. TournamentListScreen ✅

### 📄 MATCH_SCHEMA_STANDARDIZATION.md

**Key Points:**
## 🎯 Mục tiêu
## 📊 Schema Mới Đề Xuất
### Thêm Columns:
### Giải thích các trường:
#### 1. `bracket_type` (VARCHAR(10))
- **WB**: Winner Bracket
- **LB**: Loser Bracket
- **GF**: Grand Final
- **SE**: Single Elimination (không có loser bracket)
- **RR**: Round Robin

### 📄 IOS_DESIGN_MIGRATION_METHODOLOGY.md

**Key Points:**
**Version**: 1.0
**Date**: January 15, 2025
**Purpose**: Systematic approach to migrate Flutter apps to iOS/Facebook/Instagram style
---
## 📋 Table of Contents
1. [Migration Checklist](#migration-checklist)
2. [Step-by-Step Process](#step-by-step-process)
3. [Component Conversion Guide](#component-conversion-guide)
---
## 🎯 Migration Checklist

### 📄 DATABASE_MIGRATION_QUICK_FIX.md

**Key Points:**
## Lỗi gặp phải và đã fix:
**Lỗi:** `syntax error at or near "NOT"` ở dòng `CREATE POLICY IF NOT EXISTS`
**Nguyên nhân:** Supabase PostgreSQL không support `IF NOT EXISTS` cho `CREATE POLICY`
**Giải pháp:** Đã tạo file migration đơn giản hơn, bỏ phần policies (không cần thiết)
---
## ✅ Cách chạy migration (2 phút):
### Bước 1: Copy SQL
1. Mở file: `database/migrations/add_video_support_SIMPLE.sql`
2. Select ALL (Ctrl+A)
3. Copy (Ctrl+C)

### 📄 FIX_RLS_POLICY_COMMUNITY_TAB.md

**Key Points:**
## ✅ VẤN ĐỀ ĐÃ TÌM RA:
**Root Cause:** RLS Policy đang chặn anon key không xem được trận accepted!
---
## 🎯 GIẢI PHÁP - THÊM RLS POLICY:
### **Cách 1: Supabase SQL Editor (RECOMMENDED)**
1. Vào **Supabase Dashboard**
2. Click **SQL Editor** (icon ⚡)
3. New query
-- Drop policy cũ nếu có
-- Tạo policy mới: Cho phép xem tất cả challenges

---

## 💻 Implementation & Code

### 📄 APPBAR_MIGRATION_STATUS.md

**Key Points:**
## ✅ Đã hoàn thành (10/~80 màn hình)
### 1. PostDetailScreen ✅
- **File**: `lib/presentation/post_detail_screen/post_detail_screen.dart`
- **Method**: `AppBarTheme.buildAppBar()`
- **Features**: Gradient title, lazy loading posts
### 2. OtherUserProfileScreen ✅
- **File**: `lib/presentation/other_user_profile_screen/other_user_profile_screen.dart`
- **Method**: `CustomAppBar()`
- **Features**: Simple title
### 3. TournamentListScreen ✅

### 📄 MATCH_SCHEMA_STANDARDIZATION.md

**Key Points:**
## 🎯 Mục tiêu
## 📊 Schema Mới Đề Xuất
### Thêm Columns:
### Giải thích các trường:
#### 1. `bracket_type` (VARCHAR(10))
- **WB**: Winner Bracket
- **LB**: Loser Bracket
- **GF**: Grand Final
- **SE**: Single Elimination (không có loser bracket)
- **RR**: Round Robin

### 📄 DEPLOY_DATABASE_MANUAL.md

**Key Points:**
## 📍 **LÀM THEO 4 BƯỚC:**
### **BƯỚC 1: MỞ SUPABASE DASHBOARD** (10 giây)
1. Vào https://supabase.com/dashboard
2. Click vào project **mogjjvscxjwvhtpkrlqr**
---
### **BƯỚC 2: VÀO SQL EDITOR** (5 giây)
1. Nhìn sidebar bên trái
2. Click **"SQL Editor"** (biểu tượng `</>`)
3. Click **"New Query"** (nút xanh ở góc trên phải)
---

### 📄 IOS_DESIGN_MIGRATION_METHODOLOGY.md

**Key Points:**
**Version**: 1.0
**Date**: January 15, 2025
**Purpose**: Systematic approach to migrate Flutter apps to iOS/Facebook/Instagram style
---
## 📋 Table of Contents
1. [Migration Checklist](#migration-checklist)
2. [Step-by-Step Process](#step-by-step-process)
3. [Component Conversion Guide](#component-conversion-guide)
---
## 🎯 Migration Checklist

### 📄 MIGRATION_INSTRUCTIONS.md

**Key Points:**
1. Mở https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr
2. Vào SQL Editor (bên trái menu)
3. Copy toàn bộ SQL bên dưới
-- SPA CHALLENGE SYSTEM MIGRATION
-- Copy từ đây ↓
-- 1. EXTEND MATCHES TABLE
-- Values: tournament, friendly, challenge, spa_challenge, practice
-- Values: none, challenge_sent, challenge_received, friend_invite, auto_match
-- Values: none, spa_points, tournament_prize, bragging_rights
-- SPA bonus points at stake (100, 500, 1000, etc.)

---

## 🗄️ Database & Schema

### 📄 APPBAR_MIGRATION_STATUS.md

**Key Points:**
## ✅ Đã hoàn thành (10/~80 màn hình)
### 1. PostDetailScreen ✅
- **File**: `lib/presentation/post_detail_screen/post_detail_screen.dart`
- **Method**: `AppBarTheme.buildAppBar()`
- **Features**: Gradient title, lazy loading posts
### 2. OtherUserProfileScreen ✅
- **File**: `lib/presentation/other_user_profile_screen/other_user_profile_screen.dart`
- **Method**: `CustomAppBar()`
- **Features**: Simple title
### 3. TournamentListScreen ✅

### 📄 MATCH_SCHEMA_STANDARDIZATION.md

**Key Points:**
## 🎯 Mục tiêu
## 📊 Schema Mới Đề Xuất
### Thêm Columns:
### Giải thích các trường:
#### 1. `bracket_type` (VARCHAR(10))
- **WB**: Winner Bracket
- **LB**: Loser Bracket
- **GF**: Grand Final
- **SE**: Single Elimination (không có loser bracket)
- **RR**: Round Robin

### 📄 DEPLOY_DATABASE_MANUAL.md

**Key Points:**
## 📍 **LÀM THEO 4 BƯỚC:**
### **BƯỚC 1: MỞ SUPABASE DASHBOARD** (10 giây)
1. Vào https://supabase.com/dashboard
2. Click vào project **mogjjvscxjwvhtpkrlqr**
---
### **BƯỚC 2: VÀO SQL EDITOR** (5 giây)
1. Nhìn sidebar bên trái
2. Click **"SQL Editor"** (biểu tượng `</>`)
3. Click **"New Query"** (nút xanh ở góc trên phải)
---

### 📄 IOS_DESIGN_MIGRATION_METHODOLOGY.md

**Key Points:**
**Version**: 1.0
**Date**: January 15, 2025
**Purpose**: Systematic approach to migrate Flutter apps to iOS/Facebook/Instagram style
---
## 📋 Table of Contents
1. [Migration Checklist](#migration-checklist)
2. [Step-by-Step Process](#step-by-step-process)
3. [Component Conversion Guide](#component-conversion-guide)
---
## 🎯 Migration Checklist

### 📄 MIGRATION_INSTRUCTIONS.md

**Key Points:**
1. Mở https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr
2. Vào SQL Editor (bên trái menu)
3. Copy toàn bộ SQL bên dưới
-- SPA CHALLENGE SYSTEM MIGRATION
-- Copy từ đây ↓
-- 1. EXTEND MATCHES TABLE
-- Values: tournament, friendly, challenge, spa_challenge, practice
-- Values: none, challenge_sent, challenge_received, friend_invite, auto_match
-- Values: none, spa_points, tournament_prize, bragging_rights
-- SPA bonus points at stake (100, 500, 1000, etc.)

---

## 🔧 Bug Fixes & Issues

### 📄 IOS_DESIGN_MIGRATION_METHODOLOGY.md

**Key Points:**
**Version**: 1.0
**Date**: January 15, 2025
**Purpose**: Systematic approach to migrate Flutter apps to iOS/Facebook/Instagram style
---
## 📋 Table of Contents
1. [Migration Checklist](#migration-checklist)
2. [Step-by-Step Process](#step-by-step-process)
3. [Component Conversion Guide](#component-conversion-guide)
---
## 🎯 Migration Checklist

### 📄 DATABASE_MIGRATION_QUICK_FIX.md

**Key Points:**
## Lỗi gặp phải và đã fix:
**Lỗi:** `syntax error at or near "NOT"` ở dòng `CREATE POLICY IF NOT EXISTS`
**Nguyên nhân:** Supabase PostgreSQL không support `IF NOT EXISTS` cho `CREATE POLICY`
**Giải pháp:** Đã tạo file migration đơn giản hơn, bỏ phần policies (không cần thiết)
---
## ✅ Cách chạy migration (2 phút):
### Bước 1: Copy SQL
1. Mở file: `database/migrations/add_video_support_SIMPLE.sql`
2. Select ALL (Ctrl+A)
3. Copy (Ctrl+C)

### 📄 FIX_RLS_POLICY_COMMUNITY_TAB.md

**Key Points:**
## ✅ VẤN ĐỀ ĐÃ TÌM RA:
**Root Cause:** RLS Policy đang chặn anon key không xem được trận accepted!
---
## 🎯 GIẢI PHÁP - THÊM RLS POLICY:
### **Cách 1: Supabase SQL Editor (RECOMMENDED)**
1. Vào **Supabase Dashboard**
2. Click **SQL Editor** (icon ⚡)
3. New query
-- Drop policy cũ nếu có
-- Tạo policy mới: Cho phép xem tất cả challenges

### 📄 HOW_TO_FIX_RLS.md

**Key Points:**
## ⚠️ VẤN ĐỀ HIỆN TẠI
1. **chat_messages** có 7 policies (duplicate) → Cần 4 policies
2. **chat_rooms** policy chặn conversation list query → Cần fix policy
## ✅ GIẢI PHÁP (5 PHÚT)
### Bước 1: Mở Supabase Dashboard
1. Vào: **https://mogjjvscxjwvhtpkrlqr.supabase.co**
2. Login
3. Click vào project "saboarenav4"
### Bước 2: Mở SQL Editor
1. Sidebar bên trái → Click **"SQL Editor"**

---

## 📚 Tài Liệu Nguồn

Tổng cộng 8 tài liệu:

- `APPBAR_MIGRATION_STATUS.md` *[Architecture, Code, Database]*
- `DATABASE_MIGRATION_QUICK_FIX.md` *[Architecture, Code, Database, Fix]*
- `DEPLOY_DATABASE_MANUAL.md` *[Code, Database]*
- `FIX_RLS_POLICY_COMMUNITY_TAB.md` *[Architecture, Code, Database, Fix]*
- `HOW_TO_FIX_RLS.md` *[Code, Database, Fix]*
- `IOS_DESIGN_MIGRATION_METHODOLOGY.md` *[Architecture, Code, Database, Fix]*
- `MATCH_SCHEMA_STANDARDIZATION.md` *[Architecture, Code, Database]*
- `MIGRATION_INSTRUCTIONS.md` *[Code, Database]*

---

*Document generated by analyze_and_consolidate_docs.py*
