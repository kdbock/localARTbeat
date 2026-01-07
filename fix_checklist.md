# Fix Checklist (from Catlog Analysis)

## 🔴 High Priority: Firebase & Permissions
- [ ] **Fix Firebase App Check**: Initialize `AppCheckProvider` to resolve `permission-denied` errors.
- [ ] **Audit Firestore Rules**: Ensure authenticated users have access to `events`, `activities`, `art`, and `ads`.

## 🟡 Medium Priority: UI & Logic
- [ ] **Thread Safety**: Fix `setValue` calls on background threads in fragments (e.g., `MyDeviceInfoFragment`).
- [ ] **TTS Regex**: Correct the invalid character class range `\p{Letter}` in TTS replacement rules.

## 🔵 Low Priority: System & Hardware
- [ ] **Photo Picker Sync**: Investigate `IllegalStateException` in `PickerSyncController`.
- [ ] **Bluetooth Stats**: Resolve `Cannot acquire BluetoothActivityEnergyInfo` (Error 11).
- [ ] **Network Routes**: Address duplicate route errors in `netd`.
