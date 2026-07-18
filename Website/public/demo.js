/**
 * LifePilot interactive web demo.
 * Mock data mirrors GhostBrain/MockRecommendationProvider.swift on develop.
 */

const ONBOARDING_STEPS = [
  {
    id: "welcome",
    icon: "✨",
    title: "Meet LifePilot",
    message:
      "An AI operating system that prepares your day before you ask — not another app to check.",
  },
  {
    id: "calendar",
    icon: "📅",
    title: "Connect your calendar",
    message:
      "LifePilot reads your schedule to build your Morning Briefing and catch conflicts before they happen.",
  },
  {
    id: "approvals",
    icon: "🛡️",
    title: "You're always in control",
    message:
      "LifePilot prepares recommendations — nothing changes your calendar or reminders without your explicit approval.",
  },
  {
    id: "ready",
    icon: "➡️",
    title: "You're ready",
    message: "Your Morning Briefing is waiting.",
  },
];

const AGENT_ICONS = {
  calendar: "📅",
  task: "✅",
  travel: "✈️",
  weather: "🌤️",
  memory: "🧠",
  reminder: "🔔",
  planning: "💡",
  security: "🛡️",
};

const AGENT_LABELS = {
  calendar: "Calendar",
  task: "Tasks",
  travel: "Travel",
  weather: "Weather",
  memory: "Memory",
  reminder: "Reminder",
  planning: "Planning",
  security: "Security",
};

const TABS = [
  { id: "home", label: "Home", icon: "🏠" },
  { id: "timeline", label: "Timeline", icon: "📋" },
  { id: "memory", label: "Memory", icon: "🧠" },
  { id: "insights", label: "Insights", icon: "📈" },
  { id: "settings", label: "Settings", icon: "⚙️" },
];

const state = {
  phase: "splash",
  onboardingIndex: 0,
  tab: "home",
  dismissedRecommendations: new Set(),
  toastMessage: "",
};

function greetingContext(now = new Date()) {
  const hour = now.getHours();
  let timeOfDay = "evening";
  if (hour < 12) timeOfDay = "morning";
  else if (hour < 17) timeOfDay = "afternoon";

  const words = { morning: "Good morning", afternoon: "Good afternoon", evening: "Good evening" };
  return {
    greeting: `${words[timeOfDay]}, Alex`,
    dateText: now.toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" }),
  };
}

function atTime(now, hour, minute) {
  const d = new Date(now);
  d.setHours(hour, minute, 0, 0);
  return d;
}

function formatTime(date) {
  return date.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
}

function mockModel(now = new Date()) {
  return {
    recommendations: [
      {
        id: "rec-1",
        title: "Leave 15 minutes early for your 10:00 AM",
        reasoning:
          "Traffic on your usual route is heavier than normal — Maps estimates 22 minutes instead of the usual 12.",
        sourceAgent: "travel",
        riskLevel: "low",
      },
      {
        id: "rec-2",
        title: "Block 45 minutes for the board deck",
        reasoning:
          "High-priority task is due this afternoon and you still have an open focus window after lunch.",
        sourceAgent: "task",
        riskLevel: "low",
      },
      {
        id: "rec-3",
        title: "Reschedule your 2:00 PM — it conflicts with pickup",
        reasoning:
          "Your calendar shows a 2:00 PM sync overlapping with the recurring 'School Pickup' block.",
        sourceAgent: "calendar",
        riskLevel: "medium",
      },
    ],
    events: [
      {
        title: "Design Review",
        location: "Studio — Room 2B",
        start: atTime(now, 10, 0),
        end: atTime(now, 10, 45),
      },
      {
        title: "1:1 with Priya",
        location: null,
        start: atTime(now, 13, 30),
        end: atTime(now, 14, 0),
      },
      {
        title: "School Pickup",
        location: "Lincoln Elementary",
        start: atTime(now, 14, 0),
        end: atTime(now, 14, 30),
      },
    ],
    signals: [
      {
        title: "Rain expected this afternoon",
        subtitle: "60% chance starting around 3:00 PM",
        agent: "weather",
      },
      {
        title: "Pickup overlaps 2:00 PM sync",
        subtitle: "Calendar conflict detected",
        agent: "planning",
      },
    ],
    timeline: [
      { kind: "reminder", time: new Date(now.getTime() - 45 * 60 * 1000), title: "Prep notes for Design Review", subtitle: "Reminder" },
      { kind: "task", time: new Date(now.getTime() - 2 * 3600 * 1000), title: "Confirm school pickup plan", subtitle: "Personal" },
      { kind: "event", time: atTime(now, 10, 0), title: "Design Review", subtitle: "Studio — Room 2B" },
      { kind: "event", time: atTime(now, 13, 30), title: "1:1 with Priya", subtitle: "Calendar" },
      { kind: "task", time: atTime(now, 16, 0), title: "Send updated deck", subtitle: "Due today" },
    ],
  };
}

function el(html) {
  const t = document.createElement("template");
  t.innerHTML = html.trim();
  return t.content.firstElementChild;
}

