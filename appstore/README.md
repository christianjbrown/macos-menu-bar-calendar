# App Store Kit 🛍️

Everything the Mac App Store listing needs, kept next to the code so it changes with the app.

## 📝 What's here

- `metadata/<locale>/`: the name, subtitle, promotional text, description and keywords for each language the app speaks, one file per App Store Connect field. Copy and paste them in, or point a tool like fastlane's `deliver` at the folder, since the file names follow its layout.
- `review_notes.txt`: the note for App Review, because a menu bar app with no window confuses people who expect one.
- `screenshots/`: not in git. Make them with `swift run StoreScreenshotTool appstore/screenshots`. You get four 2880 x 1800 shots per language, drawn from the real calendar view.

The privacy policy is [PRIVACY.md](../PRIVACY.md) at the top of the repo, and the support page is the repo's issues page.

## 🚀 Shipping a build

1. Copy `app-store.env.example` to `app-store.env` and fill in your App ID and team. Git ignores it.
2. Sign Xcode in to your developer account (Xcode, Settings, Accounts). Xcode makes the distribution certificate and provisioning profile for you the first time.
3. Bump `CFBundleShortVersionString` in `Support/Info.plist` for a new version. The build number counts commits, so it goes up on its own.
4. Run `scripts/app-store.sh` to check the package builds, then `scripts/app-store.sh --upload` to send it to App Store Connect.

Then pick the build in App Store Connect and submit it for review. 🤞
