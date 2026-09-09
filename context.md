# Project Context: Raise a Cult (Roblox Tycoon)

## 📌 Project Overview
**Raise a Cult** is an idle tycoon game inspired by *Adventure Capitalist* and *Sell Lemons* mechanics. Players grow a cult from a lone sidewalk street preacher into an omnipotent global pantheon, collecting cash, upgrading floor structures, unlocking milestone output multipliers, hiring managers for automated collection, and executing multi-layer prestige resets (**Schism $\rightarrow$ Reformation $\rightarrow$ Ascension**) to accumulate Followers and permanent meta-boosts.

---

## 🏗️ Core Architecture & Implemented Systems

### 1. Centralized Economy Engine (`ReplicatedStorage.Economy`)
* **`EconomyConfig.luau`**:
  * **Elevated 10-Tier Building Definitions:** Calibrated base costs, yields, cycle times, and growth rates ($r = 1.12 \to 1.21$) to compensate for dual milestone and floor upgrade scaling:
    * **Building 1 (Street Preacher):** Base Unit $15 | Manager $250 | Base Yield $1 | Cycle 1.0s | $r = 1.12$
    * **Building 2 (Storage Temple):** Unlock $35,000 | Manager $2.5M | Base Yield $500 | Cycle 3.0s | $r = 1.13$
    * **Building 3 (Suburban Compound):** Unlock $50M | Manager $5B | Base Yield $250,000 | Cycle 6.0s | $r = 1.14$
    * **Building 4 (Community Hall):** Unlock $50B | Manager $50T | Base Yield $200M | Cycle 12.0s | $r = 1.15$
    * **Building 5 (Wellness Ranch):** Unlock $100T | Manager $250Qa | Base Yield $350B | Cycle 24.0s | $r = 1.16$
    * ... scaling to **$500 Sexagintillion ($10^{185}$)** for Building 10 with endgame capstones at **$50 Novemsexagintillion ($10^{211}$)**.
  * **Strict Role Separation:** 
    * **Unit Milestones:** Strictly provide **geometric output doublings** ($2\times$ at Levels 10, 25, 50, 100, 200, 500, 1000+). `SpeedMult = 1` across all milestones to eliminate premature cycle time collapse.
    * **Floor Upgrades:** Sole source of cycle acceleration ($2\times$ per tier for Tiers 1–7, $3\times$ for Tier 8 $\implies \mathbf{384\times}$ total speed divisor).
  * **8-Tier Floor Upgrade Multiplier Curve ($B_k$):** $[2.0, 25, 300, 35000, 400000, 25\text{M}, 7.5\text{B}, 150\text{T} \times B_k]$.
* **`EconomyMath.luau`**:
  * Exact geometric batch cost formulas (`GetSingleCost`, `GetBatchCost`, `CalculateMaxAffordable`).
  * **`FormatCurrency`**: 100-Tier continuous short-scale formatter (`K` through `Ce` Centillion $10^{303}$, switching to scientific notation beyond).
  * **`FormatTime`**: Dynamic cycle duration formatting (`every 0.05s`, `every 1.25ms`, `every 500μs`).

---

### 2. Economy & Data Persistence (`MoneyManager.luau`)
* **Location:** `ServerScriptService.MoneyManager` (ModuleScript)
* **Functionality:** 
  * Full player tycoon state persistence via `DataStoreService` (`Cash`, `LastSavedTimestamp`, and per-building `OwnedCount`, `FloorUpgrades`, and `HasManager`).
  * Default `OwnedCount = 0` on first join (prompts player to step on free $0 starter button).
  * Implements **0.25x offline earnings** based on automated manager rates upon rejoin.
  * In-memory fallback for local Studio playtests when API access is disabled.
  * Fires `MoneyUpdated` RemoteEvent to keep client HUDs synchronized.

---

### 3. Universal Production Engine (`ProductionEngine.legacy.luau`)
* **Location:** `ServerScriptService.ProductionEngine.legacy.luau` (Script)
* **Functionality:**
  * Handles cycle calculation, yield math, and upgrade leveling.
  * Multi-building indexing with independent cycle state tables.
  * **Automated Manager Loop:** Runs at 20 Hz, broadcasting `StartCycle` and `CycleComplete` to client for continuous progress bar animations.
  * **Fast-Bar Streaming:** When cycle time $\le 0.1\text{s}$, streams smooth batch income at 20 Hz (every $0.05\text{s}$) with delta-time validation, preventing network lag and cycle stalls.

---

