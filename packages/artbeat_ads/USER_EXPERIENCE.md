# ARTbeat Ads - User Experience Guide

This guide reflects the current ARTbeat ads experience.

It does not describe the older consumable ad system.

## What ARTbeat Ads Are

ARTbeat Ads are simple monthly placements for local businesses and local creative communities.

They are designed to feel native to the app, not like a generic ad network.

Current ad types:
- `Banner Ad`
- `Inline Ad`

Current placements:
- `Community feed`
- `Artists and artwork`
- `Events`

## What Users See

### Banner Ad

Banner ads appear between sections and content groups.

Best fit:
- event discovery
- dashboard section breaks
- lighter promotional presence

### Inline Ad

Inline ads appear inside browsing and feed-style experiences.

Best fit:
- community content
- artist browsing
- artwork browsing

These are the higher-tier placements.

## Ad Creation Flow

### Step 1: Open the ad flow

Users can:
- open `Local Ads`
- choose `Submit local ad`
- or create a new ad from `My Ads`

### Step 2: Choose ad type

The user chooses:
- `Banner Ad`
- `Inline Ad`

This is the core product choice.

### Step 3: Choose placement

The user chooses where the ad should appear:
- `Community feed`
- `Artists and artwork`
- `Events`

Not every placement is available for every ad type.

### Step 4: Add content

The user fills in:
- title
- description
- contact info
- website
- 1 to 4 images

### Step 5: Pay through the store

When the user taps submit:
- ARTbeat validates the form
- images upload first
- store checkout opens
- the user pays for the monthly subscription product

Current subscription products:
- `artbeat_ad_banner_monthly`
- `artbeat_ad_inline_monthly`

### Step 6: Review state

After successful purchase:
- the ad is created in ARTbeat
- its status is `Pending review`
- it is not visible in the live app yet

### Step 7: Admin review

An admin can:
- approve and publish
- reject

If approved:
- the ad appears in the selected placement

If rejected:
- it remains out of rotation

## What `My Ads` Means

### Pending review

This means:
- the ad was submitted successfully
- payment was completed
- the ad is waiting for approval
- the ad is not yet visible to other users

### Active

This means:
- the ad was approved
- it is currently in rotation
- it is visible in its assigned placement

### Expired / Rejected / Deleted

These mean:
- the ad is no longer in live rotation

## Current Business Logic

The product is intentionally simple.

- ads are monthly
- ads are paid before review
- ads are not instantly published
- businesses choose one ad tier at a time in the current subscription setup

On Apple, the current subscription group design means a business chooses:
- `Inline Ads Monthly`
or
- `Banner Ads Monthly`

not both simultaneously

That is an intentional simplification for launch.

## What This Guide No Longer Covers

The current ARTbeat ads experience does not use:
- 1-week ad purchases
- 3-month ad purchases
- six consumable ad SKUs
- customer-facing ad analytics as the product story
- complicated zone/campaign strategy language

Those belonged to the older design and should not be treated as current behavior.

## Support / Troubleshooting

If an ad does not appear immediately after purchase:
- check `My Ads`
- look for `Pending review`

If store checkout does not open:
- verify the product exists in App Store Connect or Google Play Console
- verify the product IDs match the app exactly
- verify the product is available in the test environment

If the ad is approved but still not visible:
- confirm the ad was assigned to a live placement
- confirm it is not expired
- confirm the user is browsing the matching surface
