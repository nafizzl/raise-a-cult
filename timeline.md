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

* **Codebase Stability & Safeguards Audit:**
  * **Luau Static Require Modernization:** Resolved IDE/LSP static analysis errors (`TypeError: Unknown require: unsupported path`) across all server and client scripts by switching to static path indexing.
  * **Automated RemoteEvent Bootstrapping:** Configured `MoneyManager`, `ProductionEngine`, and `BuildingProgressionServer` to automatically initialize `ReplicatedStorage.RemoteEvents` (`MoneyUpdated`, `CollectEvent`, `UpgradeEvent`, `UnlockStage`) if missing, preventing infinite yield boot hangs.
  * **Disconnect Safety Guarding:** Added `player:IsDescendantOf(Players)` validation before all asynchronous `FireClient` calls to eliminate server errors when players disconnect mid-cycle.
  * **Respawn-Resilient HUD Sync:** Modernized `HUDController.local.luau` with dynamic `PlayerGui.HUD` lookup and `CharacterAdded` listeners to retain live balance synchronization across character respawns (`ResetOnSpawn = true`).
  * **Client Replication Race Handling:** Added timeout-based model resolution (`WaitForChild(..., 2)`) in `BuildingAnimatorClient.local.luau` to ensure slide-in pop animations never miss newly parented models during stage unlocks.

