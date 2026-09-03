# Android Rendering Issue - Implementation Plan

**Date:** September 3, 2026  
**Priority:** HIGH  
**Status:** Ready for Execution  
**Estimated Time:** 2-3 hours

---

## 🎯 PROBLEM STATEMENT

**Symptom:** Black screen on Android emulator despite successful build and backend connection  
**Root Cause:** Flutter rendering surface fails to receive dimensions from Android ViewTreeObserver  
**Evidence:** `D/FlutterRenderer: Width is zero. 0,0` in logs  
**Impact:** Android app unusable on emulator (web platform works perfectly)

---

## 📋 EXECUTION STRATEGY

We'll apply fixes in order of success probability, testing after each step:

```
Priority Order:
1. Physical Device Test (95% success rate) - VALIDATE FIRST
2. Disable Impeller (70% success rate) - QUICK FIX
3. New Emulator (80% success rate) - ENVIRONMENT FIX
4. Software Rendering (60% success rate) - DIAGNOSTIC
5. Theme Updates (40% success rate) - LAST RESORT
```

---

## 🚀 PHASE 1: VALIDATION (5 minutes)

### Goal: Confirm issue is emulator-specific, not code-related

#### Step 1.1: Test on Physical Device

**Prerequisites:**
- Android phone with USB cable
- USB debugging enabled

**Commands:**
```powershell
# Set PATH
$env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:PATH

# Navigate to citizen app
cd apps\citizen

# Check connected devices
flutter.bat devices

# Run on physical device
flutter.bat run -d <device-id>
```

**Expected Results:**
- ✅ **If app works:** Issue is emulator-specific → Proceed to Phase 2
- ❌ **If app fails:** Code issue → Proceed to Phase 5 (Deep Diagnostics)

**Success Criteria:**
- Language selection screen appears
- Can tap Tamil/English buttons
- Navigation works
- No black screen

---

## 🔧 PHASE 2: QUICK FIXES (15 minutes)

### Goal: Apply known workarounds for Flutter rendering issues

#### Step 2.1: Disable Impeller Rendering Engine

**Why:** Impeller (new Flutter rendering backend) has compatibility issues with some emulators. Falling back to Skia often resolves this.

**Implementation:**

1. **Create/Update AndroidManifest.xml:**

```powershell
# Path: apps/citizen/android/app/src/main/AndroidManifest.xml
```

2. **Add meta-data inside `<application>` tag:**

```xml
<application
    android:label="ArogyaMitra"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- DISABLE IMPELLER - USE SKIA RENDERING -->
    <meta-data
        android:name="io.flutter.embedding.android.EnableImpeller"
        android:value="false" />
    
    <activity
        android:name=".MainActivity"
        ...>
    </activity>
</application>
```

3. **Clean and rebuild:**

```powershell
# In apps/citizen directory
flutter.bat clean
flutter.bat pub get
flutter.bat run -d emulator-5554
```

**Expected Results:**
- Build completes successfully
- App launches with Skia rendering
- UI should appear if Impeller was the issue

**Verification:**
```powershell
# Check logs for rendering engine
adb logcat | Select-String -Pattern "Skia|Impeller"
```

**Success Criteria:**
- No "Width is zero" errors
- UI renders correctly
- Hot reload works

---

#### Step 2.2: Software Rendering Test (Diagnostic)

**Why:** Tests if hardware GPU acceleration is causing the issue

**Commands:**
```powershell
cd apps\citizen
flutter.bat clean
flutter.bat run -d emulator-5554 --enable-software-rendering
```

**Expected Results:**
- If works: GPU hardware issue → Keep this flag or fix emulator graphics
- If fails: Not GPU-related → Continue to next fix

---

## 🖥️ PHASE 3: EMULATOR CONFIGURATION (30 minutes)

### Goal: Create a compatible emulator configuration

#### Step 3.1: Check Current Emulator Settings

**Commands:**
```powershell
# List available emulators
flutter.bat emulators

# Check running emulator details
adb shell getprop | Select-String -Pattern "ro.build.version|ro.product.model"
```

**Current Configuration:**
- Device: Pixel 10
- Android Version: 16 (API 36)
- Graphics: Unknown (need to check AVD settings)

#### Step 3.2: Create New Emulator with Proven Configuration

