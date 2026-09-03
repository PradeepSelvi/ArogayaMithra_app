# Test Credentials for ArogyaMitra

## Citizen App - Phone Login Flow

The citizen app uses phone authentication with OTP (One-Time Password). For **local development**, test phone numbers are configured with a **fixed OTP code**.

### Summary: How Many Mobile Logins?

Your ArogyaMitra project has **4 mobile applications**, each with different authentication:

| App | Login Method | User Type |
|-----|--------------|-----------|
| **Citizen** | Phone + OTP | Citizens/Patients |
| **ASHA** | Email + Password | ASHA Workers |
| **Facility** | Email + Password | Medical Officers/Staff |
| **DHO** | Email + Password | District Health Officers |

---

## 1. Citizen App 📱
**Login Method:** Phone Number + OTP (One-Time Password)

### Test Phone Numbers

Use any of these phone numbers to sign in as a citizen:

| Phone Number (Enter this) | Format with country code | Fixed OTP Code |
|---------------------------|-------------------------|----------------|
| `9876500001` | +91 9876500001 | `123456` |
| `9876500002` | +91 9876500002 | `123456` |
| `9876500003` | +91 9876500003 | `123456` |

**Important**: Just enter the 10-digit number (e.g., `9876500002`). The app automatically adds the +91 country code.

### Complete Citizen Login Flow

1. **Language Selection** (first time only)
   - Choose தமிழ் (Tamil) or English
   - Preference is saved locally

2. **Phone Number Entry**
   - Enter test number (e.g., `9876500002`)
   - App adds +91 automatically
   - Tap "Send code"

3. **OTP Verification**
   - Enter: `123456`
   - Tap "Verify"
   - Done! ✅

---

## 2. ASHA Worker App 🏥
**Login Method:** Email + Password

### Test Account
- **Email:** `asha@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`
- **User:** Lakshmi Arumugam
- **Role:** ASHA Worker (Tiruvannamalai block)

### How to Sign In
1. Open the ASHA app
2. Enter email: `asha@arogyamitra.local`
3. Enter password: `ArogyaMitra@2026`
4. Tap "Sign In"

---

## 3. Facility Staff App 🏨
**Login Method:** Email + Password

### Test Accounts

#### Medical Officer - District Hospital
- **Email:** `mo.district@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`
- **User:** Dr Ravi Kumar
- **Role:** Medical Officer
- **Facility:** District Headquarters Hospital, Tiruvannamalai
- **Employee Code:** MO-TVM-001

#### Medical Officer - PHC Polur
- **Email:** `mo.polur@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`
- **User:** Dr Priya Natarajan
- **Role:** Medical Officer
- **Facility:** Primary Health Centre, Polur
- **Employee Code:** MO-PLR-001

### How to Sign In
1. Open the Facility app
2. Enter one of the email addresses above
3. Enter password: `ArogyaMitra@2026`
4. Tap "Sign In"

---

## 4. DHO (District Health Officer) App 📊
**Login Method:** Email + Password

### Test Account
- **Email:** `dho@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`
- **User:** DHO Tiruvannamalai
- **Role:** District Health Officer
- **District:** Tiruvannamalai

### How to Sign In
1. Open the DHO app
2. Enter email: `dho@arogyamitra.local`
3. Enter password: `ArogyaMitra@2026`
4. Tap "Sign In"

---

## Quick Reference Table

| App | Email | Password | Phone | OTP |
|-----|-------|----------|-------|-----|
| **Citizen** | - | - | `9876500002` | `123456` |
| **ASHA** | `asha@arogyamitra.local` | `ArogyaMitra@2026` | - | - |
| **Facility (DHO Hospital)** | `mo.district@arogyamitra.local` | `ArogyaMitra@2026` | - | - |
| **Facility (PHC Polur)** | `mo.polur@arogyamitra.local` | `ArogyaMitra@2026` | - | - |
| **DHO** | `dho@arogyamitra.local` | `ArogyaMitra@2026` | - | - |

---

## Authentication Methods Summary

### 1. Phone Authentication (Citizen Only)
- **Process:** Phone → OTP → Verify
- **Local Dev:** Fixed OTP codes for test numbers
- **No password required**

### 2. Email/Password Authentication (All Staff)
- **Process:** Email → Password → Sign In
- **Provisioned accounts only** (no self-registration)
- **All staff password:** `ArogyaMitra@2026`

---

### Pre-seeded Test Citizen
- **Name:** Meena Ravi
- **Phone:** `9876500002`
- **OTP:** `123456`
- **User ID:** `aaaa0005-0000-4000-8000-000000000005`

### Pre-seeded Staff Users

#### ASHA Worker
- **Name:** Lakshmi Arumugam
- **Email:** `asha@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`
- **Block:** Tiruvannamalai

#### Facility Staff
1. **Dr Ravi Kumar** - District Hospital
   - Email: `mo.district@arogyamitra.local`
   - Facility: District Headquarters Hospital
   
2. **Dr Priya Natarajan** - PHC Polur
   - Email: `mo.polur@arogyamitra.local`
   - Facility: Primary Health Centre, Polur

#### DHO
- **Name:** DHO Tiruvannamalai
- **Email:** `dho@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`

---

### Why Your Number (9043131471) Failed

The phone number **9043131471** you entered is **NOT** in the test configuration. The error message you saw:

> ❌ "We could not sign you in. Please check the details and try again."

This happens because:

1. **Only pre-configured test numbers work** in local development
2. Your number `9043131471` is not in the test list
3. No real SMS provider is configured locally
4. The app rejects any non-test numbers to prevent accidental SMS sending

**Solution**: Use one of the test numbers above instead:
- Try `9876500002` with OTP `123456`

### For Production

In a production deployment:
- A real SMS provider (Twilio, etc.) must be configured
- The test_otp entries must be removed from config.toml
- Any valid phone number can receive a real OTP code

---

## Other Apps - Email Login

These apps use **Email + Password** authentication with administrator-provisioned accounts.

**Universal Staff Password:** `ArogyaMitra@2026`

### ASHA Worker App
- **Email:** `asha@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`

### Facility Staff App
Option 1:
- **Email:** `mo.district@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`

Option 2:
- **Email:** `mo.polur@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`

### DHO App
- **Email:** `dho@arogyamitra.local`
- **Password:** `ArogyaMitra@2026`

---

## Configuration Location

The test OTP configuration is in: `supabase/config.toml`

```toml
[auth.sms.test_otp]
919876500002 = "123456"
919876500001 = "123456"
919876500003 = "123456"
```

## Adding Your Own Test Number (9043131471)

If you want to use **9043131471** for testing, follow these steps:

### Option 1: Add to Supabase Config (Recommended for Development)

1. **Open the config file**:
   ```
   supabase/config.toml
   ```

2. **Find the `[auth.sms.test_otp]` section** (around line 266):
   ```toml
   [auth.sms.test_otp]
   919876500002 = "123456"
   919876500001 = "123456"
   919876500003 = "123456"
   ```

3. **Add your number** (format: country code + 10 digits, NO plus sign):
   ```toml
   [auth.sms.test_otp]
   919876500002 = "123456"
   919876500001 = "123456"
   919876500003 = "123456"
   919043131471 = "123456"  # ← Add this line
   ```

4. **Restart Supabase**:
   ```bash
   supabase stop
   supabase start
   ```

5. **Now you can sign in** with:
   - Phone: `9043131471`
   - OTP: `123456`

### Option 2: Use an Existing Test Number

Just use `9876500002` with OTP `123456` - it's already configured and ready to go!
