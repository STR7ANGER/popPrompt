# PopPrompt

PopPrompt is a dual-platform tray utility with native builds for macOS and Windows. Both apps share the same product behavior: organize prompts and commands into groups, search them, expand inline content, copy in one click, and stay out of the way until opened from the menu bar or system tray.

## Repo Layout

```text
macos/
  PopPrompt.xcodeproj
  PopPrompt/
windows/
  PopPrompt.Windows.sln
  PopPrompt.Windows/
  PopPrompt.Windows.Setup/
shared/
  default-groups.json   # starter groups bundled into both apps
.github/workflows/
```

## Features

- Tray/menu bar only interaction model
- Monochrome black-and-white UI
- Prompts organized into groups: open a group to see its prompts, go back with the back button or `Esc`
- Create, rename, and delete groups
- Add, edit, copy, delete, and expand prompts, and move a prompt to another group while editing
- Search across all groups from the groups screen, or within the open group
- Ships with **Git Commands** and **Linux & Bash** starter groups
- Local persistence on both platforms
- GitHub Actions builds `.dmg` and `.msi` installers and publishes them to GitHub Releases on version tags

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

- macOS stores groups in `UserDefaults` under the `groups` key.
- Windows stores groups in `%AppData%/PopPrompt/groups.json`.

On first launch of v1.1, prompts saved by v1.0 are moved into a **My Prompts** group (the v1.0 data is left in place, so downgrading still works).

## Starter Groups

`shared/default-groups.json` is the single source for the starter groups. It is bundled as a resource on macOS and embedded in the Windows executable. The starter groups are added once, the first time v1.1 runs; deleting one won't bring it back.

To change the starter content, edit that file. It applies to new installs, and to existing installs that haven't run v1.1 yet.

## Releases

The workflow at `.github/workflows/build-artifacts.yml` builds both installers:

- **On a `v*` tag push** (e.g. `git tag v1.1.0 && git push origin v1.1.0`): builds `PopPrompt.dmg` and `PopPrompt.msi` and publishes them to a GitHub Release with auto-generated notes.
- **On manual dispatch** (Actions tab → Build Installers → Run workflow): builds both and uploads them as workflow artifacts (`PopPrompt-dmg`, `PopPrompt-msi`) without creating a release.

Plain pushes to branches do not trigger a build.

Note: the macOS app is not code-signed or notarized, so Gatekeeper will warn on first launch (right-click → Open to bypass).
