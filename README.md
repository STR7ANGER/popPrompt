# PopPrompt

PopPrompt is a native macOS menu bar app built with SwiftUI for storing, searching, and copying reusable prompts.

## Features

- Menu bar utility with a compact popover-style window
- Create, browse, search, copy, and delete prompts
- Local persistence with `UserDefaults`
- GitHub Actions workflow that builds a macOS app bundle and packages a `.dmg` artifact on pushes to `main`

## Project Structure

```text
PopPrompt/
├── Models/
├── ViewModels/
├── Views/
├── Utils/
└── Assets.xcassets/
```

## Run Locally

1. Open `PopPrompt.xcodeproj` in Xcode.
2. Choose the `PopPrompt` scheme.
3. Press `Cmd + R`.

## Build Artifact Automation

On every push to `main`, GitHub Actions builds the app on a macOS runner and uploads a `.dmg` artifact from the workflow run.
