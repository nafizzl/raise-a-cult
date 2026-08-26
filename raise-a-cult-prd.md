# Raise a Cult — Product Requirements Document

**Status:** Draft v1
**Genre:** Roblox idle/incremental (Adventure Capitalist-style clicker/tycoon)
**Core Fantasy:** Grow a cult from a lone street preacher into a global movement. Buy buildings that recruit Followers over time, buy managers to automate them, buy upgrades to make each building faster/stronger, and periodically reset everything ("Schism") for a permanent multiplier.

---

## 1. Vision

A theme-swapped Adventure Capitalist clone: cult recruitment instead of businesses, Followers instead of cash. The genre is systems-driven rather than asset-driven, which makes it realistically shippable as an MVP in under a week — the core loop is GUI, math, and a DataStore, not 3D art or scripted tension.

## 2. Goals

- Ship a complete, playable MVP (10 buildings, upgrade system, one prestige layer, save/load) in under a week, solo.
- Deliver the specific "number go up" satisfaction of Adventure Capitalist: buy → wait/collect → reinvest → hit a wall → prestige → repeat, faster each cycle.
- Keep monetization hooks (gamepasses, boosts) identifiable in the design but **not required for MVP** — see Section 8.

## 3. Non-Goals (v1)

- No multiplayer, no cult-vs-cult competition, no trading.
- No story/narrative content beyond flavor text on buildings and upgrades.
- No more than one prestige layer (no "prestige of prestige" meta-currency yet).
- No stock-market-style side minigame (Adventure Capitalist has one; out of scope for MVP).

## 4. Core Loop

1. Spend **Followers** to buy units of a building.
2. Each building unit generates Followers per **cycle** (a fixed time window).
3. Without a manager, the player must tap the building to collect once a cycle completes; with a manager, collection is automatic.
4. Milestone ownership counts unlock **upgrades** that double a building's output.
5. As costs outpace income on early buildings, the player unlocks and shifts investment to later, more powerful buildings.
6. Once growth stalls, the player triggers **Schism** (prestige): all buildings/Followers reset, but the player gains **Zealot Points**, which grant a permanent global production multiplier — making the next run faster from the start.

## 5. Currency & Core Formulas

**Primary currency:** Followers (used to buy buildings and building-upgrades)
**Prestige currency:** Zealot Points (used to buy permanent multipliers)

### 5.1 Building cost (exponential)

```
Cost(n) = BaseCost × GrowthRate ^ n
```
Where `n` = number of that building already owned (0-indexed), `BaseCost` and `GrowthRate` are per-building constants (see Section 6).

**Example — Building 1 (Base Cost 10, Growth Rate 1.07):**
| Owned before purchase (n) | Cost of next unit |
|---|---|
| 0 | 10 |
| 1 | 10.7 |
| 10 | ~19.7 |
| 50 | ~294 |
| 100 | ~8,676 |

Cost to buy a batch of `m` units starting from `n` owned (geometric series, needed for "Buy 10 / Buy Max" UI buttons):
```
BatchCost(n, m) = BaseCost × GrowthRate^n × (GrowthRate^m − 1) / (GrowthRate − 1)
```

### 5.2 Production per building

```
CycleOutput = OwnedCount × BaseProduction × UpgradeMultiplier × PrestigeMultiplier
IncomePerSecond = CycleOutput / CycleTime   (effective rate once a manager is owned)
```
- `BaseProduction` = Followers generated per unit, per cycle, at no upgrades.
- `UpgradeMultiplier` = product of all owned milestone-upgrade multipliers for that building (see 7.1).
- `PrestigeMultiplier` = `1 + (0.02 × ZealotPoints)` — global, applies to every building equally.
- `CycleTime` = seconds per production cycle for that building; reduced by speed upgrades (see 7.2).

## 6. The 10 Buildings

