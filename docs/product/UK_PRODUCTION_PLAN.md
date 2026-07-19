# LifePilot UK Production Plan

**Date:** 2026-07-19  
**Scope:** production-ready, privacy-first iOS daily planner for UK users  
**Positioning:** a calm, local-first view of the day: tasks, calendar, realistic capacity, commute buffers, and optional weather context.

This plan is product guidance, not legal advice.

## Evidence that changes the product

| Evidence | Product implication |
|---|---|
| iPhone represented 55% of UK smartphone users in a CMA-commissioned 2025 survey, with stronger use among ages 16–34. | iOS-first remains reasonable; keep domain/services portable for later Android. |
| UK adults spent 77% of online time on smartphones and used 41 smartphone apps per month on average (Ofcom, 2025). | LifePilot must earn daily use through five-second capture, a useful first viewport, and widgets—not feature density. |
| 28% of working adults in Great Britain hybrid-worked in Jan–Mar 2025 (ONS). | Support office/home/other patterns and variable travel buffers; do not assume five office days. |
| One quarter of UK workers said work negatively affected mental health; excessive workload correlated strongly with harm (CIPD, 2025). | Use capacity language, breaks, and guilt-free deferral. Never frame the user as “unproductive.” |
| UK weather warnings can disrupt travel and daily plans. | Show actionable weather context (“rain during commute”), not a full weather dashboard. Offer a manual town/postcode alternative before production launch. |
| Caution was the most common UK feeling about personal-data privacy (ICO 2025 attitudes survey). | Prove local-first behaviour in the UI. Make location, cloud sync, analytics, and any future AI separately controllable. |

## Product north star

> A calm layer of foresight over the user’s day.

LifePilot should answer, in order:

1. What matters now?
2. What should I prepare for?
3. What needs my decision?
4. What can safely wait?

Depth and animation communicate hierarchy. They are not decoration:

- atmosphere: restrained navy / violet ambient light;
- readable content: mostly opaque elevated surfaces;
- floating context: selective glass;
- decisions: highest elevation, exact before/after detail;
- system recovery: clear banners with specific actions.

## Page architecture

### Home

- Editorial briefing rather than a four-tile dashboard.
- Date, greeting, one orientation sentence.
- Compact context ribbon: weather, source freshness, optional leave-by.
- One primary preparation card.
- Maximum three priorities before “See all”.
- Next timeline transition.
- Pending approval indicator when needed.

### Timeline

- Sticky date context.
- All / Calendar / Travel / Tasks filters.
- Semantic node shapes plus colour.
- Current-time marker and travel-buffer bridge.
- Large Dynamic Type falls back to stacked rows.

### Tasks

- Quiet list hierarchy with tokenised filter chips.
- One fast Inbox capture field.
- Visible due / priority / recurrence badges.
- Recurrence actions must not exist only in hidden menus.

### Approvals

- Exact action, destination, evidence, freshness, and execution state.
- Approve only after exact proposal review.
- Distinguish approved from executed.
- History is a calm audit ledger.

### Insights and Memory

- Evidence-led reflection, never a productivity score.
- Memory is an inspectable rulebook: pinned, preferences, routines, places, corrections.
- Every inferred item remains proposed until confirmed.

### Settings

- Identity/local-first summary.
- Briefing and quiet hours.
- Connections with meaningful state and last refresh.
- Privacy and sensitive previews.
- Optional sync, appearance/accessibility, export/delete.
- In-app privacy notice and data-flow summary.

## UK privacy and App Store gate

Before App Store submission:

- publish a privacy policy accessible in-app and in App Store Connect;
- document lawful bases and retention for each processing purpose;
- complete a DPIA if processing is likely high-risk or the service is child-accessible;
- assess ICO registration/data-protection fee;
- declare all off-device collection and third-party SDK behaviour in App Privacy;
- keep local-only use fully functional without account, location, calendar, or cloud sync;
- provide a location alternative (manual town/postcode) before claiming full weather support;
- ensure permission purpose strings describe the exact benefit;
- review PECR implications before adding analytics, SDK storage, or tracking;
- avoid analytics/advertising SDKs in the MVP;
- preserve export and delete controls in Settings.

## Accessibility release gate

- VoiceOver completes onboarding, capture, task completion, proposal review, export/delete.
- Dynamic Type tested through accessibility sizes; horizontal action rows stack.
- Reduce Motion removes continuous animation.
- Reduce Transparency provides opaque surfaces with visible borders.
- Increase Contrast preserves hierarchy without glow.
- Status never depends on colour alone.
- Minimum 44×44pt interactive targets.
- App Store accessibility claims are made only after device verification.

## Production definition of done

### In repository

- consistent premium components and token usage across every primary page;
- no fake metrics or prohibited actions in previews/demo;
- loading, empty, denied, stale, and offline states;
- deterministic tests and green macOS CI;
- privacy/release documentation matching shipped behaviour.

### Requires Apple hardware/accounts

- real-device permission and background-task verification;
- Widget Extension embedding and App Group decision;
- signing, entitlements, privacy manifest validation;
- screenshots from the actual build;
- TestFlight accessibility and usability pass;
- App Store Connect metadata, privacy labels, age rating, support and privacy URLs.

## Sources

- [CMA Mobile Consumer Survey (July 2025)](https://assets.publishing.service.gov.uk/media/687fb0c037c38e28f38468d4/Consumer_survey_report1.pdf)
- [Ofcom Online Nation 2025](https://www.ofcom.org.uk/media-use-and-attitudes/online-habits/from-apps-to-ai-search-how-the-uk-goes-online-in-2025)
- [ONS: hybrid working in Great Britain (11 June 2025)](https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/articles/whohasaccesstohybridworkingreatbritain/2025-06-11)
- [CIPD Good Work Index 2025](https://www.cipd.org/en/knowledge/reports/goodwork/)
- [ICO Public Attitudes 2025](https://ico.org.uk/media2/veapck3h/ico-pair-2025-report.pdf)
- [ICO storage/access technology guidance (updated 29 April 2026)](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/)
- [GOV.UK Data (Use and Access) Act commencement](https://www.gov.uk/guidance/data-use-and-access-act-2025-plans-for-commencement)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [EHRC guidance for businesses](https://www.equalityhumanrights.com/guidance/business/guidance-businesses)
