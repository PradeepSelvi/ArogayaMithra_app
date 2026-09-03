# ArogyaMitra - Android Rendering Fix Script
# Applies systematic fixes for black screen issue

param(
    [ValidateSet("quick", "full", "diagnostic", "test-device")]
    [string]$Mode = "quick",
    
    [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"
$OriginalLocation = Get-Location

try {
    Write-Host "🔧 ArogyaMitra Android Rendering Fix" -ForegroundColor Cyan
    Write-Host "   Mode: $Mode" -ForegroundColor Gray
    Write-Host "   Device: $DeviceId" -ForegroundColor Gray
    Write-Host ""

    # Ensure we're in project root
    if (-not (Test-Path "apps\citizen")) {
        Write-Host "❌ Error: Must run from project root (sih directory)" -ForegroundColor Red
        exit 1
    }

    # Set PATH for Flutter
    $env:PATH = "C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:PATH

    switch ($Mode) {
        "test-device" {
            Write-Host "📱 Testing on Physical Device" -ForegroundColor Yellow
            Write-Host ""
            
            Write-Host "Prerequisites:" -ForegroundColor Cyan
            Write-Host "  1. Enable Developer Options (Settings > About > Tap Build Number 7x)"
            Write-Host "  2. Enable USB Debugging (Settings > Developer Options)"
            Write-Host "  3. Connect phone via USB"
            Write-Host "  4. Allow USB debugging popup on phone"
            Write-Host ""
            
            Write-Host "Checking connected devices..." -ForegroundColor Green
            flutter.bat devices
            
            Write-Host ""
            Write-Host "Enter device ID from list above: " -ForegroundColor Yellow -NoNewline
            $physicalDevice = Read-Host
            
            if ($physicalDevice) {
                Write-Host ""
                Write-Host "🚀 Launching on $physicalDevice..." -ForegroundColor Green
                Set-Location "apps\citizen"
                flutter.bat run -d $physicalDevice
            } else {
                Write-Host "❌ No device ID provided" -ForegroundColor Red
            }
        }
        
        "diagnostic" {
            Write-Host "🔍 Running Diagnostics" -ForegroundColor Yellow
            Write-Host ""
            
            $outputDir = "android-diagnostics-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            
            Write-Host "1️⃣ Flutter Doctor..." -ForegroundColor Green
            flutter.bat doctor -v | Tee-Object "$outputDir\flutter-doctor.txt"
            
            Write-Host "`n2️⃣ Connected Devices..." -ForegroundColor Green
            flutter.bat devices | Tee-Object "$outputDir\devices.txt"
            
            Write-Host "`n3️⃣ Available Emulators..." -ForegroundColor Green
            flutter.bat emulators | Tee-Object "$outputDir\emulators.txt"
            
            Write-Host "`n4️⃣ Checking Emulator Properties..." -ForegroundColor Green
            if (Get-Command adb -ErrorAction SilentlyContinue) {
                adb shell getprop | Select-String -Pattern "build.version|product.model|gles|gpu" | Tee-Object "$outputDir\emulator-props.txt"
            } else {
                Write-Host "   ⚠️ ADB not in PATH - skipping emulator properties" -ForegroundColor Yellow
            }
            
            Write-Host "`n✅ Diagnostics saved to $outputDir\" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "  - Review diagnostics files"
            Write-Host "  - Run: .\fix-android-rendering.ps1 -Mode quick"
            Write-Host "  - Or test on physical device: .\fix-android-rendering.ps1 -Mode test-device"
        }
        
        "quick" {
            Write-Host "⚡ Quick Fix Mode" -ForegroundColor Yellow
            Write-Host "   Applying Impeller disable + theme fixes" -ForegroundColor Gray
            Write-Host ""
            
            # Backup files
            Write-Host "📦 Creating backups..." -ForegroundColor Green
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backupDir = "android-backup-$timestamp"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            
            $manifestPath = "apps\citizen\android\app\src\main\AndroidManifest.xml"
            $stylesPath = "apps\citizen\android\app\src\main\res\values\styles.xml"
            
            Copy-Item $manifestPath "$backupDir\" -Force
            Copy-Item $stylesPath "$backupDir\" -Force
            Write-Host "   ✅ Backups saved to $backupDir\" -ForegroundColor Green
            
            # Fix 1: Disable Impeller
            Write-Host "`n1️⃣ Disabling Impeller rendering..." -ForegroundColor Green
            $manifest = Get-Content $manifestPath -Raw
            
            if ($manifest -notmatch "EnableImpeller") {
                Write-Host "   Adding Impeller disable flag..." -ForegroundColor Gray
                $metaData = "        <!-- DISABLE IMPELLER - USE SKIA RENDERING -->`r`n        <meta-data`r`n            android:name=`"io.flutter.embedding.android.EnableImpeller`"`r`n            android:value=`"false`" />`r`n"
                $manifest = $manifest -replace '(<application[^>]*>)', "`$1`r`n$metaData"
                Set-Content $manifestPath $manifest -NoNewline
                Write-Host "   ✅ Impeller disabled - will use Skia renderer" -ForegroundColor Green
            } else {
                Write-Host "   ℹ️ Impeller already configured" -ForegroundColor Gray
            }
            
            # Fix 2: Update Theme
            Write-Host "`n2️⃣ Updating theme configuration..." -ForegroundColor Green
            $newStyles = @'
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
         Flutter UI initializes, as well as behind your Flutter UI while its running. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@android:color/white</item>
        <item name="android:windowIsTranslucent">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">true</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
'@
            Set-Content $stylesPath $newStyles
            Write-Host "   ✅ Theme updated with explicit window configuration" -ForegroundColor Green
            
            # Fix 3: Clean build
            Write-Host "`n3️⃣ Cleaning build artifacts..." -ForegroundColor Green
            Set-Location "apps\citizen"
            flutter.bat clean | Out-Null
            
            if (Test-Path "android\app\build") {
                Remove-Item -Recurse -Force "android\app\build"
            }
            Write-Host "   ✅ Build cleaned" -ForegroundColor Green
            
            # Fix 4: Get dependencies
            Write-Host "`n4️⃣ Getting dependencies..." -ForegroundColor Green
            flutter.bat pub get | Out-Null
            Write-Host "   ✅ Dependencies resolved" -ForegroundColor Green
            
            # Fix 5: Run app
            Write-Host "`n5️⃣ Launching app on $DeviceId..." -ForegroundColor Green
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "   🎯 WATCH FOR:" -ForegroundColor Yellow
            Write-Host "   ✅ Language selection screen appears" -ForegroundColor Green
            Write-Host "   ✅ White background visible" -ForegroundColor Green
            Write-Host "   ✅ Tamil/English buttons clickable" -ForegroundColor Green
            Write-Host "   ❌ NO 'Width is zero' in logs" -ForegroundColor Red
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host ""
            
            flutter.bat run -d $DeviceId
        }
        
        "full" {
            Write-Host "🔧 Full Fix Mode" -ForegroundColor Yellow
            Write-Host "   Applying all fixes including software rendering test" -ForegroundColor Gray
            Write-Host ""
            
            # Run quick fixes first
            & $PSCommandPath -Mode quick -DeviceId $DeviceId
            
            Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Did the app render correctly? (y/n): " -ForegroundColor Yellow -NoNewline
            $response = Read-Host
            
            if ($response -ne "y") {
                Write-Host "`nTrying software rendering mode..." -ForegroundColor Cyan
                Set-Location "apps\citizen"
                flutter.bat clean | Out-Null
                Write-Host "Launching with --enable-software-rendering..." -ForegroundColor Green
                flutter.bat run -d $DeviceId --enable-software-rendering
            } else {
                Write-Host "`n🎉 Success! Android rendering issue fixed!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Applied fixes:" -ForegroundColor Cyan
                Write-Host "  ✅ Disabled Impeller (using Skia renderer)"
                Write-Host "  ✅ Updated Android theme configuration"
                Write-Host ""
                Write-Host "Backups saved in: android-backup-* directories" -ForegroundColor Gray
            }
        }
    }
    
} catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Ensure Flutter is in PATH"
    Write-Host "  2. Check emulator is running: flutter.bat devices"
    Write-Host "  3. Try diagnostic mode: .\fix-android-rendering.ps1 -Mode diagnostic"
    exit 1
} finally {
    Set-Location $OriginalLocation
}
