# Gift IAP Setup Checklist - URGENT

## ❌ Current Issue: "Gift purchase could not be completed"

This error means the IAP products are **not available from the store**. Follow this checklist:

---

## ✅ Step 1: Verify Products in App Store Connect (iOS)

### Check if products exist:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **ArtBeat** app
3. Go to **In-App Purchases**
4. **Look for these 4 products:**
   - `artbeat_gift_small` - Supporter Gift ($4.99)
   - `artbeat_gift_medium` - Fan Gift ($9.99)
   - `artbeat_gift_large` - Patron Gift ($24.99)
   - `artbeat_gift_premium` - Benefactor Gift ($49.99)

### If products DON'T exist:

1. Click **Create In-App Purchase**
2. Select **Consumable** (NOT subscription)
3. For each gift:
   - **Product ID**: Use exact SKU (e.g., `artbeat_gift_small`)
   - **Reference Name**: Same as SKU
   - **Price**: Set to match table above
   - **Display Name**: "Supporter Gift", "Fan Gift", etc.
   - **Description**: "Give [amount] credits to support an artist"
4. Add localization for at least one language
5. Add a screenshot (can be simple)
6. **Save** and **Submit for Review**

### If products exist but showing "Waiting for Review":

- Products must be **approved** before they work in production
- Use **Sandbox Testing** with test account until approved
- Takes 24-48 hours for approval

---

## ✅ Step 2: Verify Products in Google Play Console (Android)

### Check if products exist:

1. Go to [Google Play Console](https://play.google.com/console)
2. Select **ArtBeat** app
3. Go to **Monetize** → **In-app products**
4. **Look for these 4 products:**
   - `artbeat_gift_small`
   - `artbeat_gift_medium`
   - `artbeat_gift_large`
   - `artbeat_gift_premium`

### If products DON'T exist:

1. Click **Create product**
2. Select **Managed product** (consumable)
3. For each gift:
   - **Product ID**: Use exact SKU
   - **Name**: "Supporter Gift", "Fan Gift", etc.
   - **Description**: Include credit amount
   - **Price**: Set to match table above
   - **Status**: Set to **Active**
4. **Save**

---

## ✅ Step 3: Testing Before Production

### iOS Sandbox Testing:

1. Create test user in App Store Connect → **Users and Access** → **Sandbox Testers**
2. On device: **Settings** → **App Store** → **Sandbox Account**
3. Sign in with test account
4. Products will appear in app immediately (no review needed)

### Android Testing:

1. Add test account in Play Console → **Setup** → **License Testing**
2. Install **internal test** or **closed test** build
3. Products work immediately for test accounts

---

## ✅ Step 4: Check App Configuration

Run this command to check if products are loading:

```bash
flutter run --verbose 2>&1 | grep -i "product\|iap\|purchase"
```

**Expected output:**

```
✅ In-app purchases are available on this device
✅ Loaded 18 products
Product: artbeat_gift_small - Supporter Gift - $4.99
Product: artbeat_gift_medium - Fan Gift - $9.99
Product: artbeat_gift_large - Patron Gift - $24.99
Product: artbeat_gift_premium - Benefactor Gift - $49.99
```

**If you see:**

```
⚠️ Loaded 0 products
```

or

```
❌ Product not found: artbeat_gift_small
```

**Then products are NOT configured in the store.**

---

## ✅ Step 5: Quick Test

1. Open app, click "Debug Info" button in gift modal
2. Check console logs for:

   ```
   IAP Available: true
   Gift products config: true
   ```

3. If `false`, products aren't loaded from store yet

---

## 🔧 Quick Fix for Testing

If you need to test NOW before store approval:

### Option A: Use StoreKit Configuration (iOS only)

1. In Xcode, create `Products.storekit` file
2. Add all 4 gift products with exact SKUs
3. Run in simulator with StoreKit enabled
4. Products work immediately without App Store

### Option B: Use real test account

1. Set up sandbox tester (iOS) or license testing (Android)
2. Products must still be created in store (even if not approved)
3. Test accounts can purchase without charges

---

## 📋 Current Code Status

✅ Code is correct - all SKUs match IAP_SKU_LIST.md  
✅ Metadata flow fixed - gifts will complete properly  
✅ Error handling improved - better diagnostics  
✅ UI shows proper loading/error states

❌ **ONLY ISSUE**: Products not in App Store Connect/Play Console

---

## Next Steps

1. **Check if products exist in stores** (Step 1 & 2)
2. **If not**: Create them following steps above
3. **If yes but pending**: Use sandbox testing
4. **If approved**: Try gift purchase again - should work!

The gift system code is now production-ready. The only remaining issue is store configuration.
