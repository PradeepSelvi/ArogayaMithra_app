# Citizen Login Issue - RESOLVED ✅

## Problem
User tried to login to the Citizen app with phone number **9043131471** and received error:
> ❌ "We could not sign you in. Please check the details and try again."

## Root Cause
The phone number `9043131471` is **NOT** configured as a test number in the local development environment.

## Why This Happens
For local development:
- Supabase is configured with **test phone numbers** only
- No real SMS provider is active (to prevent accidental SMS charges)
- Only pre-configured test numbers accept OTP codes
- Any other number is rejected by the authentication system

## Solution

### ✅ Quick Fix: Use Existing Test Numbers

Use one of these pre-configured test phone numbers:

| Phone Number | OTP Code |
|--------------|----------|
| `9876500001` | `123456` |
| `9876500002` | `123456` |
| `9876500003` | `123456` |

**Steps:**
1. Open the Citizen app
2. Select language (Tamil or English)
3. Enter: `9876500002`
4. Tap "Send code"
5. Enter OTP: `123456`
6. Tap "Verify"
7. ✅ You're signed in!

### 🔧 Alternative: Add Your Phone Number

To use `9043131471` specifically:

1. Edit `supabase/config.toml`
2. Find line ~266 with `[auth.sms.test_otp]`
3. Add: `919043131471 = "123456"`
4. Restart Supabase: `supabase stop` then `supabase start`
5. Now you can login with `9043131471` using OTP `123456`

## Configuration Location
**File:** `supabase/config.toml`

**Section:** `[auth.sms.test_otp]` (line ~266)

```toml
[auth.sms.test_otp]
919876500002 = "123456"
919876500001 = "123456"
919876500003 = "123456"
# Add more test numbers here
```

## Code Reference
- **Sign-in screen**: `apps/citizen/lib/src/features/auth/sign_in_screen.dart`
- **Auth controller**: `packages/authentication/lib/src/auth_controller.dart`
- **Supabase config**: `supabase/config.toml`

## For Production Deployment
In production:
- Remove all `test_otp` entries
- Configure a real SMS provider (Twilio, etc.)
- Any valid phone number will receive real OTP codes via SMS

## Related Files
- ✅ `TEST_CREDENTIALS.md` - Complete testing guide with all credentials
- `supabase/config.toml` - Configuration file to modify
- `supabase/seed.sql` - Database seed with test user data