function showToast(message) {
  state.toastMessage = message;
  render();
  window.clearTimeout(showToast._timer);
  showToast._timer = window.setTimeout(() => {
    state.toastMessage = "";
    render();
  }, 2200);
}

function renderSplash(root) {
  const screen = el(`
    <section class="screen splash active" data-screen="splash">
      <img src="logo.svg" alt="" class="splash-mark" width="88" height="88" />
      <h1>LifePilot</h1>
      <p>Preparing your day…</p>
    </section>
  `);
  root.appendChild(screen);
}

function renderOnboarding(root) {
  const step = ONBOARDING_STEPS[state.onboardingIndex];
  const progress = ((state.onboardingIndex + 1) / ONBOARDING_STEPS.length) * 100;
  const screen = el(`
    <section class="screen onboarding active" data-screen="onboarding">
      <div class="progress-bar"><div class="progress-fill" style="width:${progress}%"></div></div>
      <div class="onboarding-icon" aria-hidden="true">${step.icon}</div>
      <h2>${step.title}</h2>
      <p>${step.message}</p>
      <div class="onboarding-actions">
        ${state.onboardingIndex > 0 ? '<button type="button" class="btn btn-secondary" data-action="onboarding-back">Back</button>' : ""}
        <button type="button" class="btn btn-primary" data-action="onboarding-next">
          ${state.onboardingIndex === ONBOARDING_STEPS.length - 1 ? "Get started" : "Continue"}
        </button>
      </div>
    </section>
  `);
  root.appendChild(screen);
}

function renderRecommendationCard(rec) {
  const riskBadge =
    rec.riskLevel !== "low"
      ? `<span class="badge badge-risk">${rec.riskLevel}</span>`
      : "";
  return `
    <article class="card" data-rec-id="${rec.id}">
      <div class="card-meta">
        <div class="avatar" aria-hidden="true">${AGENT_ICONS[rec.sourceAgent] || "✨"}</div>
        <span class="agent-label">${AGENT_LABELS[rec.sourceAgent] || rec.sourceAgent}</span>
        ${riskBadge}
      </div>
      <h3 class="card-title">${rec.title}</h3>
      <p class="card-reason">${rec.reasoning}</p>
      <div class="onboarding-actions" style="padding-top:12px;margin-top:12px">
        <button type="button" class="btn btn-primary" data-action="approve" data-id="${rec.id}">Approve</button>
        <button type="button" class="btn btn-secondary" data-action="dismiss" data-id="${rec.id}">Dismiss</button>
      </div>
    </article>
  `;
}

function renderHome(model) {
  const { greeting, dateText } = greetingContext();
  const recs = model.recommendations.filter((r) => !state.dismissedRecommendations.has(r.id));

  return `
    <div class="scroll-content">
      <div class="hero-date">${dateText}</div>
      <h1 class="hero-greeting">${greeting}</h1>

      <section class="section">
        <div class="section-header"><span>✨</span> Prepared for you</div>
        ${recs.length ? recs.map(renderRecommendationCard).join("") : '<p class="card-reason">All caught up — Ghost Brain will surface new recommendations as your day evolves.</p>'}
      </section>

      <section class="section">
        <div class="section-header"><span>📅</span> Upcoming schedule</div>
        <div class="card">
          ${model.events
            .map(
              (e) => `
            <div class="schedule-row">
              <div class="schedule-time">${formatTime(e.start)}</div>
              <div class="schedule-details">
                <strong>${e.title}</strong>
                <span>${e.location || "No location"}</span>
              </div>
            </div>`
            )
            .join("")}
        </div>
      </section>

      <section class="section">
        <div class="section-header"><span>⚡</span> Quick actions</div>
        <div class="quick-actions">
          <button type="button" class="quick-action" data-action="quick" data-msg="Briefing refreshed">
            <strong>Refresh briefing</strong><span>Pull latest signals</span>
          </button>
          <button type="button" class="quick-action" data-action="quick" data-msg="Snoozed until 9:00 AM">
            <strong>Snooze alerts</strong><span>1 hour quiet mode</span>
          </button>
        </div>
      </section>

      <section class="section">
        <div class="section-header"><span>📡</span> Recent activity</div>
        ${model.signals
          .map(
            (s) => `
          <div class="card" style="margin-bottom:8px">
            <div class="card-meta">
              <div class="avatar">${AGENT_ICONS[s.agent] || "✨"}</div>
              <span class="agent-label">${AGENT_LABELS[s.agent]}</span>
            </div>
            <h3 class="card-title" style="font-size:18px">${s.title}</h3>
            <p class="card-reason">${s.subtitle}</p>
          </div>`
          )
          .join("")}
      </section>
    </div>
  `;
}

function renderTimeline(model) {
  const items = [...model.timeline].sort((a, b) => a.time - b.time);
  return `
    <div class="scroll-content">
      <h1 class="hero-greeting" style="font-size:28px;margin-bottom:8px">Timeline</h1>
      <p class="card-reason" style="margin-bottom:24px">Everything happening across your connected apps, in one stream.</p>
      <div class="card">
        ${items
          .map(
            (item) => `
          <div class="timeline-item">
            <div class="timeline-dot"></div>
            <div>
              <span style="font-size:13px;color:var(--text-secondary)">${formatTime(item.time)} · ${item.kind}</span>
              <strong>${item.title}</strong>
              <span>${item.subtitle}</span>
            </div>
          </div>`
          )
          .join("")}
      </div>
    </div>
  `;
}

