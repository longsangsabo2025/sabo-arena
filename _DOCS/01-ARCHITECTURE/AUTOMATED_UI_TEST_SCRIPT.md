# 🤖 AUTOMATED UI TEST SCRIPT - SABO Arena

## 📋 Hướng dẫn sử dụng

Script này giúp bạn test tự động các tính năng chính của app bằng cách chạy app và kiểm tra logs.

---

## 🚀 BƯỚC 1: CHẠY APP VÀ MONITOR LOGS

```powershell
# Terminal 1: Chạy app
cd "D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app"
flutter run --dart-define-from-file=env.json

# Terminal 2: Monitor errors (chạy song song)
cd "D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-arena\app"
flutter run --dart-define-from-file=env.json 2>&1 | Select-String -Pattern "Error|Exception|Failed|❌|💥" | Tee-Object -FilePath "errors.log"
```

---

## ✅ CHECKLIST TEST TỰ ĐỘNG

### **AUTHENTICATION FLOW**

#### 1. Login Screen
- [ ] Mở app → Splash screen → Login screen
- [ ] Nhập email và password
- [ ] Click "Đăng nhập"
- [ ] **Expected:** Navigate to home feed
- [ ] **Check logs:** Không có errors

#### 2. Register Screen  
- [ ] Click "Đăng ký"
- [ ] Điền form đầy đủ
- [ ] Click "Đăng ký"
- [ ] **Expected:** OTP verification screen
- [ ] **Check logs:** Không có errors

---

### **HOME FEED SCREEN**

#### 3. Navigation & Actions
- [ ] AppBar hiển thị đúng
- [ ] Click notification icon → Navigate to notifications
- [ ] Click search icon → Search dialog mở
- [ ] Click FAB "Tạo bài viết" → Modal mở (heroTag: 'home_feed_create_post')
- [ ] **Check logs:** Không có Hero widget errors

#### 4. Post Interactions
- [ ] Scroll feed → Posts load đúng
- [ ] Click like button → Like/unlike hoạt động
- [ ] Click comment button → Comment dialog mở
- [ ] Click share button → Share dialog mở
- [ ] Click avatar → Navigate to user profile
- [ ] Pull to refresh → Feed refresh
- [ ] **Check logs:** Không có null pointer errors

---

### **TOURNAMENT LIST SCREEN**

#### 5. Tournament List
- [ ] Navigate to Tournament tab
- [ ] Tournament cards hiển thị đúng
- [ ] Click filter button → Filter sheet mở (heroTag: 'tournament_list_filter')
- [ ] Click tournament card → Navigate to detail
- [ ] Switch tabs (Upcoming, Ongoing, Completed)
- [ ] **Check logs:** Không có errors

---

### **FIND OPPONENTS SCREEN**

#### 6. Competitive Play Tab
- [ ] Navigate to Find Opponents tab
- [ ] Competitive Play tab hiển thị đúng
- [ ] FAB "Tạo thách đấu" hoạt động (heroTag: 'competitive_play_create_challenge')
- [ ] Player cards hiển thị đúng
- [ ] Challenge button hoạt động
- [ ] **Check logs:** Không có Hero widget errors

#### 7. Social Play Tab
- [ ] Switch to Social Play tab
- [ ] FAB "Tạo giao lưu" hoạt động (heroTag: 'social_play_create_challenge')
- [ ] Invite button hoạt động
- [ ] **Check logs:** Không có errors

#### 8. Competitive Challenges Tab
- [ ] Switch to Competitive Challenges tab
- [ ] FAB "Tạo thách đấu" hoạt động (heroTag: 'competitive_challenges_create')
- [ ] Accept/Decline buttons hoạt động
- [ ] **Check logs:** Không có errors

#### 9. Social Invites Tab
- [ ] Switch to Social Invites tab
- [ ] FAB "Tạo giao lưu" hoạt động (heroTag: 'social_invites_create')
- [ ] Accept/Decline buttons hoạt động
- [ ] **Check logs:** Không có errors