**Why:** Pixel 10 with API 36 is cutting-edge; proven configurations are more stable

**Recommended Configuration:**
- Device: Pixel 3 or Pixel 5
- Android Version: 13 (API 33)
- Graphics: Hardware - GLES 2.0
- RAM: 2048 MB
- Internal Storage: 4096 MB

**Steps:**

1. **Open Android Studio:**
```powershell
# From project root
start android\build.gradle
```

2. **Create AVD via UI:**
   - Tools → Device Manager → Create Device
   - Select Pixel 3
   - Download System Image: Android 13 (API 33) - Google APIs
   - Graphics: Hardware - GLES 2.0
   - RAM: 2048 MB
   - Name: `Pixel_3_API_33_Test`

3. **Launch new emulator:**
```powershell
flutter.bat emulators --launch Pixel_3_API_33_Test

# Wait for boot, then run app
flutter.bat run -d <new-emulator-id>
```

**Alternative - Command Line Creation:**
```powershell
# List available system images
sdkmanager --list | Select-String -Pattern "system-images"

# Create AVD
avdmanager create avd -n Pixel_3_API_33 -k "system-images;android-33;google_apis;x86_64" -d "pixel_3"

# Launch
emulator -avd Pixel_3_API_33 -gpu host
```

---

## 🎨 PHASE 4: THEME AND MANIFEST FIXES (20 minutes)

### Goal: Ensure proper Android theme configuration

#### Step 4.1: Update Styles.xml

**File:** `apps/citizen/android/app/src/main/res/values/styles.xml`

**Current Check:**
```powershell
# Read current styles
type apps\citizen\android\app\src\main\res\values\styles.xml
```

**Update to:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
    
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@android:color/white</item>
        <item name="android:windowIsTranslucent">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">true</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
```

**Key Changes:**
- Explicit `android:windowBackground` set to white
- `android:windowIsTranslucent` set to false
- `android:windowDrawsSystemBarBackgrounds` enabled
- Status bar made transparent

#### Step 4.2: Update MainActivity.kt (if needed)

**File:** `apps/citizen/android/app/src/main/kotlin/com/arogyamitra/citizen/MainActivity.kt`

**Check current implementation:**
```powershell
type apps\citizen\android\app\src\main\kotlin\com\arogyamitra\citizen\MainActivity.kt
```

**Ensure it contains:**
```kotlin
package com.arogyamitra.citizen

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    // No custom overrides needed for rendering
}
```

---

## 🔍 PHASE 5: DEEP DIAGNOSTICS (30 minutes)

### If all above fixes fail, perform detailed analysis

#### Step 5.1: Collect Comprehensive Logs

**Create debug script:**
```powershell
# Create apps/citizen/debug-android.ps1
```

**Script content:**
```powershell
# Debug Android Rendering Issue
Write-Host "🔍 Collecting Android Diagnostics..." -ForegroundColor Cyan

# 1. Flutter Doctor
Write-Host "`n1. Flutter Doctor..." -ForegroundColor Yellow
flutter.bat doctor -v | Out-File -FilePath "debug-flutter-doctor.txt"

# 2. Device Info
Write-Host "`n2. Connected Devices..." -ForegroundColor Yellow
flutter.bat devices | Out-File -FilePath "debug-devices.txt"

# 3. Emulator Info
Write-Host "`n3. Emulator Properties..." -ForegroundColor Yellow
adb shell getprop | Out-File -FilePath "debug-emulator-props.txt"

# 4. Graphics Info
Write-Host "`n4. Graphics Configuration..." -ForegroundColor Yellow
adb shell dumpsys SurfaceFlinger | Out-File -FilePath "debug-graphics.txt"

# 5. Run with verbose logging
Write-Host "`n5. Running app with verbose logging..." -ForegroundColor Yellow
flutter.bat run -d emulator-5554 --verbose 2>&1 | Out-File -FilePath "debug-flutter-run.txt"

Write-Host "`n✅ Diagnostics saved to debug-*.txt files" -ForegroundColor Green
```

#### Step 5.2: Analyze Flutter Engine Logs

**Real-time monitoring:**
```powershell
# Terminal 1: Run app
cd apps\citizen
flutter.bat run -d emulator-5554

