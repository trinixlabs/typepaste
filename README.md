# TypePaste

![TypePaste Logo](./logo/typepaste_app/apple-devices/AppIcon.appiconset/icon-mac-128x128.png)

TypePaste is a lightweight macOS menu-bar app that reads the current clipboard text and types it into the active app as if you were typing. It is built for product demos and screen recordings where you want a natural, human-like typing effect without manually retyping content.

**Features**
- Global hotkey to type clipboard contents into any app.
- Human-like typing with configurable delays.
- Recording mode that increases delays to avoid dropped characters in screen recordings.
- Menu-bar UI with quick access to settings.

**How To Run**
1. Open `TypePaste.xcodeproj` in Xcode.
2. Select the `TypePaste` scheme.
3. Press `Run`.
4. When prompted, grant Accessibility permissions in `System Settings > Privacy & Security > Accessibility`.

**How To Build**
1. Open `TypePaste.xcodeproj` in Xcode.
2. Select the `TypePaste` scheme.
3. Use `Product > Build` or `Product > Archive` to create a build.

**Install (Unsigned Release)**
1. Download the `.zip` from GitHub Releases.
2. Unzip it to get `TypePaste.app`.
3. Drag it to `/Applications`.
4. On first launch: right-click `TypePaste.app` → `Open` → `Open`.

**Build App**
1. Open `TypePaste.xcodeproj` in Xcode.
2. Select the `TypePaste` scheme.
3. Use `Product > Archive` to create a release build.
4. In Organizer: `Distribute App` → `Custom` → `Copy App`.
5. Choose “Do not sign” and export the `.app`.
6. Compress the `.app` into a `.zip` for distribution.

**Notes**
- The default hotkey is `⌘1`. You can change the hotkey in Settings.
- The app uses Accessibility to post keyboard events, so it must be allowed in Privacy & Security.
