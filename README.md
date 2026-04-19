# PopPrompt

PopPrompt is now a dual-platform tray utility with native builds for macOS and Windows. Both apps share the same product behavior: save prompts, search them, expand inline content, copy in one click, and stay out of the way until opened from the menu bar or system tray.

## Repo Layout

```text
macos/
  PopPrompt.xcodeproj
  PopPrompt/
windows/
  PopPrompt.Windows.sln
  PopPrompt.Windows/
  PopPrompt.Windows.Setup/
.github/workflows/
```

## Features

- Tray/menu bar only interaction model
- Monochrome black-and-white UI
- Add, search, copy, delete, and expand prompts
- Local persistence on both platforms
- GitHub Actions builds both `.dmg` and `.msi` installers on push

## Run Locally

### macOS

1. Open `macos/PopPrompt.xcodeproj` in Xcode.
2. Choose the `PopPrompt` scheme.
3. Press `Cmd + R`.

### Windows

1. Open `windows/PopPrompt.Windows.sln` in Visual Studio 2022 or newer.
2. Set `PopPrompt.Windows` as the startup project.
3. Build and run in `Release` or `Debug`.

## Persistence

- macOS stores prompts in `UserDefaults`.
- Windows stores prompts in `%AppData%/PopPrompt/prompts.json`.

## Build Artifact Automation

The workflow at `.github/workflows/build-artifacts.yml` runs on every push and publishes:

- `PopPrompt-dmg`
- `PopPrompt-msi`
