# Quick Test Guide - Stripe 3D Secure Fix

## 🎯 Goal
Verify that Stripe 3D Secure authentication completes WITHOUT crashes.

## 🧪 Test Card (Stripe Test Mode)
```
Card: 4000 0025 0000 3155
Expiry: Any future date (e.g., 12/26)
CVC: Any 3 digits (e.g., 123)
ZIP: Any 5 digits (e.g., 12345)
```

## ✅ Quick Test Steps

### Test 1: Add Payment Method (2 minutes)
1. Open ARTbeat app
2. Go to **Profile → Settings → Payment Methods**
3. Tap **"Add Payment Method"**
4. Enter test card: `4000 0025 0000 3155`
5. **3D Secure popup should appear**
6. Complete authentication
7. ✓ **SUCCESS:** Card added without crash
8. ✗ **FAILURE:** App crashes with PassiveChallengeViewModel error

### Test 2: Subscription Payment (3 minutes)
1. Navigate to **Artist → Subscriptions**
2. Select any paid tier
3. Use the 3DS test card above
4. Complete 3D Secure challenge
5. ✓ **SUCCESS:** Subscription activated
6. ✗ **FAILURE:** IntentConfirmationChallenge crash

### Test 3: Commission Payment (5 minutes)
1. Create a test commission
2. Process deposit payment
3. Enter 3DS test card
4. Complete attestation flow
5. ✓ **SUCCESS:** Payment processes
6. ✗ **FAILURE:** AttestationViewModel crash

## 🔍 What to Look For

### ✓ Expected Behavior (GOOD)
- 3D Secure popup appears smoothly
- Authentication completes
- Returns to app without crash
- Payment method/subscription is saved
- No error messages

### ✗ Previous Crashes (SHOULD NOT HAPPEN)
- App crashes when 3DS popup appears
- "NoArgsException" in logs
- "IllegalArgumentException" errors
- Blank screen during authentication
- App force closes

## 📱 Test on Multiple Devices
- [ ] Pixel/Samsung (Android 14+)
- [ ] Older Android device (Android 10-13)
- [ ] Different screen sizes

## 📊 Report Results
After testing, report:
- ✅ All tests passed
- ⚠️ Some issues found (specify which)
- ❌ Crashes still occurring

## 🔧 If Tests Fail
1. Check Logcat for crash logs
2. Verify ProGuard rules are applied
3. Confirm build is release mode
4. Check Stripe initialization logs

---

**Pro Tip:** Use Android Studio Logcat filtered by "Stripe" to see detailed 3DS flow logs.
