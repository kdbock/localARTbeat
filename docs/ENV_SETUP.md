Project Environment Setup (external-drive)

Purpose
- Document how the development environment is configured to run the app with the Android SDK and project files on an external drive.

Key facts
- Android SDK location (symlink):
  ~/Library/Android/sdk -> /Volumes/ExternalDrive/Android/sdk

- Shell profile (add to `~/.zprofile`):
  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
  export PATH="$HOME/Library/Android/sdk/emulator:$HOME/Library/Android/sdk/cmdline-tools/latest/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"

- Filesystem & mount:
  - External drive formatted: Mac OS Extended (Journaled) (HFS+) — suitable for SDK / projects.
  - Keep the external drive mounted before launching IDEs or running emulators.

- AVDs / caches:
  - AVDs are stored in the user home: `~/.android/avd` (leave here to avoid dependency on external drive availability).
  - Emulator cache and temp runtime files live  - Emulator cache and temp runtime files live  - Emulamu  - Emulatores must be installed (verify with `xcrun simctl list runtimes`).

Verification commands (examples run during setup):
- `flutter doctor --verbose`
- `sdkmanager --list`
- `avdmanager --verbose create avd -n pixel_api_33 -k "system-images;android-33;google_apis;arm64-v8a"`
- `emulator -avd pixel_api_33 -no-window`
- `xcrun simctl list runtimes`

Rollback / restore steps
- To restore SDK to internal disk or fix ownership:
  ```bash
  # restore ownership if needed
  sudo chown -R $(whoami):staff /Volumes/ExternalDrive/DevProjects
  sudo chown -R $(whoami):staff /Volumes/ExternalDrive/Android/sdk

  # if you want to move SDK back to home (example)
  rsync -aP /Volumes/ExternalDrive/Android/sdk/ "$HOME/Library/Android/sdk.backup/"
  rm -rf "$HOME/Library/Android/sdk"
  mv "$HOME/Library/Android/sdk.backup" "$HOME/Library/Android/sdk"
  ```

Notes
- Do not use exFAT/FAT for SDK or projects (they lack POSIX permissions and symlinks).
- Keep this doc updated if you change SDK location or AVD location.

