@echo off
echo ======================================
echo  GET SHA256 FINGERPRINT FOR ANDROID
echo ======================================
echo.

echo [1] Debug Keystore (for development)
echo.
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr SHA256

echo.
echo.
echo [2] Release Keystore (if exists)
echo.
if exist android\app\release.keystore (
    echo Enter your release keystore password:
    keytool -list -v -keystore android\app\release.keystore -alias upload | findstr SHA256
) else (
    echo Release keystore not found. Skip this for now.
)

echo.
echo ======================================
echo  NEXT STEPS:
echo ======================================
echo 1. Copy SHA256 fingerprint above
echo 2. Remove colons (:) from the fingerprint
echo 3. Paste into website/.well-known/assetlinks.json
echo.
pause
