# artbeat_capture_updates

---

## PART 1: DEVELOPER CHECKLIST

These are written as actionable tasks. Check them off as you go.

---

## ARCHITECTURE AND STRUCTURE

[x] Ensure no Firebase initialization happens inside artbeat_capture  
[ ] Confirm only the root main.dart initializes Firebase  
[x] Convert all artbeat_capture imports to package imports (no ../ or ./ paths)  
[x] Register all capture routes in the global router  
[x] Remove manual Navigator.push calls where named routes exist  
[x] Ensure artbeat_capture does NOT depend on profile or root app modules  
[ ] Move any service instantiations into the provider tree  
[x] Standardize folder layout inside artbeat_capture:

models / services / widgets / screens / routes / utils / theme

[ ] Ensure all capture screens use the new design system components

---

## DATA AND FUNCTIONAL INTEGRITY

[x] Replace all Firestore "as double" casts with (num?)?.toDouble() “as double” casts with (num?)?.toDouble()  
[x] Replace all Timestamp casts with safe nullable parsing  
[x] Add defaults to all model constructors  
[ ] Implement consistent async state pattern: loading / success / empty / error  
[ ] Remove restart‑the‑screen logic anywhere it appears  
[ ] Keep Firebase versions synchronized across packages  
[ ] Move platform permissions setup out of artbeat_capture and into app root

---

## USER EXPERIENCE AND ABILITY

[ ] Reduce number of steps in the capture flow  
[ ] Add visual breadcrumb / progress indicators  
[ ] Add confirmation feedback after uploads, saves, approvals, rejections  
[ ] Remove dead ends and stuck states  
[ ] Surface upload + sync progress indicators clearly  
[ ] Autosave capture metadata wherever possible  
[ ] Confirm destructive actions (delete, discard, reject)  
[ ] Respect accessibility features and text scaling

---

## PART 2: MAP EACH CHANGE TO LIKELY FILE LOCATIONS

Use this as a starting map — filenames may vary.

---

### MINI‑APP ENTRYPOINT

Look for:

artbeat_capture/lib/main.dart  
example / demo folders

Action:

Comment and label “dev only” or delete.

---

### ROUTING AND IMPORTS

Check:

artbeat_capture/lib/src/routes/  
artbeat_capture/lib/src/screens/

Look for:

./screens  
../services  
./constants

Replace with:

package:artbeat_capture/src/...

Then ensure routes exist in:

artbeat/lib/src/routing/app_router.dart  
artbeat/lib/main.dart

---

### CIRCULAR DEPENDENCY RISK

Search for:

import 'package:artbeat_profile'  
import 'package:artbeat'

If found → redesign direction.

---

### CENTRALIZING SERVICES

Search for:

new CaptureService(  
new CameraService(  
new StorageService(

Fix location:

app root provider tree (MultiProvider)

Remove widget‑local instantiation.

---

### FIRESTORE MODEL FIXES

Check:

artbeat_capture/lib/src/models/

Search:

as double  
as Timestamp

Replace:

(num?)?.toDouble()  
(Timestamp?)?.toDate()

---

### ASYNC STATE CONSISTENCY

Check screens:

artbeat_capture/lib/src/screens/

Look for patterns like:

if (snapshot.hasData) ...  
else if (...) ...  
else return Container()

Replace with standardized:

loading / loaded / empty / error states

---

### RESTART‑SCREEN FIXES

Search:

pushReplacement  
Navigator.of(context).push(...) after errors

Replace:

retry logic — do NOT restart whole screens.

---

### DESIGN SYSTEM INTEGRATION

Search screens for:

Scaffold(  
AppBar(  
ListTile(

Ensure new design system wrappers replace legacy UI.

---

## PART 3: COMMIT‑READY TODO COMMENTS

Paste these directly above problem code.

// TODO: Remove mini‑app behavior. This feature should only run inside the main app.

// TODO: Replace relative import with package import to avoid brittle routing.

// TODO: Ensure this route is registered through the global app router, not locally.

// TODO: This service should be provided at the top level via MultiProvider, not created here.

// TODO: Defensive Firestore parsing. Never assume type. Convert via num? and nullable timestamp.

// TODO: Standardize async UI states (loading / success / empty / error).

// TODO: Avoid restarting screens to solve UI problems. Retry only affected component.

// TODO: Align Firebase versions across packages before adding new features.

// TODO: Move platform permission logic to root app layer. Feature modules should not configure OS behavior.

// TODO: Replace legacy UI with design system surfaces and reusable components.

// TODO: Add feedback banner or toast so users know this saved successfully.

// TODO: Prevent dead‑end screen. Add back / cancel / retry paths.

// TODO: Add visible progress indicator for capture uploads and sync.

// TODO: Add autosave or restore logic to prevent data loss.
