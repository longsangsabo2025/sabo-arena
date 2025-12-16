# 🌐 SABO Arena Landing Page

Landing page cho deep links và referral system.

## 📁 Cấu trúc

```
website/
├── index.html                                  # Landing page
├── .well-known/
│   ├── assetlinks.json                        # Android App Links
│   └── apple-app-site-association             # iOS Universal Links
├── vercel.json                                # Vercel configuration
└── README.md
```

## 🚀 Deploy

### Deploy lên Vercel
```bash
cd website
vercel
```

### Link custom domain
```bash
vercel domains add saboarena.com
```

## 🔧 Cấu hình

### 1. Update Android SHA256
Edit `.well-known/assetlinks.json`:
```json
"sha256_cert_fingerprints": ["YOUR_SHA256_HERE"]
```

### 2. Update iOS Team ID
Edit `.well-known/apple-app-site-association`:
```json
"appID": "YOUR_TEAM_ID.com.saboarena.app"
```

### 3. Update App Store URLs
Edit `index.html`:
```javascript
const appStoreUrl = 'YOUR_APP_STORE_URL';
const playStoreUrl = 'YOUR_PLAY_STORE_URL';
```

## ✅ Verify

Test Android App Links:
```bash
curl https://saboarena.com/.well-known/assetlinks.json
```

Test iOS Universal Links:
```bash
curl https://saboarena.com/.well-known/apple-app-site-association
```

Apple Validator:
https://search.developer.apple.com/appsearch-validation-tool/

Google Validator:
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://saboarena.com&relation=delegate_permission/common.handle_all_urls
