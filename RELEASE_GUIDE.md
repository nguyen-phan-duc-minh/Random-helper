# Hướng Dẫn Build và Upload AAB lên Google Play Store

## ✅ Đã Hoàn Thành

### 1. Cập nhật version
- **Version hiện tại**: 1.0.1+2
- File: `pubspec.yaml`

### 2. Privacy Policy
- **File**: `privacy_policy.html` (trong thư mục gốc dự án)
- Nội dung: Chính sách bảo mật song ngữ (Tiếng Việt & English)
- URL để upload: Bạn cần host file này lên một web server hoặc GitHub Pages

### 3. Keystore & Signing
- **Keystore file**: `android/app/upload-keystore.jks`
- **Key properties**: `android/key.properties`
- **Thông tin keystore**:
  - Store Password: `luckyhub2024`
  - Key Password: `luckyhub2024`
  - Key Alias: `upload`
  - Validity: 10,000 ngày

⚠️ **LƯU Ý QUAN TRỌNG**: Backup keystore file và passwords này cẩn thận! Không được mất file này!

### 4. Application ID
- **Old**: com.example.lucky_hub
- **New**: com.mydang.lucky_hub
- **App Name**: Lucky Hub

### 5. Build AAB
- **File output**: `build/app/outputs/bundle/release/app-release.aab`
- **Size**: 40.8 MB
- ✅ Build thành công!

## 📋 Checklist Trước Khi Upload Lên Google Play Store

### A. Chuẩn Bị File
- [x] File AAB đã build: `build/app/outputs/bundle/release/app-release.aab`
- [x] Privacy Policy URL (cần host `privacy_policy.html`)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (ít nhất 2 ảnh cho mỗi loại thiết bị)
- [ ] App description (ngắn & dài)

### B. Thông Tin App
- **Package name**: com.mydang.lucky_hub
- **App name**: Lucky Hub
- **Version**: 1.0.1 (versionCode: 2)
- **Category**: Tools / Entertainment

### C. Privacy Policy URL
Bạn cần host file `privacy_policy.html` lên một trong các nơi sau:
1. GitHub Pages (miễn phí)
2. Firebase Hosting (miễn phí)
3. Web server riêng

**Hướng dẫn host trên GitHub Pages**:
```bash
# 1. Tạo repository public trên GitHub (ví dụ: luckyhub-privacy)
# 2. Upload file privacy_policy.html
# 3. Enable GitHub Pages trong Settings > Pages
# 4. URL sẽ là: https://<username>.github.io/luckyhub-privacy/privacy_policy.html
```

## 🚀 Các Bước Upload Lên Google Play Store

### 1. Tạo App Trên Google Play Console
1. Đăng nhập vào https://play.google.com/console
2. Chọn "Create app"
3. Điền thông tin:
   - App name: Lucky Hub
   - Default language: Vietnamese (hoặc English)
   - App/Game: App
   - Free/Paid: Free

### 2. Upload AAB
1. Vào "Release" > "Production" > "Create new release"
2. Upload file AAB: `build/app/outputs/bundle/release/app-release.aab`
3. Điền Release notes

### 3. Điền Thông Tin Store Listing
- **App name**: Lucky Hub
- **Short description**: Ứng dụng vòng quay may mắn giúp bạn đưa ra quyết định ngẫu nhiên
- **Full description**: Mô tả chi tiết về app
- **App icon**: 512x512 PNG
- **Feature graphic**: 1024x500 PNG
- **Screenshots**: Ít nhất 2 ảnh
- **Category**: Tools hoặc Entertainment
- **Privacy Policy URL**: URL của file privacy_policy.html

### 4. Content Rating
1. Điền questionnaire
2. Với app này, nên chọn: PEGI 3 / Everyone

### 5. App Content
- **Privacy policy**: Nhập URL
- **Ads**: Chọn No (nếu không có quảng cáo)
- **Target audience**: All ages
- **App access**: All features available
- **Government apps**: No

### 6. Submit For Review
1. Kiểm tra tất cả thông tin
2. Submit app for review
3. Đợi Google review (thường 1-3 ngày)

## 🔄 Build Version Mới

Khi cần cập nhật app:

```bash
# 1. Cập nhật version trong pubspec.yaml
# version: 1.0.2+3 (tăng cả version name và version code)

# 2. Build AAB mới
cd /Users/macos/Downloads/Application/LUCKYHUB
flutter build appbundle --release

# 3. File AAB sẽ ở: build/app/outputs/bundle/release/app-release.aab
```

## 🔐 Bảo Mật Keystore

**CỰC KỲ QUAN TRỌNG**: 
- File `android/app/upload-keystore.jks` phải được backup cẩn thận
- Không được commit file này lên git
- Nếu mất keystore, bạn sẽ KHÔNG THỂ cập nhật app trên Play Store
- Nên lưu ở nhiều nơi: Google Drive, Dropbox, ổ cứng ngoài, v.v.

Đã thêm vào `.gitignore`:
```
android/app/upload-keystore.jks
android/key.properties
```

## 📝 Thông Tin Liên Hệ Trong App

- **Email**: mydang2705@gmail.com
- **Location**: Việt Nam

## 🎨 Gợi Ý Tạo Assets

### App Icon (512x512)
- Nên có logo rõ ràng, màu sắc nổi bật
- Không có text hoặc có ít text
- Background không trong suốt

### Feature Graphic (1024x500)
- Thể hiện tính năng chính của app
- Có thể có text giới thiệu
- Màu sắc hấp dẫn

### Screenshots
- Chụp màn hình các tính năng chính:
  - Trang chủ với danh sách vòng quay
  - Màn hình tạo vòng quay mới
  - Màn hình quay
  - Lịch sử kết quả

## ✅ Kiểm Tra Cuối Cùng

- [x] Version đúng: 1.0.1+2
- [x] Package name: com.mydang.lucky_hub
- [x] App name: Lucky Hub
- [x] Keystore đã tạo và cấu hình
- [x] Privacy policy đã có (cần host)
- [x] AAB build thành công
- [x] AndroidManifest cấu hình đầy đủ

---

**Chúc bạn thành công với Lucky Hub trên Google Play Store!** 🎉