function renderPlaceholder(title, icon, message) {
  return `
    <div class="scroll-content placeholder">
      <div class="placeholder-icon" aria-hidden="true">${icon}</div>
      <h2 style="margin:0 0 8px">${title}</h2>
      <p style="margin:0;color:var(--text-secondary);line-height:1.5">${message}</p>
    </div>
  `;
}

function renderSettings() {
  return `
    <div class="scroll-content">
      <h1 class="hero-greeting" style="font-size:28px">Settings</h1>
      <div class="settings-group">
        <h3>Preferences</h3>
        <div class="settings-row"><span>Morning briefing time</span><span style="color:var(--text-secondary)">7:00 AM</span></div>
        <div class="settings-row"><span>Explain recommendations</span><div class="toggle" aria-hidden="true"></div></div>
      </div>
      <div class="settings-group">
        <h3>Connections</h3>
        <div class="settings-row"><span>Calendar</span><span style="color:var(--signal-success)">Mock</span></div>
        <div class="settings-row"><span>Reminders</span><span style="color:var(--signal-success)">Mock</span></div>
        <div class="settings-row"><span>Maps & Travel</span><span style="color:var(--text-secondary)">Leave-by ETA</span></div>
      </div>
      <div class="settings-group">
        <h3>About</h3>
        <div class="settings-row"><span>Version</span><span style="color:var(--text-secondary)">0.4.0-demo</span></div>
      </div>
    </div>
  `;
}

function renderMain(root) {
  const model = mockModel();
  let body = "";

  switch (state.tab) {
    case "home":
      body = renderHome(model);
      break;
    case "timeline":
      body = renderTimeline(model);
      break;
    case "memory":
      body = renderPlaceholder(
        "Memory",
        "🧠",
        "Long-term preferences and routines land in Phase 4. Ghost Brain will use them to personalize every briefing."
      );
      break;
    case "insights":
      body = renderPlaceholder(
        "Insights",
        "📈",
        "Patterns in how you plan and communicate — periodic summaries arrive in Phase 4."
      );
      break;
    case "settings":
      body = renderSettings();
      break;
    default:
      body = renderHome(model);
  }

  const tabs = TABS.map(
    (t) => `
    <button type="button" class="tab-btn ${state.tab === t.id ? "active" : ""}" data-tab="${t.id}">
      <span class="tab-icon" aria-hidden="true">${t.icon}</span>
      ${t.label}
    </button>`
  ).join("");

  const screen = el(`
    <section class="screen main-shell active" data-screen="main">
      ${body}
      <nav class="tab-bar" aria-label="Main">${tabs}</nav>
      <div class="toast ${state.toastMessage ? "show" : ""}" role="status">${state.toastMessage}</div>
    </section>
  `);
  root.appendChild(screen);
}

function render() {
  const root = document.getElementById("app-root");
  root.innerHTML = "";

  if (state.phase === "splash") renderSplash(root);
  else if (state.phase === "onboarding") renderOnboarding(root);
  else renderMain(root);
}

function bindAppEvents() {
  const root = document.getElementById("app-root");

  root.addEventListener("click", (event) => {
    const target = event.target.closest("[data-action],[data-tab]");
    if (!target) return;

    if (target.dataset.tab) {
      state.tab = target.dataset.tab;
      render();
      return;
    }

    switch (target.dataset.action) {
      case "onboarding-back":
        state.onboardingIndex = Math.max(0, state.onboardingIndex - 1);
        render();
        break;
      case "onboarding-next":
        if (state.onboardingIndex < ONBOARDING_STEPS.length - 1) {
          state.onboardingIndex += 1;
        } else {
          state.phase = "main";
        }
        render();
        break;
      case "approve":
        state.dismissedRecommendations.add(target.dataset.id);
        showToast("Approved — queued for execution");
        break;
      case "dismiss":
        state.dismissedRecommendations.add(target.dataset.id);
        showToast("Dismissed");
        break;
      case "quick":
        showToast(target.dataset.msg);
        break;
      default:
        break;
    }
  });
}

function restartDemo() {
  state.phase = "splash";
  state.onboardingIndex = 0;
  state.tab = "home";
  state.dismissedRecommendations.clear();
  state.toastMessage = "";
  render();
  window.setTimeout(() => {
    state.phase = "onboarding";
    render();
  }, 1200);
}

function init() {
  document.documentElement.dataset.theme = "dark";
  render();
  bindAppEvents();

  window.setTimeout(() => {
    if (state.phase === "splash") {
      state.phase = "onboarding";
      render();
    }
  }, 1200);

  document.getElementById("btn-restart").addEventListener("click", restartDemo);

  document.getElementById("btn-theme").addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    document.getElementById("btn-theme").setAttribute("aria-pressed", String(next === "dark"));
  });
}

init();
