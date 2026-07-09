# Product Vision

## One Sentence

LifePilot is a proactive AI companion that prepares your day before you ask.

## The Belief We're Building On

Software has spent two decades getting better at *displaying* information and no better at *synthesizing* it. A calendar shows meetings. An inbox shows messages. A weather app shows a forecast. None of them know that today's rain should move the 1 PM outdoor lunch, or that the delayed 7 AM flight makes the 10 AM meeting impossible to attend in person.

That synthesis — turning ten disconnected signals into one coherent understanding of "what today requires of me" — has always been left to the human. We believe that work no longer needs to be manual, and that the products which remove it will define the next era of personal software, the same way the smartphone redefined the era before it.

## What LifePilot Is

An AI operating system for everyday life, built around one loop: **Observe → Understand → Predict → Prepare → Explain → Approve → Execute → Learn.** Full detail on each stage lives in the [README's Core Philosophy](../README.md#core-philosophy).

## What LifePilot Is Not

- **Not a chatbot.** There is no empty text box waiting for the user to think of a question. LifePilot initiates.
- **Not a replacement for existing apps.** Calendar, Mail, and Maps remain the systems of record. LifePilot is the layer that understands them together — see [The Solution](../README.md#the-solution).
- **Not an automation tool that acts without oversight.** Every high-risk action requires explicit approval. LifePilot prepares; the user decides. See [Security](../README.md#security).

## Who We're Building For

People whose day is assembled from many independent systems: dense calendars, high message volume, frequent travel, and a real cost — in time and attention — to doing that assembly manually every morning. Precisely the audience described in the README's [Introduction](../README.md#introduction).

## How We'll Know We're Right

Not by engagement metrics in the traditional sense — a successful morning briefing is one the user barely has to interact with, because it already told them what they needed to know. The right measure of LifePilot's success is time and cognitive load *removed*, not time spent in the app.

## Product Principles

1. **Prepare, don't perform.** LifePilot's default posture is proposing, not acting. Autonomy is opt-in and scoped, never assumed.
2. **Explain everything.** Every prediction and recommendation carries the reasoning behind it. A recommendation without an explanation is a black box, and black boxes don't earn trust.
3. **Orchestrate, don't replace.** We integrate with the tools people already trust rather than asking them to migrate their data into a new silo.
4. **Privacy is a default, not a setting.** On-device processing and least-privilege integrations are architectural commitments — see [ARCHITECTURE.md](ARCHITECTURE.md) and [SECURITY.md](../SECURITY.md).
5. **Earn autonomy incrementally.** The system's ability to act without approval expands only as its predictions prove reliable — trust is built, not assumed. This is the throughline of the [Roadmap](../ROADMAP.md) from Phase 3 (predictions only) through Phase 5 (automation).

## Where This Goes

The long-term ambition is described in the README's [Future Vision](../README.md#future-vision): LifePilot becomes the intelligence layer underneath everyday life, not one more app competing for a place on the home screen. Calendars, inboxes, and maps will still exist — the goal is that people need to open them less, because the layer above them already did the work.
