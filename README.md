# RGX | AQoL

**Another Quality of Life** — quality-of-life enhancements for WoW Forever, built on RGX-Framework.

The folder and saved variables are still `RGXQoL`; only the in-game name changed.

## Features

- One framework-hosted settings page (`/qol`) with Chat, Vendors, Minimap, Questing, and Party and death cards.
- Optional quest acceptance, quest turn-in, and gossip automation with an override key.
- Automatic junk sales and repairs, with optional chat summaries.
- Optional summon and resurrection acceptance, PvP/open-world release, and spirit-healer resurrection.

### Quest and resurrection automation

Turn on the **Questing** card and **Accept available quests** to accept quests
automatically. **Require override key** reverses the selected key's behavior:
when enabled, hold the key to automate; otherwise, hold it to pause automation.
Quest exclusions and item/gold requirements still apply.

**Accept spirit healer resurrection** belongs to **Party and death**, not
Questing. It selects the standard, client-localized Spirit Healer's single
gossip choice and then accepts the resurrection confirmation, including its
second sickness confirmation. Hold Shift to cancel. Unrelated NPCs and
ambiguous multiple-choice menus remain manual. Turning the option or its card
off also cancels pending automatic confirmation.

## Compatibility

- WoW Forever (classic beta, interface `16001`)

### RGX Guides Quest-Automation Coexistence

When RGX Guides is loaded with staged quest automation active, QoL's automate-quests handler defers to Guides for NPC/quest interactions within an active guide step. The gate probes `C_AddOns.IsAddOnLoaded("RGXGuides")` and the zero-arg guide-state callable `RGXGuides.QuestAutoAccept()`, which reports whether an active guide step owns the current interaction. That callable is the Guides-side contract defined by realmgx-guides#4; its implementation is tracked in realmgx-guides#17 — until that issue lands and ships on the Guides repo, no shipped Guides release exposes it, so the QoL side simply never takes the deferral branch. Once realmgx-guides#17 ships, at each automation decision point (quest accept, quest turn-in, quest select), if Guides is loaded and its callable reports an active guide step covering the current NPC/quest, QoL returns early instead of proceeding.

When RGX Guides is absent or disabled, QoL automation behavior is unchanged. Precedence rule: Guides-specific automation takes priority over QoL generic automation for covered interactions; QoL handles only quests not owned by an active Guides step. This prevents double-accept of the same quest.

## Requirements

- [RGX-Framework](https://github.com/RGXMods/RGX-Framework) must be installed and enabled.

## Installation

1. Install RGX-Framework.
2. Copy this repository into your `Interface/AddOns` directory as `RGXQoL`.
3. Restart the game client.

## Commands

| Command | Action |
| --- | --- |
| `/qol` | Open the options panel |
| `/rl` | Reload the UI |

## License And Attribution


## Links

- Development (GitLab): `rgxmods/warcraft/RGXAQoL`
- Distribution mirror (GitHub): [RGXMods/RGXAQoL](https://github.com/RGXMods/RGXAQoL)
