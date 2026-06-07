# Health Connect declaration resubmission — Vitals signals

**Status:** pending submission (user-triggered) · created 2026-06-07

The **Vitals** feature reads four overnight bio-signals that were dropped on
2026-05-07 for Google Play "Minimum Scope" compliance (they surfaced nowhere at
the time). The Vitals screen is now the user-facing surface that re-justifies
them. iOS reads them immediately via HealthKit (no per-type review gate). On
Android, re-declaring the permissions requires updating the Play **Health
Connect declaration** and passing review again.

## Why this should pass now
Last rejection reason was *"Excessive data access for declared feature"* — the
types weren't shown anywhere. Each re-declared type now maps 1:1 to a labeled
signal on the Vitals screen, which is exactly what the policy requires.

## Types being re-declared
| Manifest permission | Vitals signal | HealthKit (iOS) |
|---|---|---|
| `READ_HEART_RATE_VARIABILITY` | HRV | `heartRateVariabilitySDNN` |
| `READ_RESPIRATORY_RATE` | Respiratory rate | `respiratoryRate` |
| `READ_OXYGEN_SATURATION` | Blood oxygen | `oxygenSaturation` (`BLOOD_OXYGEN`) |
| `READ_BODY_TEMPERATURE` | Skin temperature | `bodyTemperature` |

## Pre-submission checklist
- [ ] Vitals screen is live in the build (screenshots of each signal + its baseline band).
- [ ] Each permission's in-app rationale string references the Vitals signal it powers.
- [ ] Privacy policy updated to list HRV / respiratory rate / SpO₂ / body temperature as collected, with purpose ("show overnight vitals vs your baseline") and retention.
- [ ] Play Console → Health Connect declaration form updated with the four types + the same purpose text.
- [ ] Demo video (if requested) shows the Vitals screen displaying the signals.

## After approval
1. Flip `kVitalsAndroidEnabled = false → true` in
   `mobile/flutter/lib/data/services/health_service.dart`.
2. Rebuild + ship the Android release. Vitals then reads all signals the user's
   wearable provides on Android too (iOS already does).

Until then the manifest declares intent but `_getAvailableTypes` issues **no
query** for these types on Android, so shipping the manifest early is safe.
