# ✅ Android Fix Execution Checklist

**Date:** September 3, 2026  
**Issue:** Black screen on Android emulator  
**Estimated Time:** 15-45 minutes

---

## 📋 PRE-EXECUTION CHECKLIST

### Prerequisites
- [ ] In project root directory (`c:\Users\prade\Videos\sih\`)
- [ ] Flutter is installed and in PATH
- [ ] Android emulator is available
- [ ] PowerShell terminal is open
- [ ] Have reviewed `QUICK_START_ANDROID_FIX.md`

### Optional (Recommended)
- [ ] Physical Android device available for testing
- [ ] USB cable for device connection
- [ ] Git repository is clean (no uncommitted changes)

---

## 🚀 EXECUTION STEPS

### STEP 1: Run Diagnostics (Optional but Recommended)
**Time:** 2 minutes

```powershell
.\fix-android-rendering.ps1 -Mode diagnostic
```

**Review output:**
- [ ] Flutter doctor shows no critical issues
- [ ] Emulator is detected
- [ ] Android SDK is properly configured

---

### STEP 2: Apply Quick Fix
**Time:** 10 minutes

```powershell
.\fix-android-rendering.ps1 -Mode quick
```

**Watch for:**
- [ ] Script creates backups (check for `android-backup-*` folder)
- [ ] "Impeller disabled" message appears
- [ ] "Theme updated" message appears
- [ ] Build completes without errors
- [ ] App launches on emulator

---

### STEP 3: Verify Success
**Time:** 3 minutes

**Visual Verification:**
- [ ] Language selection screen appears
- [ ] Background is white (NOT black)
- [ ] ArogyaMitra logo/branding visible
- [ ] "தமிழ்" button visible and styled
- [ ] "English" button visible and styled
- [ ] UI is sharp and clear (not blurry)

**Functional Verification:**
- [ ] Can tap Tamil button
- [ ] Can tap English button
- [ ] UI responds to touches
- [ ] No app crashes
- [ ] No ANR dialogs

**Technical Verification:**
```powershell
# In separate terminal (optional)
adb logcat | Select-String -Pattern "Width is zero"
```
- [ ] No "Width is zero" messages
- [ ] No ERROR messages in logs

**Development Verification:**
- [ ] Press 'r' in terminal (hot reload)
- [ ] Press 'R' in terminal (hot restart)
- [ ] Both work correctly

---

### STEP 4a: If Success ✅
**Time:** 5 minutes

- [ ] Test navigation (tap language button, verify next screen)
- [ ] Test Supabase connection (check logs for initialization)
- [ ] Make a small UI change and hot reload
- [ ] Note which fix worked (Impeller disable)
- [ ] Proceed to POST-FIX CHECKLIST below

---

### STEP 4b: If Still Black Screen ❌
**Time:** 10 minutes

#### Option 1: Physical Device Test
```powershell
.\fix-android-rendering.ps1 -Mode test-device
```

- [ ] Connected phone appears in device list
- [ ] Selected phone ID
- [ ] App launched on phone
- [ ] **If works on phone:** Issue is emulator-specific → Proceed to Option 2
- [ ] **If fails on phone:** Proceed to Option 3

#### Option 2: Software Rendering
```powershell
cd apps\citizen
flutter.bat run -d emulator-5554 --enable-software-rendering
```

- [ ] App launches with software rendering
- [ ] **If works:** GPU hardware issue confirmed
- [ ] **If fails:** Proceed to Option 3

#### Option 3: New Emulator
```powershell
# In Android Studio:
# Tools → Device Manager → Create Device
# - Device: Pixel 3
# - System: Android 13 (API 33)
# - Graphics: Hardware - GLES 2.0

flutter.bat devices  # Get new emulator ID
flutter.bat run -d <new-emulator-id>
```

- [ ] New emulator created
- [ ] App launched on new emulator
- [ ] **If works:** Document the working configuration
- [ ] **If fails:** Proceed to ESCALATION

---

## ✅ POST-FIX CHECKLIST

### Immediate Tasks
- [ ] Document which fix worked
- [ ] Test all navigation flows
- [ ] Test authentication (if applicable)
- [ ] Verify Supabase connection
- [ ] Test hot reload/restart

### Code Documentation
- [ ] Update README.md with fix notes
- [ ] Create commit with clear message:
  ```
  fix(android): disable Impeller to resolve black screen on emulator
  
  - Added meta-data to disable Impeller rendering
  - Updated NormalTheme with explicit window config
  - Fixes "Width is zero" ViewTreeObserver issue
  - Tested on: Pixel 10, API 36
  ```
- [ ] Push to repository

### Team Communication
- [ ] Notify team of fix
- [ ] Share working emulator configuration
- [ ] Update onboarding docs (if applicable)

### Extended Testing (Optional)
- [ ] Test ASHA app on Android
- [ ] Test Facility app on Android
- [ ] Test DHO app on Android
- [ ] Test on different Android versions (if available)

---

## 📊 RESULTS DOCUMENTATION

### What Fixed It?
*Check the solution that worked:*

- [ ] Impeller disable (Quick fix)
- [ ] Theme updates (Quick fix)
- [ ] Software rendering mode
- [ ] New emulator configuration
- [ ] Physical device only
- [ ] Other: _______________

### Working Configuration
```
Emulator: _______________
Android Version: _______________
API Level: _______________
Graphics Mode: _______________
Flutter Version: 3.41.2
Dart Version: 3.11.0
```

### Time Spent
```
Total time: _____ minutes
Attempts needed: _____
```

### Notes
```
(Any special observations or issues encountered)








```

---

## 🆘 ESCALATION CHECKLIST

### If All Fixes Fail:

#### Collect Full Diagnostics
- [ ] Run: `.\fix-android-rendering.ps1 -Mode diagnostic`
- [ ] Run: `flutter.bat doctor -v > full-diagnostics.txt`
- [ ] Run: `flutter.bat run -d emulator-5554 --verbose > verbose-run.log 2>&1`
- [ ] Capture screenshot of black screen
- [ ] Capture emulator settings screenshot

#### Review Documentation
- [ ] Re-read `ANDROID_FIX_IMPLEMENTATION_PLAN.md`
- [ ] Check Phase 5: Deep Diagnostics
- [ ] Review Flutter GitHub issues for similar problems

#### Alternative Solutions
- [ ] Deploy web version (works 100%)
- [ ] Use physical device exclusively
- [ ] Update Flutter: `flutter upgrade`
- [ ] Reinstall Android SDK

#### Get Help
- [ ] Post on Flutter Discord with diagnostics
- [ ] Create Stack Overflow question with logs
- [ ] File Flutter GitHub issue if it's a bug

---

## 📞 QUICK REFERENCE

### Commands
```powershell
# Apply quick fix
.\fix-android-rendering.ps1 -Mode quick

# Test on device
.\fix-android-rendering.ps1 -Mode test-device

# Full fix mode
.\fix-android-rendering.ps1 -Mode full

# Diagnostics only
.\fix-android-rendering.ps1 -Mode diagnostic

# Software rendering
flutter.bat run -d emulator-5554 --enable-software-rendering

# Check devices
flutter.bat devices

# Clean build
cd apps\citizen
flutter.bat clean
flutter.bat pub get
flutter.bat run -d emulator-5554
```

### Files Modified
```
apps/citizen/android/app/src/main/AndroidManifest.xml
apps/citizen/android/app/src/main/res/values/styles.xml
```

### Backup Location
```
android-backup-<timestamp>/
```

### Rollback
```powershell
# Restore from backup
copy android-backup-*\AndroidManifest.xml apps\citizen\android\app\src\main\
copy android-backup-*\styles.xml apps\citizen\android\app\src\main\res\values\
```

---

## 🎯 SUCCESS DEFINITION

**This checklist is COMPLETE when:**

1. ✅ App launches on Android emulator/device
2. ✅ Language selection screen is visible
3. ✅ All UI elements are interactive
4. ✅ No "Width is zero" errors in logs
5. ✅ Hot reload works
6. ✅ Solution is documented
7. ✅ Code is committed
8. ✅ Team is notified

---

## 📝 SIGN-OFF

### Execution Completed
- **Date:** _______________
- **Time Spent:** _______________
- **Solution Used:** _______________
- **Status:** ✅ SUCCESS / ❌ NEEDS ESCALATION

### Notes for Future
```
(Document any learnings, gotchas, or recommendations)








```

---

*Start execution: `.\fix-android-rendering.ps1 -Mode quick`*
