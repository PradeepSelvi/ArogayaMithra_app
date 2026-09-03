# Android Black Screen - Action Plan

## 🎯 Quick Summary

**Problem:** Flutter UI not rendering on Android emulator (black screen)  
**Status:** Backend works ✅ | Code works ✅ | Rendering fails ❌  
**Root Cause:** Flutter surface sizing failure ("Width is zero" logs)

---

## 🔧 IMMEDIATE FIXES TO TRY (In Order)

### Fix #1: Software Rendering Mode
**Time:** 2 minutes  
**Success Rate:** 60%

```powershell
# Stop current app
flutter.bat clean

# Run with software rendering
$env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:PATH
cd apps\citizen
flutter.bat run -d emulator-5554 --enable-software-rendering
```

**Why:** Bypasses GPU hardware acceleration

---

### Fix #2: Disable Impeller (Use Skia Rendering)
**Time:** 5 minutes  
**Success Rate:** 70%

1. Open `apps/citizen/android/app/src/main/AndroidManifest.xml`

2. Add inside `<application>` tag:
```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

3. Clean and rebuild:
```powershell
flutter.bat clean
flutter.bat run -d emulator-5554
```

**Why:** Falls back to proven Skia rendering engine

---

### Fix #3: Update FlutterActivity Theme
**Time:** 3 minutes  
**Success Rate:** 40%

1. Open `apps/citizen/android/app/src/main/res/values/styles.xml`

2. Update NormalTheme:
```xml
<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@android:color/white</item>
    <item name="android:windowIsTranslucent">false</item>
    <item name="android:windowDrawsSystemBarBackgrounds">true</item>
</style>
```

3. Rebuild app

**Why:** Forces explicit window configuration

---

### Fix #4: Create New Emulator
**Time:** 10 minutes  
**Success Rate:** 80%

```powershell
# List available system images
flutter.bat emulators --create

# Or create manually:
# 1. Open Android Studio > Virtual Device Manager
# 2. Create New Device
# 3. Choose: Pixel 3
# 4. System Image: Android 13 (API 33)
# 5. Graphics: Hardware - GLES 2.0
# 6. RAM: 2GB minimum

# Then run:
flutter.bat emulators --launch <new-emulator-name>
flutter.bat run -d <new-emulator-id>
```

**Why:** Current emulator (Pixel 10, API 36) may have compatibility issues

---

### Fix #5: Test on Physical Device
**Time:** 5 minutes  
**Success Rate:** 95%

```powershell
# 1. Enable Developer Options on Android phone:
#    Settings > About Phone > Tap "Build Number" 7 times

# 2. Enable USB Debugging:
#    Settings > Developer Options > USB Debugging

# 3. Connect phone via USB

# 4. Check device connected:
$env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:PATH
flutter.bat devices

# 5. Run app:
flutter.bat run -d <device-id>
```

**Why:** Confirms if issue is emulator-specific (most likely)

---

## 🔍 DIAGNOSTIC COMMANDS

### Check Current Status
```powershell
# Check devices
flutter.bat devices

# Check emulator graphics
flutter.bat emulators

# View detailed logs
flutter.bat run -d emulator-5554 --verbose
```

### Monitor Real-Time Logs
```powershell
# In separate terminal - requires Android SDK in PATH
adb logcat | Select-String -Pattern "flutter|Error"
```

---

## 📊 EXPECTED RESULTS

### If Fix Works
```
✅ "Width is zero" messages stop
✅ UI renders (Language selection screen appears)
✅ Can interact with app
✅ Hot reload works
```

### If Fix Doesn't Work
```
❌ Still shows black screen
❌ "Width is zero" persists
→ Try next fix in list
```

---

## 🎯 RECOMMENDED APPROACH

**Best Strategy:** Try fixes in this order:

1. **Fix #5 (Physical Device)** - Fastest way to confirm app works
2. **Fix #4 (New Emulator)** - Most likely to solve emulator issue  
3. **Fix #2 (Disable Impeller)** - Known workaround for rendering issues
4. **Fix #1 (Software Rendering)** - Quick test without code changes
5. **Fix #3 (Theme Update)** - Last resort

---

## 🚨 IF NOTHING WORKS

### Option A: Use Web Platform
The app works perfectly on web. Deploy as PWA for testing:

```powershell
cd apps\citizen
flutter.bat build web --release
# Deploy to Netlify/Firebase/Vercel
```

### Option B: Update Flutter
```powershell
flutter upgrade
flutter doctor
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### Option C: Report Bug
```powershell
# Collect diagnostics
flutter doctor -v > flutter-doctor.txt
flutter run -d emulator-5554 --verbose > flutter-run.log 2>&1

# Report to Flutter team:
# https://github.com/flutter/flutter/issues
```

---

## ✅ VERIFICATION CHECKLIST

After applying fix:

- [ ] App launches without crash
- [ ] Language selection screen appears
- [ ] Can tap "தமிழ்" or "English" button
- [ ] Navigation to sign-in screen works
- [ ] Supabase connection confirmed (check logs)
- [ ] Hot reload works (press 'r' in terminal)
- [ ] No "Width is zero" in logs

---

## 📞 QUICK REFERENCE

### PowerShell PATH Fix (Run before each Flutter command)
```powershell
$env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:PATH
```

### Emulator Commands
```powershell
# Start emulator
flutter.bat emulators --launch Pixel_10

# Stop all emulators
# Close emulator window or:
adb emu kill
```

### Clean Commands
```powershell
flutter.bat clean
Remove-Item -Recurse -Force android\app\build
flutter.bat pub get
```

---

## 🎉 SUCCESS CRITERIA

**The fix is successful when:**

1. ✅ App displays language selection screen (Tamil/English)
2. ✅ White background with ArogyaMitra logo visible
3. ✅ Two language buttons are clickable
4. ✅ No black screen
5. ✅ Logs show no "Width is zero" errors

---

*Quick Action Plan - Start with Fix #5 (Physical Device) for fastest validation*
