Local ARTbeat UI Design Guide (v1)
0) Brand + vibe

Local ARTbeat should feel like:

“quest / exploration” + “creative community”

premium, slightly futuristic, but warm and human

not flat Material default, not neon gamer UI, not corporate

Core motif: Dark world background + glass surfaces + gradient accents + bold type.

1) Color system
Base surfaces

World background: #07060F (nearly-black purple)

Surface glass: white at 4–10% opacity over dark

Dividers/borders on glass: white at 10–18% opacity

Text on dark: white at 92% (primary), 70% (secondary), 45% (tertiary)

Accent palette (use consistently)

Teal (primary accent): #22D3EE

Green (success/positive): #34D399

Purple (brand power): #7C4DFF

Pink (energy/highlight): #FF3D8D

Yellow (reward/attention): #FFC857

Red (danger): keep standard red but don’t overuse

Gradients

Use gradients as accents, not full-screen wash (except “world background” blobs):

Primary button / badge gradient:

#7C4DFF → #22D3EE → #34D399 (top-left to bottom-right)

“World” background gradient base:

#07060F → #0A1330 → #071C18 (top-left to bottom-right)

Blob glows: use the accent colors at low alpha.

2) Typography

Use one strong font family for branded UI:

GoogleFonts.spaceGrotesk (preferred)

Weights:

900/800 for titles and key labels

700 for buttons, section labels

500/600 for body

Sizing rules:

Screen title: 18–22, weight 900

Section label: 12–13, weight 800–900, letterSpacing 0.3–0.8

Body: 13–15, weight 600–700

Helper text: 12–13, weight 600, alpha ~0.6–0.7

Avoid thin weights. Avoid default Roboto look.

3) Layout rules
Spacing

Outer padding: 14–18

Card padding: 14–18

Vertical rhythm: multiples of 8

Corners

Primary surfaces/cards: 24–28 radius

Small chips/buttons: 16–20 radius

Icon buttons: circle or 20–24 radius

Shadows

Keep subtle + soft:

Big card shadow: black at 40–50% alpha, blur 24–34, y offset 14–18

Accent glow shadow: teal/purple at 8–14% alpha, blur 28–40

4) Core components (must reuse)
4.1 World Background

Use a stack background pattern:

Solid/gradient base fill (dark)

3–5 blurred “blob” lights (teal/purple/pink/yellow/green) animated slowly (optional)

Optional: faint rings/arcs (very low alpha)

Vignette (radial gradient darkening edges) at ~0.65–0.78 alpha

Rules:

Blobs should never block content readability.

Blobs are decorative and low alpha.

4.2 Glass Card / Panel

A “glass” container should:

be clipped (ClipRRect)

use BackdropFilter blur(16–20)

have fill: white 6–10% alpha

border: white 10–14% alpha

optional: subtle accent glow shadow

4.3 Top HUD Bar

Instead of standard AppBar (when possible):

SafeArea + Row

Left: menu/back icon

Center: title

Right: search/profile icon

All icons white, title white

Use glass strip behind it only if needed for readability.

4.4 Buttons

Primary CTA:

Glass or gradient filled

48–52 height

Radius 22–26

Text weight 800–900

Optional small icon

Secondary:

Glass outline (white 14% border)

Fill white 6% alpha

Same height, slightly calmer

Destructive:

Red icon + red text, minimal gradient

4.5 Inputs

On dark:

Use glass input container

Label in white 70%

Cursor teal

Icons teal/white70

Avoid default TextField underline

5) Screen composition templates
5.1 “Auth” screens (login/register/forgot/verify)

Background: world + vignette

Center: constrained width 420–520

Main content in glass card

Top: badge icon (gradient square/circle)

Title + subtitle

Form fields

Primary CTA

Secondary actions as outlined or text buttons

5.2 “Dashboard” screens

Background can be lighter OR still world, but keep branding consistent.

Use cards with strong visual hierarchy:

hero card

stats row (2 cards)

horizontal carousels

fewer words, more “modules”

5.3 “Map” screens

Critical rule:

Do not paint or darken over the map tiles.

No full-screen overlay above the map other than HUD elements positioned around edges.

Allowed:

Top HUD bar

Floating search field

Floating buttons

Bottom tray

If readability needs help, put glass panels behind the controls only.

6) Drawer design (Local ARTbeat standard)

Drawer should match the dark/glass theme:

Background: very dark #07060F (or near)

Content sits on glass sections

Header:

user avatar (glow ring optional)

display name + email

small role/feature badge chip

Section headers:

uppercase, small (12), white 55%

Items:

“pill row” style instead of default ListTile:

glass row with icon chip + label

selected state: teal accent + slightly brighter fill

Dividers:

use hairline with white 10% alpha or spacing blocks (prefer spacing)

Sign out:

red accent, last item

Navigation behavior:

close drawer, delay 200–250ms, then navigate

use pushReplacement only for truly top-level routes

7) Motion / animation (subtle)

Use slow looping background motion (9–12s)

Fade/slide intro for HUD elements (300–800ms)

Avoid bouncy overscroll everywhere

Keep animations optional: don’t block UI

8) Accessibility / readability rules

Ensure contrast: text on glass must be readable against blobs

Keep important text at white 85–95% alpha

Don’t use tiny fonts below 11 except badges

Touch targets ≥ 44px

9) Implementation rules (so it stays consistent across 300 screens)
Must-do:

Create shared widgets once and reuse:

AuthWorldBackground

GlassCard

GradientBadge

HudTopBar

HudButton

GlassInputDecoration

DrawerSection, DrawerItemPill

Must-not-do:

Don’t create one-off gradients per screen.

Don’t mix bright white pages with dark world pages randomly.

Don’t use default ListTile + white drawer.

Don’t overlay a dark tint over Google Maps tiles.

“Definition of done” for a redesigned screen:

Uses world background OR uses the new card language on light background intentionally

Typography updated to Space Grotesk hierarchy

Primary CTA uses gradient/teal accent rules

Cards are glass or consistent soft cards

No default Material “basic” look

10) Quick checklist per screen (fast QA)

 Background matches Local ARTbeat (world+glass or intentional light variant)

 One clear primary CTA (gradient)

 Space Grotesk used for titles/buttons

 Cards have 24–28 radius and soft shadows

 Icons match accent palette (teal/green/purple)

 Navigation patterns consistent (drawer delay, root nav rules)

 No unreadable text over blobs

 Map screens: no full overlay on tiles