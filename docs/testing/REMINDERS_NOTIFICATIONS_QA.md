# Reminders and Notifications Device QA

Run this checklist on a real iPhone before release. The automated suite uses deterministic adapters; EventKit and notification delivery still require device validation.

## Apple Reminders

1. In Settings > Connections, grant Reminders access.
2. Add an open reminder in Apple Reminders, launch LifePilot, and confirm it appears once on Home after repeated refreshes and relaunches.
3. In Quick Capture, choose Apple Reminder, review the parsed title/date/recurrence, save, then approve it in Settings > Pending Approvals.
4. Confirm the new item appears in Apple Reminders with the selected due date and recurrence and that the approval result includes an EventKit identifier.
5. Revoke Reminders permission in iOS Settings. Confirm LifePilot keeps local tasks usable and shows a reconnect message instead of crashing.
6. Restore permission and repeat the approved write.

## Local Notifications

1. Grant Notifications access and create a LifePilot task due at least two minutes in the future.
2. Lock the device and confirm one notification arrives.
3. Edit or snooze the task and confirm the old delivery time is replaced, not duplicated.
4. Complete or delete the task and confirm no obsolete notification is delivered.
5. Relaunch LifePilot before delivery and confirm the task remains scheduled.
6. Set quiet hours across midnight and schedule a task inside them. Confirm delivery moves to the quiet-hours end.
7. With sensitive previews off, confirm lock-screen text does not contain the task title. Opt in and confirm the title is then shown.
8. Revoke Notifications permission and confirm task editing/completion still works without an error loop.

Record the iOS version, device model, permission state, and screenshots for any failure.