---

### **USER PROFILE SCREEN**

#### 10. Profile Navigation
- [ ] Navigate to Profile tab
- [ ] Avatar hiển thị đúng
- [ ] Edit profile button hoạt động
- [ ] Settings button hoạt động
- [ ] **Check logs:** Không có errors

#### 11. Profile Tabs
- [ ] Switch between tabs (Posts, Tournaments, Matches, Achievements)
- [ ] Each tab loads data đúng
- [ ] **Check logs:** Không có errors

---

### **TOURNAMENT DETAIL SCREEN**

#### 12. Tournament Detail
- [ ] Click tournament card → Navigate to detail
- [ ] FAB "Đăng ký" hoạt động (heroTag: 'tournament_detail_action')
- [ ] Switch tabs (Overview, Participants, Bracket, Results)
- [ ] Register button hoạt động
- [ ] **Check logs:** Không có errors

---

### **CLUB SCREENS**

#### 13. Club Main Screen
- [ ] Navigate to Club screen
- [ ] Club info hiển thị đúng
- [ ] Join/Leave button hoạt động
- [ ] **Check logs:** Không có errors

#### 14. Club Profile Screen
- [ ] Click "Xem trang câu lạc bộ"
- [ ] Edit button hoạt động (heroTag: 'edit_profile')
- [ ] Create Post FAB hoạt động (heroTag: 'create_post')
- [ ] **Check logs:** Không có Hero widget errors

#### 15. Club Dashboard
- [ ] Navigate to Club Dashboard (nếu là owner)
- [ ] Click "Tạo giải đấu" → Navigate to creation wizard
- [ ] **Check logs:** Không có duplicate navigation errors

---

### **MESSAGING SCREENS**

#### 16. Messaging
- [ ] Click message icon → Navigate to messaging
- [ ] Conversation list hiển thị đúng
- [ ] Click conversation → Open chat
- [ ] Send message hoạt động
- [ ] **Check logs:** Không có errors

---

### **SETTINGS & PROFILE**

#### 17. Account Settings
- [ ] Navigate to Settings
- [ ] All settings options accessible
- [ ] Save changes hoạt động
- [ ] Logout button hoạt động
- [ ] **Check logs:** Không có errors

---

## 🔍 KIỂM TRA LỖI TỰ ĐỘNG

### Check for Common Errors:

```powershell
# 1. Hero Widget Conflicts
flutter run --dart-define-from-file=env.json 2>&1 | Select-String -Pattern "multiple heroes|Hero.*tag"

# 2. Navigation Errors
flutter run --dart-define-from-file=env.json 2>&1 | Select-String -Pattern "Navigator.*error|Route.*not found"

# 3. Null Pointer Exceptions
flutter run --dart-define-from-file=env.json 2>&1 | Select-String -Pattern "Null.*Exception|null.*error"

# 4. Image Loading Errors
flutter run --dart-define-from-file=env.json 2>&1 | Select-String -Pattern "Image.*error|Failed.*decode"

# 5. Database Errors
flutter run --dart-define-from-file=env.json 2>&1 | Select-String -Pattern "PostgrestException|Database.*error"
```

---

## 📊 TEST RESULTS TEMPLATE

**Date:** _______________
**Tester:** _______________
**Device:** _______________

### ✅ Passed Tests
- [ ] Authentication flow
- [ ] Home Feed navigation
- [ ] Tournament list
- [ ] Find Opponents tabs
- [ ] User Profile
- [ ] Tournament Detail
- [ ] Club Screens
- [ ] Messaging
- [ ] Settings

### ❌ Failed Tests
1. 
2. 
3. 

### ⚠️ Warnings
1. 
2. 

---

## 🎯 NEXT STEPS

Sau khi hoàn thành checklist:
1. Review tất cả errors trong logs
2. Fix các lỗi phát hiện được
3. Re-test các tính năng đã fix
4. Document findings

