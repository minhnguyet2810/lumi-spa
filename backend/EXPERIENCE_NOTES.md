# LUMI: favorites, repeat bookings, verified reviews, reminders and admin overview

## Apply and verify

Run the provided `lumi_upgrade_experience.py` from the project root. It validates all affected files before writing, creates a backup under `.ui_backups`, and does not commit, deploy or access production data.

```sh
flutter analyze && flutter test
(cd backend && npx --yes --package=node@22 -c 'node --test tests/experience_test.js tests/permissions_test.js tests/dependency_compat_test.js tests/membership_test.js')
```

The patch uses existing dependencies; no dependency or Firestore rule changes are required. New collections are accessible only through the authenticated backend, covered by the existing default-deny client rules.

## Where to find the features

- Customer profile → **Góc riêng của bạn** / **Your LUMI space**.
- Favorites tab lists saved catalogue items, using current catalogue data. Removed/inactive items remain removable.
- Service and product detail pages have a heart and review icon. Sign in to use them. Favorite products open a detail preview; purchases continue through the existing Shop.
- Experiences tab shows your bookings and completed order products. **Book again** opens the existing booking form, with current catalogue values; you must select a new day/time and submit normally. It does not duplicate an old reservation.
- Treatment history also has **Book this treatment again**.
- **Review** is available for completed records only; the backend verifies ownership, status and target. One immutable review per booking/service or completed order/product. Review lists show anonymous LUMI customer labels, not identities or order IDs.
- Admin portal → top-right menu → **Tổng quan LUMI**. Counts use real records, refreshed on opening or manual refresh. Day boundaries use Vietnam time. Completed order value is not cash received or accounting revenue.

## Reminder operation

Reminders are OFF by default. Customer → Experiences → enable **Remind me 1 hour before**. This is an account-level server preference, separate from older device-only notification switches.

When started with `node server.js`, the backend checks each minute for confirmed/approved future appointments starting within the next hour. Keep the backend running and online. It creates an inbox notification once for each booking/start time and attempts an FCM push. The separate backend-only receipt prevents duplicates even if the customer deletes the notification or two workers run concurrently. A rescheduled start time gets a distinct receipt.

FCM delivery requires valid server credentials, a registered device token, device notification permission, and working Google/Apple messaging. Push is best-effort: if the process stops after the inbox commit, or FCM fails, the inbox notification remains but this worker does not retry the push. Reminders missed while the server is stopped are not sent after the appointment has started. App/device offline does not guarantee an immediate system alert.

For Cloud Functions hosting, `backend/index.js` exports `bookingReminders` with an every-minute schedule. This is not deployed by the installer or by starting the local server. After review, deploy the backend and scheduler with your normal Firebase deployment workflow. Scheduled functions may require billing/Cloud Scheduler configuration. Do not depend on an in-process timer in a serverless HTTP function.

## Acceptance checks on your devices

1. Log in as customer A, save a product/service. Log in as B: A's favorites and history must not appear. Return to A: favorites persist.
2. From treatment history, book again. Confirm current price and new date/time; no booking is created until submission. Inactive services show an error.
3. Pending/cancelled records must not permit a review. Mark a real test booking completed via admin; submit a review. A duplicate and another customer's submission must fail. Product reviews require a completed order containing that product.
4. Create a confirmed test appointment within 60 minutes; enable reminders; restart the backend. Check the inbox and, if device permissions/FCM are configured, push. Check again: no duplicate. Delete the notification and check again: no duplicate.
5. With reminders disabled or appointment cancelled, no reminder is generated. Receipt records are not automatically cleaned up.
6. Admin overview counts should agree with the underlying records. Customer requests to `/api/experience/dashboard` must receive 403.
7. Check new pages on a narrow Android device, light/dark modes and Vietnamese/English.

The dashboard/history/review endpoints scan the relevant records for correctness without composite-index requirements; large deployments will need pagination/aggregate counters. Customer history is account-scoped; admin aggregate scans are admin-only.

## Existing test correction

The uploaded permission test mock did not implement QuerySnapshot.forEach or transaction.set, both used by the current coupon code. Its old expectation of at least six featured coupons also conflicted with the current three configured featured codes. The patch updates the mock and verifies these three codes while retaining the checkout price/discount/stock assertions. Production coupon behavior is unchanged.

## Local validation

Dart 3.13.4 formatter and syntax parser checks completed. Node 22 isolated tests cover auth/role checks, ownership, review eligibility and duplicates, reminder opt-in/deduplication, catalogue freshness and dashboard totals. These do not validate live Firestore/FCM or replace Flutter analysis and device acceptance tests.
