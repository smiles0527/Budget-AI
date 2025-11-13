# How to Run the iOS App

## Prerequisites

1. **Xcode** (latest version recommended)
2. **macOS** (required for iOS development)
3. **Backend running** (see backend README)

## Quick Start

### Option 1: iOS Simulator (Easiest)

1. **Start the backend:**
   ```bash
   docker compose up -d db minio api worker
   ```

2. **Open the project:**
   ```bash
   open testapp.xcodeproj
   ```

3. **Select a simulator** (e.g., iPhone 15 Pro)

4. **Click Run** (⌘R) or press the Play button

5. **The app will launch** and connect to `http://localhost:8000`

### Option 2: Real iOS Device

**Important:** `localhost` won't work on a real device! You need to use your Mac's IP address.

1. **Find your Mac's IP address:**
   ```bash
   # On macOS
   ifconfig | grep "inet " | grep -v 127.0.0.1
   # Look for something like: 192.168.1.100
   ```

2. **Update the API URL:**
   - Open `testapp/Services/AppConfig.swift`
   - Change the development baseURL to use your Mac's IP:
   ```swift
   case .development:
       return "http://192.168.1.100:8000/v1"  // Replace with your Mac's IP
   ```

3. **Make sure your Mac and iPhone are on the same WiFi network**

4. **Connect your iPhone via USB**

5. **Select your device** in Xcode

6. **Click Run**

## First Run

1. **Sign up** with a test email
2. **Login** with your credentials
3. **Start using the app!**

## Troubleshooting

### "Cannot connect to server"
- **Simulator:** Make sure backend is running (`docker compose ps`)
- **Real device:** 
  - Check Mac's IP address is correct
  - Ensure Mac and iPhone on same WiFi
  - Check Mac's firewall isn't blocking port 8000

### "Camera not available"
- Simulator doesn't have a real camera
- Use "Choose from Library" option instead
- Or test on a real device

### Build Errors
- Make sure all files are added to the Xcode project
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Restart Xcode if needed

## Testing Different Environments

Edit `AppConfig.swift` to switch environments:

```swift
private init() {
    // Force a specific environment for testing
    self.environment = .development  // or .staging, .production
}
```

## Next Steps

Once running:
1. Test all features
2. Fix any bugs
3. Update API URLs for production
4. Add proper environment configuration
5. Test on multiple devices



