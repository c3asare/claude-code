# Competitive research (2026-10-12)

Caveat: agents had web search only. Store pages and city data portals were unreachable (DNS/proxy), so ratings, current prices, and dataset schemas are **unverified**.

## 1. "Where did I park" apps
- Apple Maps (iOS, free): auto-saves via car Bluetooth/CarPlay. Fails with no Bluetooth, after re-pairing, or when a friend's car pairs.
- Google Maps (free): manual on Android; iOS auto-save via USB/BT/CarPlay, expires ~48 h. Android auto-save claims conflict.
- SpotAngels (free + Plus): Bluetooth auto-detect, sweeping alerts, crowdsourced rules. Closest competitor.
- Parkify (Android): named/colored multiple cars, BT + motion fallback, IAP $0.99-5.99 (2022).
- Parking Pin (iOS, $0.99): motion auto-pin; last updated 2019, likely abandoned.
- Misc iOS lookalikes with weekly/annual subs ($2.99/wk, $29.49/yr).
- Complaints (anecdotal): Bluetooth dependence, wrong location, battery, abandoned apps, weekly subs.
- Gaps: detection without Bluetooth (rentals, rideshare, older cars), proper multi-car, battery-friendly OS activity APIs.

## 2. Street-cleaning apps (LA)
- LA moved to **biweekly** sweeping March 2021; signs still read weekly. Fine about $73; most common LA ticket. ~12.5k "phantom" tickets reported since 2021 (Hoodline, treat cautiously).
- StreetsLA: email alerts 24/48 h ahead for registered addresses; no location awareness.
- Sweep LA (sweep.la, web, .ics feed), SweepSpotter (iOS/Android), Street Cleaning Reminder (Android), Curbswap (valet), SpotAngels (alerts reportedly in paid tier).
- Gaps: "is it THIS week?" certainty, free core alerts, auto-located, multi-car, ticket-dispute evidence (timestamped photos).

## 3. Monetization
- Recommend freemium subscription, no ads v1. Free: 1 car, current-spot alerts. Paid (~$19.99/yr or $2.99/mo, estimate): multi-car, auto-detect, multiple lead times, sharing, ticket log.
- Comparables: SpotAngels Plus $29.99/yr (2021 figure). Freemium conversion ~2-5%. Store fee 15% small-business tier (verify current terms).
- 10k MAU at 3-5% paying, ~$20/yr: ~$5-8.5k/yr net. Side-income scale unless more cities or a higher tier. Ads: ~$1-4k/yr. All estimates.
- Risk: free municipal alerts cap pricing on alerts alone; gate multi-car and auto-detect instead.

## 4. LA sweeping data
- Socrata "Posted Street Sweeping Routes" `krk7-ayq2` on data.lacity.org, CC0, last modified 2020, probably tabular.
- ArcGIS `Biweekly_Routes_2021` FeatureServer (services1.arcgis.com/PTh9WC0Sf2WS7AAq), posted routes as of Aug 2023; likely geometry source. Layer index, fields, license unverified.
- Excludes non-posted routes (DTLA etc.). Show a "check the posted sign" disclaimer.
- Long Beach: no open layer found (DataLB is Esri-based); may need Public Records Act request.
- Architecture: bundled snapshot + server cache (weekly, ETag) + on-device lookup. Do not send user locations to live APIs.
- Next: run the metadata calls from an unrestricted network, check DataLB, confirm licenses.