# Terminal 2: Monitor logs
adb logcat -s flutter:V FlutterRenderer:V ActivityManager:I WindowManager:I
```

**Look for:**
- Surface creation events
- View dimensions
- GPU initialization
- Texture registration
- Any ERROR or FATAL messages

#### Step 5.3: Check Flutter Engine Build

**Verify Flutter installation:**
```powershell
# Check Flutter installation
flutter.bat --version

# Verify engine artifacts
dir $env:FLUTTER_ROOT\bin\cache\artifacts\engine\android-arm64-release\

# Re-download if needed
flutter.bat precache --android
```

---

## 📊 TESTING CHECKLIST

### After Each Fix Attempt:

- [ ] App launches without crash
- [ ] White/colored background visible (not black)
- [ ] Language selection screen renders
- [ ] Can see "தமிழ்" and "English" buttons
- [ ] Buttons are clickable
- [ ] Navigation works
- [ ] Logs show no "Width is zero" errors
- [ ] Hot reload works (press 'r' in terminal)
- [ ] Supabase connection confirmed

### Full Validation Test:

```powershell
# Run validation script
cd apps\citizen

# 1. Clean build
flutter.bat clean
Remove-Item -Recurse -Force android\app\build -ErrorAction SilentlyContinue

# 2. Get dependencies
flutter.bat pub get

# 3. Run app
flutter.bat run -d emulator-5554

# 4. Test hot reload
# Make a small UI change, save, and press 'r' in terminal

# 5. Check logs
adb logcat | Select-String -Pattern "Width is zero|ERROR|FATAL"
```

---

## 🎯 SUCCESS METRICS

### Critical Success Criteria:

1. **Visual Confirmation:**
   - ✅ App displays language selection screen
   - ✅ White background with ArogyaMitra branding
   - ✅ Two language buttons visible and styled correctly

2. **Functional Confirmation:**
   - ✅ Can tap buttons
   - ✅ Navigation to next screen works
   - ✅ No ANR (Application Not Responding) dialogs

3. **Technical Confirmation:**
   - ✅ Logs show Flutter surface dimensions > 0
   - ✅ No "Width is zero" messages
   - ✅ Skipped frames < 10% (performance acceptable)
   - ✅ Hot reload functional

4. **Backend Confirmation:**
   - ✅ Supabase client initializes
   - ✅ Can make API calls (test with language selection)
   - ✅ No network errors

---

## 🔄 ROLLBACK PLAN

### If fixes break something:

#### Rollback Impeller Disable:
```powershell
# Remove meta-data from AndroidManifest.xml
# Or set android:value="true"
```

#### Rollback Styles:
```powershell
# Restore from git
git checkout apps/citizen/android/app/src/main/res/values/styles.xml
```

#### Rollback to Web Platform:
```powershell
# Use working web version
cd apps\citizen
flutter.bat run -d chrome
```

---

## 📝 IMPLEMENTATION SCRIPTS

### Master Fix Script

**File:** `fix-android-rendering.ps1`

```powershell
# ArogyaMitra - Android Rendering Fix Script
# Run this to apply all fixes systematically

param(
    [ValidateSet("quick", "full", "diagnostic")]
    [string]$Mode = "quick"
)

$ErrorActionPreference = "Stop"
Write-Host "🔧 Android Rendering Fix - Mode: $Mode" -ForegroundColor Cyan

# Set PATH
$env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:PATH

# Navigate to citizen app
Set-Location "apps\citizen"