### 4. Progression Pipeline & Floor Buttons (`BuildingProgressionServer.legacy.luau`)
* **Location:** `ServerScriptService.BuildingProgressionServer.legacy.luau` (Script)
* **Functionality:**
  * Robust accessory touch detection via `hit:FindFirstAncestorWhichIsA("Model")`.
  * Per-player debounce table to eliminate cross-player interaction locking.
  * Dynamically queries `EconomyConfig` and `EconomyMath` to execute authoritative purchases.
  * **Dynamic Multi-Folder Stashing:** Dynamically moves all unpurchased models and buttons into `ReplicatedStorage.BuildingTemplates.Building1` on server start, preventing premature rendering.
  * **Full Building 1 Sequential Unlock Chain:**
    0. **`NewBuildingButton` ($0):** Unparents itself; spawns Table, Cult Member, `CollectUpgradeGui`, `ManagerButton` ($250), and `Flyers` button ($50).
    1. **`Worship Flyers` ($50, $2\times$ Speed):** Spawns table flyers $\rightarrow$ unlocks `More Preachers` button.
    2. **`More Preachers` ($600, $2\times$ Speed):** Spawns 2 chanting cultists $\rightarrow$ unlocks `Canopy Tents` button.
    3. **`Canopy Tents` (Cosmetic, $2,500):** Spawns 3 popup shelter tents $\rightarrow$ unlocks `Megaphones` button.
    4. **`Street Megaphones` ($10,000, $2\times$ Speed):** Spawns megaphones & preacher $\rightarrow$ unlocks `FloorChalk` button.
    5. **`FloorChalk` (Cosmetic, $50,000):** Spawns chalk circle & chalk cartons $\rightarrow$ unlocks `Outreach Booth` button.
    6. **`Outreach Booth` ($525K, $2\times$ Speed):** Spawns booth, pamphlets & phone $\rightarrow$ unlocks `Booklets` button.
    7. **`Printed Booklets` ($6.0M, $2\times$ Speed):** Spawns book stacks, boxes & member $\rightarrow$ unlocks `Speakers` button.
    8. **`Speaker Towers` ($375M, $2\times$ Speed):** Spawns dual PA speaker towers $\rightarrow$ unlocks `Street Sign` button.
    9. **`LED Street Signs` ($112.5B, $2\times$ Speed):** Spawns neon street sign $\rightarrow$ unlocks `Holy Podium` button.
    10. **`Holy Podium` ($2.25Qa, $3\times$ Speed):** Spawns elevated podium & golden player statue *(Building 1 Capstone)*.
    * **`ManagerButton` ($250):** Spawns at Stage 0; upon purchase, restores all manager props (`Table`, `Cult Member`, `MoneyonTable`) and triggers the slide-up animation and automated collection loop.
  * **Building 2 (Storage Unit Temple) Pipeline:**
    * **`NewBuildingButton` ($250,000):** Gated behind Building 1's `FloorChalk` (Sidewalk Chalk Circle, $50K). Stays hidden in templates until `FloorChalk` is purchased, which reveals both `OutreachBooth` in Building 1 and pops up this button in Building 2. Spawns the entire temple structure upon stepping on the floor button.
    * **Multi-Directional Assembly Animation (`BuildingAnimatorClient.local.luau`):**
      * `Ceiling`: pops down from $+Y$ ($+10\text{ studs}$).
      * `Floor`: pops up from $-Y$ ($-6\text{ studs}$).
      * `LeftWall`: pops rightwards from $-X$ ($-8\text{ studs}$).
      * `RightWall`: pops leftwards from $+X$ ($+8\text{ studs}$).
      * `FrontWall` & `BackWall`: pop in along $Z$ into place ($\pm 8\text{ studs}$).
      * `Light`: drops from ceiling with a slight bounce.
      * After a $0.35\text{s}$ delay, `Podium`, `Cult Member`, and `CollectUpgradeGui` pop up inside with standard upward easing.
    * **Dynamic Stashing:** Moves unowned Building 2 base assets (`Storage Unit`, `Podium`, `Cult Member`, `CollectUpgradeGui`) into `ReplicatedStorage.BuildingTemplates.Building2` until unlocked.

---

### 5. Client 3D UI & Interaction (`CollectUpgradeClient.local.luau`)
* **Location:** `StarterPlayer.StarterPlayerScripts.CollectUpgradeClient.local.luau` (LocalScript)
* **Architecture:** **PlayerGui Adornee Architecture** with Proximity Hysteresis
  * Clones 3D `BillboardGui`s into `Players.LocalPlayer.PlayerGui` and sets `Adornee = workspacePart`.
  * **Hysteresis Distance Checks:**
    * `CollectUpgradeGui`: Pop-in at $\le 7$ studs, pop-out at $\ge 9$ studs.
    * Floor Button `PricingTag`s: Pop-in at $\le 16$ studs, pop-out at $\ge 20$ studs.
  * **Dynamic Building ID Routing:** Automatically resolves building IDs from `part:GetAttribute("BuildingId")` or ancestor naming (`Building2`, `Building3`), enabling instant copy-paste modularity.
  * **Live Countdown & Seamless Animation:** Progress bar fills and resets continuously during manager automation without flashing `"READY"` between cycles.
  * **Anti-Ballooning Bounce Safety:** Fixed `BASE_SIZES` table (`280 × 44 px` for UpgradeButton, `360 × 34 px` for ProgressBarTrack) with active tween cancellation, preventing button growth during rapid clicking.
  * **`LevelLabel` Badge:** Displays unit level (`x1`, `x10`, etc.) with FredokaOne Bold and black `UIStroke`.
  * **Next-Level Price Calculation:** Default label initializes to Level 2 cost ($16) for `x1` owned buildings.

