# Image Picker Setup

## Permissions Added

### Android (`android/app/src/main/AndroidManifest.xml`)
- `CAMERA` - For taking photos
- `READ_EXTERNAL_STORAGE` - For reading images from gallery (Android 12 and below)
- `WRITE_EXTERNAL_STORAGE` - For saving images (Android 12 and below)
- `READ_MEDIA_IMAGES` - For reading images from gallery (Android 13+)

### iOS (`ios/Runner/Info.plist`)
- `NSCameraUsageDescription` - Camera access permission
- `NSPhotoLibraryUsageDescription` - Photo library access permission
- `NSPhotoLibraryAddUsageDescription` - Save to photo library permission

## Important: Rebuild Required

After adding these permissions, you **MUST** rebuild the app completely:

1. **Stop the app** if it's running
2. **Clean the build**:
   ```bash
   flutter clean
   ```
3. **Get dependencies**:
   ```bash
   flutter pub get
   ```
4. **Rebuild and run**:
   ```bash
   flutter run
   ```

**Note**: Hot reload/hot restart will NOT work for permission changes. A full rebuild is required.

## Testing

1. Try selecting an image from Gallery - should work now
2. Try taking a photo with Camera - should work now
3. If you still get errors, check:
   - App permissions in device settings
   - That you've granted permissions when prompted
   - That the app was fully rebuilt (not just hot reloaded)

