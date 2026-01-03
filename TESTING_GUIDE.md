# Testing Tenant Onboarding Feature

## Prerequisites
1. Make sure you've run `flutter pub get` to install new dependencies
2. Have the app running on a device/emulator

## Testing Steps

### 1. Test Invitation Link Generation (Owner Side)

1. **Open the app** and navigate to **Tenants** screen
2. **Tap the "Invite Tenant"** floating action button
3. **Select a vacant room** from the dropdown
4. **Optionally enter tenant name** (for reference)
5. **Tap "Generate Invitation Link"**
6. You should see:
   - ✅ Success message
   - Generated link displayed
   - Copy and Share buttons

### 2. Test Deep Linking (When App is Running)

#### On Android:
```bash
# Open terminal and run:
adb shell am start -W -a android.intent.action.VIEW -d "ownhouse://tenant/register?token=test123&room=101" com.example.own_house
```

#### On iOS (Simulator):
```bash
# Open terminal and run:
xcrun simctl openurl booted "ownhouse://tenant/register?token=test123&room=101"
```

#### Expected Result:
- App should navigate to Tenant Onboarding screen
- Room number should be pre-filled (if provided in link)
- Token should be stored

### 3. Test Deep Linking (When App is Closed)

#### On Android:
1. Close the app completely
2. Run the same adb command:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "ownhouse://tenant/register?token=test456&room=201" com.example.own_house
```

#### On iOS (Simulator):
1. Close the app completely
2. Run the same xcrun command:
```bash
xcrun simctl openurl booted "ownhouse://tenant/register?token=test456&room=201"
```

#### Expected Result:
- App should open
- Navigate directly to Tenant Onboarding screen
- Room number should be pre-filled

### 4. Test the Onboarding Form

1. **Step 1 - Personal Details:**
   - Upload profile photo (tap circle, choose from gallery or camera)
   - Enter full name
   - Room number should be pre-filled (if from link)
   - Select tenant type (Tenant or Paying Guest)
   - Enter monthly rent
   - Select move-in date
   - Optionally enter occupation
   - Tap "Next"

2. **Step 2 - Contact Details:**
   - Enter phone number
   - Enter email address
   - Enter Aadhar number
   - Optionally enter emergency contact
   - Tap "Next"

3. **Step 3 - Documents:**
   - Upload Aadhar Card (Front) - **Required**
   - Upload Aadhar Card (Back) - **Required**
   - Optionally upload PAN Card
   - Optionally upload Address Proof
   - Tap "Submit"

4. **Expected Result:**
   - ✅ Success message: "Registration completed successfully!"
   - App navigates back to dashboard/home
   - New tenant appears in Tenants list

### 5. Test Share Functionality

1. Generate an invitation link
2. Tap "Share" button
3. You should see native share dialog
4. Test sharing via:
   - WhatsApp
   - SMS
   - Email
   - Copy to clipboard

### 6. Verify Data Persistence

1. After submitting the form:
   - Go to Tenants screen
   - Verify new tenant appears in the list
   - Check that all details are correct
2. Restart the app:
   - Tenant data should persist (stored in Hive)
   - Should still appear in the list

## Quick Test Commands

### Generate Test Link Manually
You can manually create a test link:
```
ownhouse://tenant/register?token=manualtest123&room=301
```

### Test with Different Scenarios

1. **Link with room number:**
   ```
   ownhouse://tenant/register?token=test1&room=101
   ```

2. **Link without room number:**
   ```
   ownhouse://tenant/register?token=test2
   ```

3. **Invalid link (should not crash):**
   ```
   ownhouse://tenant/register
   ```

## Troubleshooting

### Deep Link Not Working?

1. **Android:**
   - Check `AndroidManifest.xml` has the intent-filter
   - Make sure package name matches: `com.example.own_house`
   - Try: `flutter clean` and rebuild

2. **iOS:**
   - Check `Info.plist` has CFBundleURLTypes
   - Make sure you're testing on simulator or real device (not just hot reload)
   - Try: `flutter clean` and rebuild

### Form Not Submitting?

1. Check all required fields are filled
2. Check required documents are uploaded
3. Check console for error messages
4. Verify Hive is initialized properly

### Tenant Not Appearing in List?

1. Check TenantService is being used (not just API)
2. Verify Hive adapter is registered
3. Check console for errors
4. Try refreshing the list (pull to refresh)

## Testing Checklist

- [ ] Can generate invitation link
- [ ] Can copy invitation link
- [ ] Can share invitation link
- [ ] Deep link works when app is running
- [ ] Deep link works when app is closed
- [ ] Room number pre-fills from link
- [ ] All form steps work correctly
- [ ] Form validation works
- [ ] Document upload works
- [ ] Form submission succeeds
- [ ] Tenant appears in list after submission
- [ ] Data persists after app restart