---

### 6. 3-Tier Button Billboard UI Standard
* **Billboard Size:** Standardized to `{0, 240}, {0, 120}` across all floor buttons.
* **Layout Hierarchy:**
  1. **`BenefitLabel` (Top):** `FredokaOne Bold`, 18px, White (`"2x Speed"`, `"Auto Collect"`, `"New Building"`, or Blank for Cosmetics).
  2. **`Title` (Middle):** `FredokaOne Bold`, 22px, Category Tint (Green for Speed, Magenta for Manager, Yellow for New Building, Cyan for Cosmetic).
  3. **`Pricing` (Bottom):** `FredokaOne Bold`, 22px, Category Tint (`$30`, `$375`, `$250`).

---

### 7. Custom Props, Shaders & Lighting
* **`WorshipFlyers` SurfaceGui:**
  * Configured with `LightInfluence = 0` and `Brightness = 1` to prevent dynamic NPC/character shadows from washing out paper flyers.
  * `HeadshotImage.BackgroundTransparency = 1` to eliminate grey square haze.
  * Rotated 90° with FredokaOne Bold `"WORSHIP"` header and player avatar thumbnail.
* **`BuildingAnimatorClient.local.luau`:** Standardized `PivotTo()` slide-up pop-in animation for newly purchased parts, including all `Manager` models (`Table`, `Cult Member`, `MoneyonTable`).
* **`PlayAnimation.server.luau`:** Attached to Manager's R15 `Cult Member` model to loop `Getting Money Animation` (`rbxassetid://9069088593`).

---

### 8. Authoritative Developer Console & Command System
* **Server Script:** `ServerScriptService.AdminServer.legacy.luau`
  * Strict permission verification: `player.UserId == game.CreatorId` (`51437187`), `ALLOWED_USER_IDS` whitelist, or `RunService:IsStudio()`.
  * Command syntax: `:give <amount>`, `:set <amount>`, `:reset`, `:unlockall`, `:unlockmanager <id>`, `:help`.
  * Suffix parsing: handles `k`, `M`, `B`, `T`, `Qa`, `Qi`, `Sx`, `Sp`, `Oc`, `No`, `Dc`, `Ud`, `Dd`, `Td`, `Qad`, `Qid`, `Sxd`, `Spd`, `Ocd`, `Nod`, `Vg`, `Cen`.
* **Client UI:** `StarterPlayer.StarterPlayerScripts.AdminClient.local.luau`
  * Floating `⚙ DEV` top-right button with `F4`, `;` (Semicolon), and `]` toggle hotkeys.
  * Status feedback banner for valid and invalid commands.

---

### 9. Dynamic Visual & Time Formatting Systems
* **Interactive READY Progress Bar (`CollectUpgradeClient.local.luau`):**
  * When in manual mode and idle/ready, the progress bar remains 100% full bright red (`fill.Size = UDim2.new(1, 0, 1, 0)`) with `"READY"` displayed.
  * Upon clicking, `ProgressFill` resets to `0%` revealing the dark red background and plays a linear fill sweep to `100%`.
* **Smart Dynamic Time Units (`EconomyMath.FormatTime`):**
  * `≥ 0.10s`: Displayed in seconds (`"every 1.5s"`, `"every 0.25s"`).
  * `< 0.10s`: Automatically switches to milliseconds (`"every 63ms"`, `"every 3ms"`).
  * `< 1ms`: Automatically switches to microseconds (`"every 500μs"`, `"every 10μs"`).
  * `< 1μs`: Automatically switches to nanoseconds (`"every 250ns"`).
* **Holy Podium Dynamic Avatar Loading (`AvatarScript.luau`):**
  * Remains `Transparency = 1` during load to eliminate T-pose flickers.
  * Applies `2.0x` scaling across all dimensions, purges pre-existing cultist hood/mask props, anchors all parts, and rotates 180° forward onto the podium stand.

---

### 10. Related Project Documents
* **[`economy.md`](file:///c:/Users/Nafiz%20Labib/raise-a-cult/economy.md):** Full mathematical PRD specification, multi-tier tables, and prestige mechanics.
* **[`building_upgrades_catalog.md`](file:///c:/Users/Nafiz%20Labib/raise-a-cult/building_upgrades_catalog.md):** Thematic 3D visual guide for all 8 speed upgrades and cosmetic construction steps across all 10 buildings.
* **[`proposed_prestiges.md`](file:///c:/Users/Nafiz%20Labib/raise-a-cult/proposed_prestiges.md):** 3-tier prestige economy (Schisms, Reformations, Ascensions) and Sacred Dogma scaling.
* **[`multi_plot_architecture.md`](file:///c:/Users/Nafiz%20Labib/raise-a-cult/multi_plot_architecture.md):** Architecture for multi-player tycoon plot cloning, owner isolation, and edit-time model preservation.
* **[`timeline.md`](file:///c:/Users/Nafiz%20Labib/raise-a-cult/timeline.md):** Complete chronological engineering and commit log.