# RoundTimer — Market Research Summary

Research conducted 2026-04-07. This doc captures the WHY behind product decisions so future agents don't re-question validated choices.

## Why an Interval Timer?

We evaluated 10+ app categories. The interval timer won because:

1. **Proven revenue:** Seconds (market leader) earns ~$43K/month at $7.99 with ~106K downloads/month
2. **Daily use:** Athletes train 3-6x/week, using a timer every session — high retention
3. **Clear feature gap:** No app combines Live Activity + Watch haptics + one-time purchase
4. **No backend needed:** Pure client-side app, zero ongoing costs
5. **Growing market:** HIIT market at $8.9B (2025), 10% CAGR

## Competitive Landscape

| App | Price | Live Activity | Watch Standalone | Weakness |
|-----|-------|--------------|-----------------|----------|
| **Seconds** | $7.99 once | NO | Limited | No Live Activity, aging UI, Watch app rebuilt and limited |
| **Intervals Pro** | $70 lifetime / sub | NO | Yes (best) | Expensive, subscription model angers users |
| **Arc Timer** | Free | Yes | Claims yes | Brand new, no ratings, unclear monetization |
| **Box Timer** | Free | No | No | CrossFit-only, limited |
| **Bit Timer** | $1.99 | No | No | Too basic |

**Key finding:** Seconds dominates but hasn't adopted Live Activities. Intervals Pro has the best Watch app but charges $70. Nobody occupies the "premium but affordable" middle ground.

## What Athletes Actually Complain About

From Reddit (r/HIIT, r/crossfit, r/boxing, r/running) and App Store reviews:

1. **Ads interrupting workouts** — political ads, full-screen interstitials mid-set
2. **Timer sounds kill Spotify** — audio session category mismanagement (most apps use `.playback` which steals audio focus; correct is `.ambient` + `.mixWithOthers`)
3. **Timer stops when screen locks** — need Live Activity to solve this
4. **Can't see timer from across the room** — small text, low contrast
5. **Subscription fatigue** — "I just want to pay once for a timer"
6. **No haptic-only mode** — for quiet gyms, yoga studios
7. **Overly complex setup** — too many taps to start a simple work/rest timer

## Ideas We Rejected (and Why)

| Idea | Why Rejected |
|------|-------------|
| **Clipboard history** | iOS blocks background clipboard access. Paste permission prompt is infuriating. Apple added native clipboard history to macOS — iOS likely next. |
| **Parking timer** | A competitor ("Parking Spot") already shipped Live Activity version (March 2025). ParkMobile covers paid meters. Physical meters declining. Google could add iOS parking timer anytime. |
| **Countdown widget** | Saturated category with strong free options. Low-frequency use (set and forget). Subscription fatigue is real but the counter-positioning alone isn't enough. |
| **QR + NFC utility** | Use-once-then-forget. No retention. Apple Shortcuts generates QR codes for free. Commodity utility. |
| **Sound level meter** | NIOSH SLM is free and government-validated. Apple could bring Watch Noise app to iPhone. Per-device calibration is hard. |
| **Photo date stamper** | Stuck between free utility apps and premium retro camera apps. Neither fish nor fowl. |
| **Baby kick counter** | Viable niche but more work (Watch app mandatory, HealthKit, session history). Better at $2.99-3.99. Good backup idea if timer doesn't work out. |

## Pricing Decision

$4.99 one-time purchase because:
- Undercuts Seconds ($7.99) — clear value comparison
- Massively undercuts Intervals Pro ($70)
- Apple Small Business Program: 15% commission = $4.24 net per sale
- "No subscription" is the marketing message, not just a pricing choice
- At 1,500 downloads/month = ~$6,360/month revenue

## Revenue Math

```
Conservative:  500 downloads/month × $4.24 net = $2,120/month
Moderate:    1,500 downloads/month × $4.24 net = $6,360/month
Optimistic:  5,000 downloads/month × $4.24 net = $21,200/month

Seconds benchmark: ~106K downloads/month (mostly free), ~$43K/month revenue
Capturing 1-2% of Seconds' audience = 1,000-2,000 paid downloads/month
```

## App Store Strategy

**Discovery risks:**
- "Interval timer" search results dominated by Seconds and Intervals Pro
- Paid apps get fewer downloads than free alternatives by default
- Need strong ASO (keywords, screenshots, description) and possibly a ProductHunt launch

**Mitigation:**
- Target long-tail keywords: "boxing round timer", "tabata timer no ads", "HIIT timer no subscription"
- Screenshots emphasizing Live Activity (visual differentiator in search results)
- App Store description leading with "No ads. No subscription. Pay once."
- Consider reaching out to fitness YouTubers/bloggers for reviews
