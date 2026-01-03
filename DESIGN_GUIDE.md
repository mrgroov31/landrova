# Modern Mini Cards Design Guide

## Overview
The modern mini cards now support:
- **Lottie Animations** - Animated illustrations via URI
- **Network Images** - Images from URLs
- **Icons** - Fallback Material icons
- **Modern Design** - Gradient backgrounds, shadows, and smooth animations

## How to Use

### 1. Using Lottie Animations

```dart
ModernStatMiniCard(
  title: 'Total Rooms',
  value: '6',
  lottieUri: 'https://lottie.host/embed/your-lottie-id.json',
  icon: Icons.home_outlined, // Fallback if Lottie fails
  color: Colors.blue,
  subtitle: 'Available spaces',
  showTrend: true,
)
```

**Where to get Lottie animations:**
- **LottieFiles**: https://lottiefiles.com/ (Free & Premium)
- **Lottie Host**: https://lottie.host/ (Free hosting)
- Search for: "home", "building", "money", "revenue", "people", "check"

### 2. Using Network Images

```dart
ModernStatMiniCard(
  title: 'Occupied',
  value: '4',
  imageUri: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200&h=200&fit=crop',
  icon: Icons.check_circle_outline, // Fallback if image fails
  color: Colors.green,
  subtitle: 'Currently rented',
)
```

**Where to get images:**
- **Unsplash**: https://unsplash.com/ (Free high-quality images)
- **Pexels**: https://www.pexels.com/ (Free stock photos)
- **Your CDN**: Upload to your own storage/CDN

### 3. Using Icons Only (Fallback)

```dart
ModernStatMiniCard(
  title: 'Revenue',
  value: '₹45K',
  icon: Icons.account_balance_wallet_outlined,
  color: Colors.purple,
  subtitle: 'This month',
)
```

## Design Features

### Visual Elements
- **Gradient Backgrounds**: Subtle gradients for depth
- **Border**: Colored borders matching the theme
- **Shadows**: Multi-layer shadows for elevation
- **Rounded Corners**: 20px border radius for modern look

### Interactive Elements
- **Tap Gestures**: Cards are tappable
- **Trend Indicators**: Optional trend badges
- **Subtitles**: Additional context text

### Responsive Design
- Automatically adjusts for mobile/tablet/desktop
- Optimized padding and sizing per device

## Configuration

### Update Asset URIs

Edit `lib/constants/app_assets.dart`:

```dart
class AppAssets {
  // Replace with your actual Lottie URIs
  static const String roomsLottie = 'https://lottie.host/embed/YOUR_ID.json';
  
  // Replace with your actual image URIs
  static const String occupiedRoomsImage = 'https://your-cdn.com/image.jpg';
}
```

### Priority Order
1. **Lottie URI** (if provided) - Shows animated illustration
2. **Image URI** (if provided) - Shows network image
3. **Icon** (fallback) - Shows Material icon

## Best Practices

1. **Always provide a fallback icon** - In case URIs fail to load
2. **Use optimized images** - Compress images for faster loading
3. **Test URIs** - Ensure your Lottie/image URIs are accessible
4. **Use appropriate colors** - Match colors to the card's purpose
5. **Add subtitles** - Provide context for better UX

## Example Card Configurations

### Revenue Card with Lottie
```dart
ModernStatMiniCard(
  title: 'Revenue',
  value: '₹45K',
  lottieUri: 'https://lottie.host/embed/money-animation.json',
  icon: Icons.account_balance_wallet_outlined,
  color: Colors.purple,
  subtitle: 'This month',
  showTrend: true,
)
```

### Occupied Rooms with Image
```dart
ModernStatMiniCard(
  title: 'Occupied',
  value: '4',
  imageUri: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43',
  icon: Icons.check_circle_outline,
  color: Colors.green,
  subtitle: 'Currently rented',
)
```

## Troubleshooting

### Lottie not loading?
- Check if the URI is accessible
- Verify the JSON format is valid
- Use fallback icon as backup

### Image not loading?
- Verify image URL is correct
- Check network connectivity
- Ensure image format is supported (JPG, PNG, WebP)

### Design issues?
- Adjust colors in `color` parameter
- Modify padding in widget if needed
- Check responsive breakpoints