Costs/production below are **illustrative starting values** meant to establish the correct shape of the curve (each tier roughly an order of magnitude more expensive and more productive than the last, mirroring Adventure Capitalist's pacing). They will need a real balancing pass during MVP playtesting — see Section 10.

| # | Building | Base Cost | Growth Rate | Base Production (Followers/cycle/unit) | Cycle Time | Manager Cost |
|---|---|---|---|---|---|---|
| 1 | Street Corner Preacher | 10 | 1.07 | 1 | 1s | 1,000 |
| 2 | Storage Unit Temple | 150 | 1.08 | 8 | 3s | 15,000 |
| 3 | Suburban Compound | 2,000 | 1.09 | 47 | 6s | 150,000 |
| 4 | Community Hall | 25,000 | 1.10 | 260 | 10s | 1.5M |
| 5 | Wellness Retreat Ranch | 300,000 | 1.11 | 1,430 | 15s | 15M |
| 6 | Merch & Media Wing | 4M | 1.12 | 7,700 | 20s | 150M |
| 7 | Pirate Radio/TV Broadcast | 50M | 1.13 | 40,000 | 30s | 1.5B |
| 8 | Underground Bunker Complex | 650M | 1.14 | 200,000 | 45s | 15B |
| 9 | Shell Corporation Network | 8B | 1.15 | 950,000 | 60s | 150B |
| 10 | Global Mega-Temple HQ | 100B | 1.16 | 4.2M | 90s | 1.5T |

Design intent per column:
- **Growth Rate climbs by tier** (1.07 → 1.16) so early buildings are cheap to stack fast (satisfying early game) while late buildings stay meaningful investments for longer (prevents "solved" endgame spam-buying).
- **Cycle Time climbs by tier** so late buildings feel weighty/passive (check back later) versus early buildings feeling twitchy/clicky — matches Adventure Capitalist's pacing shift.
- **Manager Cost ≈ 100× that building's base cost**, standard idle-genre ratio that makes automation feel like a real milestone, not an afterthought.

## 7. Upgrade System

### 7.1 Ownership-milestone multipliers (per building)

At each of these owned-unit thresholds, that building's output **doubles**:
```
10 owned → ×2
25 owned → ×2 (×4 total)
50 owned → ×2 (×8 total)
100 owned → ×2 (×16 total)
200 owned → ×2 (×32 total)
500 owned → ×2 (×64 total)
```
`UpgradeMultiplier = 2 ^ (number of milestones reached)`

This is the direct Adventure Capitalist pattern and is the main lever that makes "just keep buying the same building" a viable, satisfying strategy rather than purely a cost trap.

### 7.2 Speed upgrades (global)

A separate purchasable tier, bought with Followers, independent of any one building:
```
Recruitment Speed I–V, each: −10% to all CycleTimes (multiplicative)
```
Framed thematically as things like "Hire more recruiters," "Print faster pamphlets," "Charter a second bus." These make automation (managers) increasingly valuable and give the player a mid-game reason to spend on something other than raw building count.

### 7.3 Flavor examples (theming only, same underlying math)

| Building | Milestone flavor text example |
|---|---|
| Street Corner Preacher | "New sandwich board — 25% more converts per hour" |
| Wellness Retreat Ranch | "Add a sauna. Recruits stay longer, donate more." |
| Pirate Radio/TV Broadcast | "3 AM infomercial slot secured." |
| Global Mega-Temple HQ | "The dome is visible from orbit." |

## 8. Prestige — "Schism"

Available once the player has purchased at least one unit of Building 5 or reached a minimum lifetime-Followers threshold (exact gate TBD in balancing).

```
ZealotPointsEarned = floor( sqrt( LifetimeFollowersEarned / 1e9 ) )
```

On Schism:
- All Followers, buildings, and building-upgrades reset to zero.
- Managers and milestone-upgrade *ownership records* reset (must be re-bought next run).
- `ZealotPoints` are added to the player's permanent total.
- `PrestigeMultiplier = 1 + (0.02 × TotalZealotPoints)` applies globally from the very start of the new run — this is what makes each run faster than the last and is the genre's core long-term hook.

## 9. Building Visual Progression

**Goal:** capture the "buildings visibly assemble as you invest" feel that made Sell Lemons stand out aesthetically, without the art cost of unique models per building per tier.

### 9.1 Approach: modular piece-reveal (not full-model stage-swap)

Rather than swapping between a handful of discrete building models at set thresholds, each building is constructed from a small kit of reusable modular pieces (tent, stall, sign, fence panel, banner, extra structure segment, etc.). Pieces start hidden and are individually animated into visibility as the player invests. This reads as active construction rather than a picture changing, and scales cheaply across all 10 buildings since the same piece kit is reused with different dressing (color/signage) per building.

**Kit budget for MVP:** ~10–15 reusable pieces total, shared across all 10 buildings via re-skinning (recolor/re-texture, not new geometry).

### 9.2 Trigger point: milestone-based, not per-purchase

Each building already has 6 ownership milestones (10/25/50/100/200/500 owned — Section 7.1). Visual reveals trigger **at these same milestones**, reusing an existing hook rather than adding new logic:

- 10 owned → first piece(s) appear (e.g., a second tent goes up)
- 25 owned → structure expands (e.g., stall becomes a small building)
- 50 owned → signage/banner appears
- 100 owned → building visibly doubles in footprint
- 200 owned → surrounding scenery changes (crowd of NPC followers, queue forms)
- 500 owned → final "maxed out" flourish (largest structure state, unique lighting/particle effect)

This caps the animation-trigger count at 6 per building × 10 buildings = 60 total reveal events for the MVP — bounded and plannable in a week, versus an uncapped per-purchase drip-feed.

**Deferred (post-MVP polish):** a true per-purchase drip-feed (a small visible change every few units bought, closer to Sell Lemons' constant motion) is a good candidate for a later update once the milestone system is proven, but adds meaningfully more animation-authoring time and isn't required for v1 to read as "alive."

### 9.3 Implementation pattern (Roblox / TweenService)

Each hidden piece starts either fully transparent, scaled to near-zero, or positioned below the floor (or a combination). On milestone trigger:

```lua
local TweenService = game:GetService("TweenService")

local function revealPiece(piece, finalPosition, finalSize)
    piece.Transparency = 1
    piece.Size = finalSize * 0.01
    piece.Position = finalPosition - Vector3.new(0, 5, 0) -- start below ground
    piece.Parent = workspace -- or unhide if pre-parented

    local tweenInfo = TweenInfo.new(
        0.6,                              -- duration (sec)
        Enum.EasingStyle.Back,             -- overshoot "pop" feel
        Enum.EasingDirection.Out
    )

    local goal = {
        Position = finalPosition,
        Size = finalSize,
        Transparency = 0,
    }

    local tween = TweenService:Create(piece, tweenInfo, goal)
    tween:Play()

    -- pair with a short sound + particle burst on tween completion
    tween.Completed:Connect(function()
        playConstructionSound(piece)
        spawnDustBurst(piece.Position)
    end)
end
```

**Why the sound/particle pairing matters:** the motion alone reads as fine but forgettable; the combination of tween + a short construction sound cue + a small particle burst on landing is what actually sells the "satisfying" feeling players associate with Sell Lemons — worth treating as a required pair, not an optional add-on.

### 9.4 Scope guardrail

To keep this inside the one-week MVP window:
- Reuse one shared reveal function (`revealPiece`) across all buildings/pieces — don't hand-author unique tweens per building.
- Reuse one shared sound + one shared particle effect for all reveals in v1 (per-building unique effects are a post-MVP polish pass).
- Build the modular kit once, dress it per building via recolor/retexture rather than new geometry.

## 10. MVP Scope Checklist

**In scope for v1:**
- 10 buildings with cost/production formulas above
- Buy 1 / Buy 10 / Buy Max UI
- Per-building manager purchase (automation)
- Per-building milestone upgrades (6 tiers each = 60 upgrades total)
- Global speed upgrade tier (5 levels)
- One prestige layer (Schism / Zealot Points)
- DataStore save/load (including offline-earnings calculation on rejoin)
- Basic UI: building list, currency counter, prestige screen

**Explicitly deferred:**
- Cosmetic/visual building upgrades in 3D world (numbers-only UI is enough for MVP)
- Gamepasses/monetization (design should leave hooks — e.g., a "2x offline earnings" pass — but none need to be built for MVP)
- Second prestige layer / meta-currency shop
- Any competitive or social feature

## 11. Open Questions / Risks

- **Balancing pass required:** the cost/production table in Section 6 is a structurally reasonable starting curve, not tuned numbers — needs a spreadsheet simulation (or in-engine playtesting) to confirm early-game buildings become "not worth clicking" at the intended pace and that Schism timing feels rewarding rather than punishing.
- **Offline earnings:** need to decide a cap (e.g., 8–24 hours) so idle progress doesn't trivialize active play.
- **Buy Max UI performance:** `BatchCost` calculations need to run cleanly at large `n` without float precision issues — Roblox Lua numbers should be fine up to the ranges here, but very late-game prestige-boosted runs should be spot-checked.
- **First-prestige gate:** needs a concrete threshold (currently TBD) so new players don't stumble into an unrewarding first Schism.
