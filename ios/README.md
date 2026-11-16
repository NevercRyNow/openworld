# OpenWorld iOS wrapper

This is a small WKWebView wrapper around the live OpenWorld site:

```text
https://nevercrynow.github.io/openworld/?v=3
```

## Build unsigned IPA

The build is done on a macOS GitHub Actions runner, because this environment has no Swift/Xcode toolchain.

```bash
brew install xcodegen
cd ios
./build-ipa.sh
```

Or run **Actions → Build OpenWorld iOS IPA → Run workflow** and download the `OpenWorld-unsigned-ipa` artifact.

The workflow is `.github/workflows/ios-ipa.yml`.

## Important

- This is **not** a rebuild of the native iOSHub app; it is a wrapper around the website.
- The IPA is **unsigned**. Installing it requires a signing tool (SideStore/AltStore/Sideloadly with a certificate, or TrollStore on supported iOS versions).
- There is no signing certificate or provisioning profile in this repository.
