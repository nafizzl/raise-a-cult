# Project Timeline & Progress Log

## August 26, 2026

* **Economy & Data Persistence (`MoneyManager.luau`):**
  * Created `MoneyManager` ModuleScript in `ServerScriptService` with DataStore saving.
  * Implemented **0.25x offline earnings** policy for returning players based on timestamp delta.
  * Added Studio API fallback so local playtesting runs smoothly in-memory.

* **Live Currency Display (`HUDController.luau`):**
  * Built `HUDController` in `StarterPlayerScripts` to format cash ($0, $100, $1.5K, $2.4M, $3.8B) on the main UI.

* **Production Engine & Milestone System (`ProductionEngine.luau`):**
  * Configured base yield math ($1), growth rate (1.07), and base cycle time (1.0s).
  * Added 2x speed boost milestones (25, 50, 100, 200, 500 upgrades).
  * Added late-game yield multipliers ($\times 2, \times 4, \times 10$) at 1,000 to 10,000 upgrades.

* **Building 1 Step-by-Step Unlock Pipeline (`BuildingProgressionServer.luau`):**
  * Implemented initial template hiding in `ReplicatedStorage.BuildingTemplates.Building1`.
  * Connected unlock progression: `NewBuildingButton` ($0) $\rightarrow$ `Flyers` ($100) $\rightarrow$ `MorePreachers` ($500) $\rightarrow$ `Manager` ($10,000).

* **Prop Design & NPC Customization:**
  * Custom `WorshipFlyers` paper poster design with 0.9 margin, 90° rotated SurfaceGui, and paper-colored part.
  * Created `FriendNPCScript` to morph workspace avatar into a random Roblox friend.

* **Structure Animation Standard (`BuildingAnimatorClient.luau`):**
  * Welded `Table` parts together and standardized `PivotTo()` slide-up pop animation for all unlocked structures coming from underneath the ground.

* **UI Interactivity & PlayerGui Architecture (`CollectUpgradeClient.local.luau`):**
  * Solved Roblox 3D UI click suppression by migrating to **PlayerGui Adornee Architecture** (`BillboardGui.Adornee = workspacePart`).
  * Added live frame-by-frame countdown timer ($1.0\text{s} \rightarrow 0.0\text{s}$) to progress bar during cycles.
  * Restored `UIScale` spring pop-in (`Back.Out`, 0.25s) and pop-out (`Back.In`, 0.18s) proximity animations.
  * Mounted floor button **`PricingTag`** billboards into `PlayerGui` for seamless proximity visibility.
  * Saved all changes permanently in Roblox Studio Edit mode and workspace files.

## August 29, 2026

* **Centralized Economy Engine (`EconomyConfig.luau` & `EconomyMath.luau`):**
  * Built `ReplicatedStorage.Economy` containing `EconomyConfig` and `EconomyMath`.
  * Configured canonical 10-building parameters (Building 1 Base Cost $4, Growth Rate 1.07, Base Yield $1, Cycle Time 1.0s, Manager Cost $100).
  * Designed the **8-Tier Exponential Floor Speed Upgrade curve** inspired by *Sell Lemons* ($3.5\times, 25\times, 200\times, 3,000\times, 85,000\times, 4.5\text{M}\times, 350\text{M}\times, 60\text{B}\times B_k$) applying strictly to cycle speed ($384\times$ total speed divisor).
  * Implemented pure geometric batch cost formulas, Buy Max calculations, and extended milestone output multipliers past 1,000,000.
  * Built **Option A 100-Tier Continuous Short-Scale Formatter** spanning from `K` up through `Ce` (Centillion $10^{303}$) and transitioning to scientific notation beyond.

* **Full Tycoon Data Persistence (`MoneyManager.luau`):**
  * Expanded DataStore schema to persist full player tycoon state (Cash, LastSavedTimestamp, building levels, unlocked floor upgrades, and manager ownership).
  * Implemented automatic **0.25x offline earnings** calculation on rejoin based on automated managers' effective rate.

* **Universal Production Loop & Fast-Bar Streaming (`ProductionEngine.luau`):**
  * Connected server production engine to `EconomyConfig` and `EconomyMath` with multi-building indexing.
  * Added smooth income batch streaming when cycle times drop below $\le 0.1\text{s}$ (10 Hz/1 Hz stream) to eliminate network lag.