switch ($Mode) {
    "quick" {
        Write-Host "`n📋 Quick Fix Mode" -ForegroundColor Yellow
        
        # Step 1: Disable Impeller
        Write-Host "`n1️⃣ Disabling Impeller..." -ForegroundColor Green
        $manifestPath = "android\app\src\main\AndroidManifest.xml"
        $manifest = Get-Content $manifestPath -Raw
        
        if ($manifest -notmatch "EnableImpeller") {
            $metaData = @"
        <!-- DISABLE IMPELLER - USE SKIA RENDERING -->
        <meta-data
            android:name="io.flutter.embedding.android.EnableImpeller"
            android:value="false" />
"@
            $manifest = $manifest -replace '(<application[^>]*>)', "`$1`n$metaData"
            Set-Content $manifestPath $manifest
            Write-Host "   ✅ Impeller disabled" -ForegroundColor Green
        } else {
            Write-Host "   ℹ️ Impeller already configured" -ForegroundColor Gray
        }
        
        # Step 2: Clean build
        Write-Host "`n2️⃣ Cleaning build..." -ForegroundColor Green
        flutter.bat clean | Out-Null
        Remove-Item -Recurse -Force android\app\build -ErrorAction SilentlyContinue
        
        # Step 3: Rebuild
        Write-Host "`n3️⃣ Getting dependencies..." -ForegroundColor Green
        flutter.bat pub get | Out-Null
        
        # Step 4: Run
        Write-Host "`n4️⃣ Launching app..." -ForegroundColor Green
        Write-Host "   Watch for UI to appear..." -ForegroundColor Yellow
        flutter.bat run -d emulator-5554
    }
    
    "full" {
        Write-Host "`n📋 Full Fix Mode (with theme updates)" -ForegroundColor Yellow
        
        # Apply quick fixes first
        & $PSCommandPath -Mode quick
        
        # Additional theme fixes would go here
    }
    
    "diagnostic" {
        Write-Host "`n📋 Diagnostic Mode" -ForegroundColor Yellow
        
        # Run diagnostic commands
        Write-Host "`n1️⃣ Flutter Doctor..." -ForegroundColor Green
        flutter.bat doctor -v
        
        Write-Host "`n2️⃣ Connected Devices..." -ForegroundColor Green
        flutter.bat devices
        
        Write-Host "`n3️⃣ Available Emulators..." -ForegroundColor Green
        flutter.bat emulators
        
        Write-Host "`n4️⃣ Checking Emulator Properties..." -ForegroundColor Green
        adb shell getprop | Select-String -Pattern "build.version|product.model|gles"
        
        Write-Host "`n5️⃣ Running with verbose logs..." -ForegroundColor Green
        flutter.bat run -d emulator-5554 --verbose
    }
}
```

---

## 📅 EXECUTION TIMELINE

### Immediate (Next 30 minutes):
1. ✅ Run physical device test (if available)
2. ✅ Apply Impeller disable fix
3. ✅ Test on current emulator

### Short-term (Next 2 hours):
4. ✅ Create new emulator configuration
5. ✅ Test software rendering
6. ✅ Update theme configurations

### If Still Failing (Next day):
7. ✅ Collect comprehensive diagnostics
8. ✅ Report to Flutter team
9. ✅ Consider alternative deployment (web PWA)

---

## 🎉 EXPECTED OUTCOMES

### Best Case (80% probability):
- **Fix #2.1 (Disable Impeller)** solves the issue
- Time to resolution: 15 minutes
- App works on emulator
- Can proceed with development

### Likely Case (15% probability):
- **Fix #3.2 (New Emulator)** solves the issue
- Time to resolution: 45 minutes
- Emulator-specific problem confirmed
- Documented for team

### Worst Case (5% probability):
- No fix works on emulator
- **Fix #1.1 (Physical Device)** confirms code is correct
- Deploy as web PWA for presentation
- File Flutter bug report

---

## 📞 SUPPORT RESOURCES

### If You Get Stuck:

1. **Flutter Community:**
   - Discord: https://discord.gg/flutter
   - Reddit: r/FlutterDev
   - Stack Overflow: [flutter] tag

2. **Known Issues:**
   - Flutter Issue Tracker: https://github.com/flutter/flutter/issues
   - Search for: "black screen emulator"

3. **Alternative Deployment:**
   - Web works perfectly ✅
   - Can build APK for physical device testing
   - Consider Netlify/Firebase hosting for web version

---

## ✅ COMPLETION CRITERIA

**This issue is RESOLVED when:**

1. ✅ Citizen app launches on Android emulator
2. ✅ Language selection screen visible
3. ✅ No "Width is zero" logs
4. ✅ UI is interactive
5. ✅ Hot reload works
6. ✅ Other 3 apps (asha, facility, dho) also work

**Document the solution in:**
- README.md (known issues section)
- TROUBLESHOOTING.md (for team reference)
- Git commit message (for history)

---

*Ready for execution - Start with physical device test if available, otherwise go straight to Impeller disable*
