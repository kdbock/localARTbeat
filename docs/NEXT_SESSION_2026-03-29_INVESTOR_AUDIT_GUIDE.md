# Next Session: March 29, 2026

## Purpose

This session is about improving the investor-audit posture of the app, not just
cleaning code for its own sake.

The main investor lenses in play are:
- execution confidence
- risk reduction
- scalability / team-readiness
- defensibility
- marketability

The biggest technical goal so far has been to move the repo from
"interesting but structurally risky" toward "credible, governable, and easier
to defend in diligence."

## Where We Are Now

The repo is materially stronger than it was at the start of the audit effort.

Estimated overall improvement:
- about `40%` better overall in engineering quality and investor-defensibility
  signal versus the original audit baseline

High-level current read:
- execution confidence has improved substantially
- payment / release risk has been reduced substantially
- root architecture is much cleaner than before
- CI is now enforcing more of the release contract
- defensibility is still the weakest investor lens because the moat layer is
  still underbuilt

## What Has Been Done

### 1. Package UI / Provider Boundary Cleanup

Completed for the screens/widgets UI/provider-boundary pass:
- `artbeat_admin`
- `artbeat_core`
- `artbeat_artist`
- `artbeat_artwork`
- `artbeat_events`
- `artbeat_profile`

Mostly complete:
- `artbeat_art_walk`

What that means:
- major UI surfaces no longer construct service objects locally
- provider ownership is clearer
- direct Firebase singleton access was reduced or removed from many guarded UI
  surfaces
- architecture guard scripts were added and used to hold those boundaries

### 2. Hardening Sprint

Completed:
- explicit env/config contract
- stricter release-critical config behavior
- Stripe config cleanup
- endpoint targeting cleanup
- purchase verification boundary audit
- backend-owned IAP activation and cancellation paths
- stronger monetization verification boundaries
- release payment config gate
- release monetization prerequisites gate
- CI enforcement of release hardening gates

What that means:
- release safety is no longer based on loose defaults
- monetization paths are much easier to defend in diligence
- CI now checks important release assumptions instead of trusting humans to
  remember them

### 3. Root Architecture / Execution Confidence Work

Completed:
- provider root split from one giant file into grouped provider modules
- bootstrap extraction out of `main.dart`
- router Firebase-decoupling pass
- router split by domain into dedicated handlers
- protected-route policy extraction
- specialized route dispatch extraction
- removal of the legacy root route handler
- first provider-overlap consolidation pass

What that means:
- root ownership is easier to understand
- startup policy is more inspectable
- routing is less fragile than before
- the app looks more maintainable to outside reviewers

### 4. CI / Release Workflow Cleanup

Completed:
- `Release Hardening Gates` job added and enforced in CI
- branch protection now blocks direct pushes to `main`
- several CI issues were fixed in PR work:
  - missing placeholder `.env` asset in multiple jobs
  - stale generated test mock in `artbeat_capture`
  - root auth test harness provider drift
  - integration-test workflow setup drift
  - package dependency inventory drift
  - explicit Android emulator selection for integration tests
  - integration job now detects integration test paths and skips cleanly when
    none are present

What that means:
- the repo is moving toward a real PR-and-checks workflow
- release discipline is becoming operational instead of aspirational

## What Is Left To Do

### 1. Finish The Current PR Cleanly

Status:
- PR `#1` is merged to `main`
- latest `main` runs for `Flutter Tests` and `Comprehensive Test Suite` are
  green

Why it matters:
- this locks in the protected-branch workflow and CI hardening on `main`

### 2. Continue Provider-Overlap Cleanup Carefully

Still open:
- remaining overlap pairs at the app root
- clarifying where similar services have distinct responsibilities versus
  accidental duplication

Why it matters:
- root composition is much better, but still not fully minimal or fully obvious

### 3. Build The Actual Defensibility Layer

This is the largest remaining investor gap.

Still needed:
- moat hypothesis written clearly
- creator reputation / quality signals
- recommendation and ranking inputs
- sponsor ROI and ad yield intelligence
- monetization-quality dashboards
- telemetry that compounds into proprietary advantage

Why it matters:
- the codebase is more trustworthy now, but trustworthiness is not the same as
  a moat

### 4. Improve Marketability Proof

Still needed:
- better funnel telemetry
- investor-facing KPI reporting
- tighter visibility into monetization performance, retention, and activation

Why it matters:
- investors want evidence of traction quality, not just a broad feature set

## What Not To Do By Default

Do not:
- reopen the broad package sweep by default
- restart large router cleanup unless a concrete issue appears
- do random feature expansion without tying it to an audit objective

The repo is past the point where broad cleanup gives the best return.

## Recommended Next Focus

Default next phase:
1. keep `main` green under the new CI and branch-protection rules
2. keep root provider-overlap cleanup moving in small, explicit passes
3. shift the next major sprint toward defensibility and marketability
   instrumentation, not more broad structural cleanup

Best next strategic work:
- define the moat hypothesis in writing
- add telemetry that supports reputation, ranking, and monetization intelligence
- create one investor-facing KPI / monetization health view

## Short Status Summary For Tomorrow's Chat

We spent this phase improving the investor-audit posture of the app by
reducing architecture risk, hardening release and payment behavior, cleaning up
root composition, and turning release assumptions into CI-enforced checks. The
repo is substantially more credible now, but the biggest remaining gap is still
defensibility: the app collects and routes a lot of activity, but it still
needs stronger proprietary data loops, recommendation signals, creator quality
metrics, and investor-facing KPI reporting.

## One-Paragraph Restart Prompt

We are no longer in broad cleanup mode. The hardening sprint and major root
architecture cleanup are largely complete, and the next job is to finish
landing the current CI/PR work and then move toward the real investor-gap work:
defensibility, telemetry, reputation signals, ranking inputs, sponsor/ad ROI
measurement, and clearer KPI evidence.