* **Floor Button Touch Fixes & Progression Pricing (`BuildingProgressionServer.luau`):**
  * Fixed button touch failures caused by accessory parts by switching detection to `hit:FindFirstAncestorWhichIsA("Model")`.
  * Implemented per-player debounce table to prevent cross-player interaction locking.
  * Updated Building 1 progression costs to match economy spec: `NewBuildingButton` ($0) $\rightarrow$ `Flyers` ($14, $2\times$ speed) $\rightarrow$ `MorePreachers` ($100, $2\times$ speed) $\rightarrow$ `Manager` ($100).

* **Proximity Hysteresis & Fast-Bar Visuals (`CollectUpgradeClient.local.luau` & `HUDController.local.luau`):**
  * Solved `CollectUpgradeGui` collapsing/flickering bug by implementing **Distance Hysteresis** ($\le 14$ studs pop-in, $\ge 18$ studs pop-out) and clamping `UIScale.Scale \ge 0`.
  * Added pulsing green fast-bar visual animation with `"FAST"` text indicator when cycle time $\le 0.1\text{s}$.
  * Connected HUD and 3D Billboard labels to `EconomyMath.FormatCurrency` for synchronized, clean short-scale numbers.

* **Elevated Sell Lemons Economy Scale Implementation:**
  * **Dual-Milestone Compensated Unlock Gaps:** Calibrated all 10 building base costs ($B_1 = \$15, B_2 = \$35\text{K}, B_3 = \$50\text{M}, B_4 = \$50\text{B}, B_5 = \$100\text{T}, B_6 = \$500\text{Qi}, B_7 = \$50\text{Sp}, B_8 = \$250\text{Td}, B_9 = \$500\text{Vg}, B_{10} = \$500\text{Sg}$) to prevent rapid tier burning caused by combined milestone output doublings.
  * **Exponential Floor Speed Multipliers:** Applied $[2.0, 25, 300, 35000, 400000, 25\text{M}, 7.5\text{B}, 150\text{T}]$ curve, scaling Building 1 floor upgrades from **$30** up to **$2.25Qa** and Building 10 Tier 8 to **$50 Novemsexagintillion ($10^{211}$)**.
  * **Building 1 Pricing Realignment:** Updated Building 1 starting upgrades: Unit 1 Base ($15), Worship Flyers ($30), Building 1 Manager ($250), More Preachers ($375), and Megaphones ($4,500).

* **3-Tier Button Billboard UI & Starting Level Cost Alignment:**
  * **3-Tier Layout Standard:** Standardized vertical layout across all button `PricingTag` billboards (`BenefitLabel` in White FredokaOne Bold, item `Title` in colored FredokaOne Bold, and `Pricing` in colored FredokaOne Bold).
  * **Next-Level Cost Initialization:** Fixed `PriceText` to compute the next upgrade cost ($16 for starting Level `x1`) using `EconomyMath.GetSingleCost(bDef.BaseCost, bDef.GrowthRate, 2)` instead of unowned base cost.
  * **Catalog Specification:** Published [`building_upgrades_catalog.md`](file:///c:/Users/Nafiz%20Labib/raise-a-cult/building_upgrades_catalog.md) detailing 8 functional speed upgrades and intermediary cosmetic builds for all 10 tycoon buildings.

* **Manager Hierarchy Reorganization & Dynamic Prop Hiding:**
  * **Dynamic Manager Stashing:** Updated `BuildingProgressionServer.legacy.luau` to dynamically move all manager props (`Table`, `Cult Member`, `MoneyonTable`) into `ReplicatedStorage.BuildingTemplates.Building1.Manager` on server start, preventing premature rendering.
  * **Pop-In Slide Animation:** Extended `BuildingAnimatorClient.local.luau` to play `PivotTo()` slide-up spring animation on all manager props upon purchase ($250).
  * **NPC Animation Wired:** Added `PlayAnimation.server.luau` to the Manager's `Cult Member` model to loop `Getting Money Animation` upon spawn.

* **Authoritative Developer Console & Chat Command System:**
  * **Server-Side Whitelist Gatekeeper (`AdminServer.legacy.luau`):** Authoritative validation checking `player.UserId == game.CreatorId` (`51437187`), `ALLOWED_USER_IDS` whitelist, or `RunService:IsStudio()`.
  * **Command Suite & Suffix Parsing:** Supports `:give <amount>`, `:set <amount>`, `:reset`, `:unlockall`, `:unlockmanager <id>`, `:help` with short-scale suffix parsing (`10k`, `5M`, `1B`, `500T`, `100Qi`).
  * **Client Console UI (`AdminClient.local.luau`):** Added floating `⚙ DEV` top-right toggle button with `F4`, `;` (Semicolon), and `]` hotkeys.




