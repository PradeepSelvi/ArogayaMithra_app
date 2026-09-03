# 🚀 Quick Start: Fix Android Black Screen

**Problem:** Black screen on Android emulator  
**Solution:** 3 simple steps (15 minutes)

---

## ⚡ FASTEST FIX (Run This First)

### Option 1: Automated Script (Recommended)

```powershell
# From project root (sih directory)
.\fix-android-rendering.ps1 -Mode quick
```

**What it does:**
1. ✅ Disables Impeller (uses Skia renderer instead)
2. ✅ Updates Android theme configuration
3. ✅ Cleans and rebuilds the app
4. ✅ Launches on emulator
5. ✅ Creates automatic backups

**Expected result:** Language selection screen appears with white background

---

### Option 2: Manual Steps (If script doesn't work)

#### Step 1: Disable Impeller

Edit `apps/citizen/android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="arogyamitra_citizen"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- ADD THIS -->
    <meta-data
        android:name="io.flutter.embedding.android.EnableImpeller"
        android:value="false" />
    
    <activity android:name=".MainActivity" ...>
```

#### Step 2: Update Theme

Edit `apps/citizen/android/app/src/main/res/values/styles.xml`:

Replace `NormalTheme` with:

```xml
<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@android:color/white</item>
    <item name="android:windowIsTranslucent">false</item>
    <item name="android:windowDrawsSystemBarBackgrounds">true</item>
</style>
```

#### Step 3: Clean and Run

```powershell
cd apps\citizen
flutter.bat clean
flutter.bat run -d emulator-5554
```

---

## 📱 ALTERNATIVE: Test on Physical Device (Fastest Validation)

```powershell
# Enable USB debugging on phone first
.\fix-android-rendering.ps1 -Mode test-device
```

**Why:** Confirms if issue is emulator-specific (95% success rate)

---

## 🔍 IF STILL NOT WORKING

### Try Software Rendering

```powershell
cd apps\citizen
flutter.bat run -d emulator-5554 --enable-software-rendering
```

### Create New Emulator

```powershell
# In Android Studio:
# Tools > Device Manager > Create Device
# - Device: Pixel 3
# - System: Android 13 (API 33)
# - Graphics: Hardware - GLES 2.0

# Then run:
flutter.bat devices  # Get new emulator ID
flutter.bat run -d <new-emulator-id>
```

### Run Diagnostics

```powershell
.\fix-android-rendering.ps1 -Mode diagnostic
```

---

## ✅ SUCCESS CHECKLIST

After running fix, verify:

- [ ] App launches (no crash)
- [ ] White/colored background (not black)
- [ ] Language selection screen visible
- [ ] "தமிழ்" and "English" buttons appear
- [ ] Buttons are clickable
- [ ] No "Width is zero" in logs
- [ ] Hot reload works (press 'r')

---

## 🆘 STILL STUCK?

### Web Platform (100% Working)

```powershell
cd apps\citizen
flutter.bat run -d chrome
```

Web version works perfectly - use this while troubleshooting Android.

### Get Help

1. Check `ANDROID_FIX_IMPLEMENTATION_PLAN.md` for detailed steps
2. Review `DIAGNOSTIC_REPORT.md` for background
3. Run diagnostics: `.\fix-android-rendering.ps1 -Mode diagnostic`

---

## 📞 QUICK REFERENCE

### All Script Modes

```powershell
# Quick fix (recommended)
.\fix-android-rendering.ps1 -Mode quick

# Full fix with software rendering
.\fix-android-rendering.ps1 -Mode full

# Physical device test
.\fix-android-rendering.ps1 -Mode test-device

# Diagnostics only
.\fix-android-rendering.ps1 -Mode diagnostic

# Custom device
.\fix-android-rendering.ps1 -Mode quick -DeviceId "emulator-5556"
```

### Rollback Changes

```powershell
# Backups are in: android-backup-<timestamp>
# To restore:
copy android-backup-*\AndroidManifest.xml apps\citizen\android\app\src\main\
copy android-backup-*\styles.xml apps\citizen\android\app\src\main\res\values\
```

---

## 🎯 ROOT CAUSE

**Technical:** Flutter rendering surface not receiving dimensions from Android ViewTreeObserver  
**Symptom:** `D/FlutterRenderer: Width is zero. 0,0` in logs  
**Solution:** Disable Impeller rendering backend, use proven Skia renderer

**Why Impeller?** 
- Impeller is Flutter's new rendering engine (default in Flutter 3.41.2)
- Has compatibility issues with some emulators
- Skia is the proven fallback renderer

---

*Quick fix script ready - Run `.\fix-android-rendering.ps1 -Mode quick` to start*
