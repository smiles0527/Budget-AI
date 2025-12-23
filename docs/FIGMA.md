# Figma Integration Setup

This guide explains how to integrate Figma designs into the iOS app so your UI designer can work in Figma and have those designs automatically sync to the app.

## Overview

The app uses a design system that can be synced from Figma. This allows:
- **Designers** to work in Figma with full design tools
- **Developers** to use those designs directly in SwiftUI
- **Automatic sync** of colors, typography, spacing, and other design tokens

## Setup Steps

### 1. Get Figma API Access

1. Go to [Figma Settings](https://www.figma.com/settings)
2. Scroll to "Personal Access Tokens"
3. Click "Create new token"
4. Name it (e.g., "Budget AI iOS App")
5. Copy the token (you'll only see it once!)

### 2. Get Your Figma File Key

1. Open your Figma file
2. Look at the URL: `https://www.figma.com/file/FILE_KEY/File-Name`
3. Copy the `FILE_KEY` part (the long string between `/file/` and `/`)

### 3. Configure the App

Edit `BudgetAI/Services/FigmaService.swift`:

```swift
struct FigmaConfig {
    static let apiToken = "YOUR_FIGMA_API_TOKEN_HERE"
    static let fileKey = "YOUR_FIGMA_FILE_KEY_HERE"
}
```

**⚠️ Security Note:** Don't commit these tokens to git! Use environment variables or a config file that's in `.gitignore`.

### 4. Organize Your Figma File

For the sync to work, organize your Figma file with these conventions:

#### Colors
- Create a frame/page named "Colors" or "Design Tokens"
- Use Figma's **Color Styles** feature:
  - Name colors like: `Primary`, `Secondary`, `Success`, `Error`, etc.
  - The sync script will read these styles

#### Typography
- Create a frame/page named "Typography"
- Use Figma's **Text Styles**:
  - Name styles like: `Heading 1`, `Body`, `Caption`, etc.
  - Include font family, size, weight, line height

#### Spacing
- Create a frame/page named "Spacing"
- Use rectangles or frames with specific sizes:
  - Name them: `XS (4px)`, `SM (8px)`, `MD (16px)`, etc.
  - The sync will read the width/height values

### 5. Sync Design Tokens

#### Option A: Manual Sync (Current)
Run the sync function in the app:

```swift
Task {
    await DesignSystemSync.syncFromFigma()
}
```

#### Option B: Automated Sync Script (Recommended)
Create a script to sync tokens:

```bash
# scripts/sync-figma-tokens.sh
#!/bin/bash

# Fetch tokens from Figma API
# Parse and generate Swift code
# Update DesignSystem.swift
```

### 6. Using Design Tokens in Code

Once synced, use the design system throughout the app:

```swift
// Colors
Text("Hello")
    .foregroundColor(AppColors.primary)

// Typography
Text("Title")
    .font(AppTypography.h1)

// Spacing
VStack(spacing: AppSpacing.md) {
    // ...
}

// Corner Radius
RoundedRectangle(cornerRadius: AppCornerRadius.medium)
```

## Figma File Structure Example

```
📁 Budget AI Design System
  📁 Colors
    🎨 Primary (Color Style)
    🎨 Secondary (Color Style)
    🎨 Success (Color Style)
    🎨 Error (Color Style)
  📁 Typography
    📝 Heading 1 (Text Style)
    📝 Body (Text Style)
    📝 Caption (Text Style)
  📁 Spacing
    ⬜ XS (4px)
    ⬜ SM (8px)
    ⬜ MD (16px)
    ⬜ LG (24px)
  📁 Components
    📱 Button
    📱 Card
    📱 Badge
```

## Advanced: Component Sync

For more advanced integration, you can:

1. **Export Components**: Use Figma's component system
2. **Generate SwiftUI Code**: Tools like [Figma to Code](https://www.figma.com/community/plugin/747985167520967365/Figma-to-Code) can generate SwiftUI
3. **Design Specs**: Use Figma's inspect mode to get exact values

## Troubleshooting

### "Invalid API Token"
- Check that your token is correct
- Make sure it hasn't expired
- Regenerate if needed

### "File Not Found"
- Verify the file key is correct
- Make sure the file is accessible (not private/restricted)

### "No Design Tokens Found"
- Check that you're using Figma Styles (not just named layers)
- Verify naming conventions match
- Check the file structure matches the expected format

## Next Steps

1. Set up your Figma file with design tokens
2. Configure API credentials
3. Run initial sync
4. Update views to use `AppColors`, `AppTypography`, etc.
5. Set up automated sync (CI/CD or local script)

## Resources

- [Figma API Docs](https://www.figma.com/developers/api)
- [Figma Styles Guide](https://help.figma.com/hc/en-us/articles/360038746534-Create-and-apply-text-styles)
- [SwiftUI Design System Best Practices](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/)

