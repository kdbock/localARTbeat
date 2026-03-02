# Legal Payment & Refund QA Checklist (Non-Technical)

Owner: Kristy Kelly  
Environment: staging first, then production  
Goal: verify payment/refund legal promises match real app behavior.

## What You Need

- A test user account.
- A payment method you can use for a small test purchase.
- Screenshot capture enabled.
- This checklist open while testing.

## Part 1: Before Purchase (Legal Clarity)

- [ ] Open the purchase/subscription screen.
- [ ] Confirm you can see pricing clearly.
- [ ] Confirm recurring billing language is visible before purchase.
- [ ] Confirm refund policy language is visible before purchase.
- [ ] Tap Terms of Service link and confirm it opens.
- [ ] Tap Privacy Policy link and confirm it opens.

Evidence:
- [ ] Screenshot of purchase screen with pricing + legal disclosure.
- [ ] Screenshot of Terms page opened from purchase flow.
- [ ] Screenshot of Privacy page opened from purchase flow.

Pass if:
- Legal language is visible before payment.
- Terms/Privacy links open correctly.

## Part 2: Purchase Flow

- [ ] Complete one test purchase.
- [ ] Confirm success message/screen appears.
- [ ] Confirm purchase state updates in app (active plan/premium status).

Evidence:
- [ ] Screenshot of successful purchase confirmation.
- [ ] Screenshot showing active plan/status in app.

Pass if:
- Payment succeeds and access/status updates correctly.

## Part 3: Cancellation / Refund Expectations

- [ ] Find cancellation path in app/settings.
- [ ] Confirm cancellation instructions are clear.
- [ ] Confirm refund language matches policy (no refunds except where required).

Evidence:
- [ ] Screenshot of cancellation path/instructions.
- [ ] Screenshot of refund policy wording in app.

Pass if:
- User can find cancellation steps.
- Refund wording is consistent and clear.

## Part 4: Duplicate-Charge Safety (Simple User Check)

- [ ] Tap purchase once and wait.
- [ ] Do not double-tap while loading.
- [ ] Confirm app does not create duplicate active plans/orders from one purchase action.

Evidence:
- [ ] Screenshot of final subscription/order state.

Pass if:
- Only one purchase result is created for one intended purchase.

## Part 5: Refund/Support Channel

- [ ] Send a test support request asking about refund/cancellation.
- [ ] Confirm support channel receives it.

Evidence:
- [ ] Screenshot of sent support request (or sent email).
- [ ] Screenshot of received support confirmation/inbox entry.

Pass if:
- Support path works and is consistent with legal text.

## Final Result

- [ ] PASS
- [ ] FAIL

Use PASS only if all parts above pass.

If FAIL:
- Failed step:
- Date/time:
- Screenshot(s):
- Follow-up fix needed:

