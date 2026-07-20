# Permission and Connection Device QA

Use this checklist on the release-candidate commit with a clean install and a
returning-user install. Record the device, iOS version, build number, tester,
and result for every run.

## Clean-install matrix

Test Calendar, Reminders, Notifications, and Location independently:

1. Confirm the LifePilot education screen appears before the Apple prompt.
2. Choose **Not Now** and confirm onboarding continues in local-only mode.
3. Relaunch and confirm the skipped choice is not represented as authorization.
4. From Settings, choose **Connect** and allow access.
5. Confirm the connection state changes without restarting LifePilot.
6. Return to Home and confirm the briefing refreshes for newly available data.
7. Repeat from a clean install and deny the prompt.
8. Confirm the feature shows a reduced-function explanation, not a dead end.
9. Choose **Open System Settings**, grant access, then return to LifePilot.
10. Confirm the state refreshes when the app becomes active.

## Required scenarios

- Calendar: full access, write-only/limited where offered, denial, revocation.
- Reminders: full access, denial, revocation, no-reminders empty state.
- Notifications: allow, deny, provisional state where available, revocation.
- Location: When In Use, denial, Precise Location off, revocation.
- Restricted controls: verify the app explains managed/parental restrictions and
  does not present them as a user denial.
- All four declined: local tasks, events, planning, export, and deletion work.
- Mixed access: failure of one integration does not hide data from another.
- Offline after authorization: local data remains available with stale status.

## Release evidence

- Attach screenshots only if they contain synthetic data.
- Record the exact `main` commit and TestFlight build number.
- File every critical/high defect as a release blocker under roadmap #52.
- Do not mark #55 device-verified until this checklist passes on a physical iPhone.
