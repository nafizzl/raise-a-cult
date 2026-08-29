# Project Context: Raise a Cult (Roblox Tycoon)

## 📌 Project Overview
**Raise a Cult** is an idle tycoon game inspired by *Adventure Capitalist* and *Sell Lemons* mechanics. Players grow a cult from a lone street preacher into a global movement, collecting cash, upgrading floor structures, unlocking milestone speed/output boosts, hiring managers for automation, and executing "Schism" prestige resets for Followers.

---

## 🏗️ Implemented Architecture & Systems

### 1. Centralized Economy Engine (`ReplicatedStorage.Economy`)
* **`EconomyConfig.luau`**: 
  * 10-Tier canonical building definitions (Building 1: Base Cost $4, Growth Rate 1.07, Base Yield $1, Cycle Time 1.0s, Manager Cost $100).
  * 8-Tier Floor Speed Upgrades curve ($3.5\times, 25\times, 200\times, 3,000\times, 85,000\times, 4.5\text{M}\times, 350\text{M}\times, 60\text{B}\times B_k$).
  * Extended Unit Milestone schedule (10, 25, 50, 100, 200, 500 ... 1,000,000+ units).
* **`EconomyMath.luau`**:
  * Pure geometric batch cost calculations and Buy Max formula.
  * Milestone output and speed multiplier engine with algorithmic scaling past 1,000,000.
  * 100-Tier continuous short-scale currency formatting (`K` through `Ce` Centillion, plus scientific notation past $10^{303}$).

### 2. Economy & Data Persistence (`MoneyManager.luau`)
* **Location:** `ServerScriptService.MoneyManager` (ModuleScript)
* **Functionality:** 
  * Full player tycoon state persistence (`DataStoreService` saving `Cash`, `LastSavedTimestamp`, and per-building `OwnedCount`, `FloorUpgrades`, and `HasManager`).
  * Implements **0.25x offline earnings** based on automated manager rates upon rejoin.
  * Provides in-memory fallback for local Studio playtests when DataStore API access is disabled.
  * Fires `MoneyUpdated` RemoteEvent to sync client HUDs instantly.

### 3. Production Engine (`ProductionEngine.luau`)
* **Location:** `ServerScriptService.ProductionEngine` (Script)
* **Functionality:**
  * Handles cycle calculation, yield math, and upgrade leveling.
  * Automated manager cycle loop and manual collect handlers.
  * **Fast-bar streaming:** When effective cycle time $\le 0.1\text{s}$, streams smooth batch income (10 Hz/1 Hz) to eliminate network lag.

### 4. Progression Pipeline & Floor Buttons (`BuildingProgressionServer.luau`)
* **Location:** `ServerScriptService.BuildingProgressionServer` (Script)
* **Functionality:**
  * Robust accessory touch detection via `hit:FindFirstAncestorWhichIsA("Model")`.
  * Per-player debounce table to eliminate cross-player interaction blocking.
  * Building 1 unlock progression:
    1. **`NewBuildingButton` ($0):** Spawns Table, Preacher, and CollectUpgradeGui.
    2. **`Flyers UpgradeButton` ($14):** Spawns `WorshipFlyers` posters on table + $2\times$ Speed.
    3. **`MorePreachers UpgradeButton` ($100):** Spawns extra cult members / `FriendNPC` + $2\times$ Speed.
    4. **`ManagerButton` ($100):** Hires manager for continuous automated collection.

### 5. Client 3D UI & Interaction (`CollectUpgradeClient.local.luau`)
* **Location:** `StarterPlayer.StarterPlayerScripts.CollectUpgradeClient` (LocalScript)
* **Architecture:** **PlayerGui Adornee Architecture** with Proximity Hysteresis
  * Clones 3D `BillboardGui`s into `Players.LocalPlayer.PlayerGui` and sets `Adornee = workspacePart`.
  * **Hysteresis Distance Check:** Pop-in at $\le 14$ studs, pop-out at $\ge 18$ studs to eliminate boundary flickering/collapsing.
  * **Live Countdown Timer:** Displays real-time frame-by-frame countdown ($1.0\text{s} \rightarrow 0.8\text{s} \rightarrow \text{"READY"}$).
  * **Fast-Bar Visual Mode:** Displays pulsing green animation and `"FAST"` text when cycle times $\le 0.1\text{s}$.
  * Tactile bounce animation on clicks and keyboard `[E]` shortcut.

### 6. Structure Slide-In Animator (`BuildingAnimatorClient.luau`)
* **Location:** `StarterPlayer.StarterPlayerScripts.BuildingAnimatorClient` (LocalScript)
* **Functionality:**
  * Standardized `PivotTo()` slide-up pop-in animation for purchased models/parts coming up from underneath the floor.

### 7. Custom Props & NPCs
* **`WorshipFlyers` Poster:** `SurfaceGui` with 0.9 margins, 90° rotation, `"WORSHIP"` header text, and paper-colored part (`RGB(245, 240, 225)`).
* **`FriendNPC` Script:** Dynamically fetches player friends via `Players:GetFriendsAsync()` and applies HumanoidDescription avatar, with fallback to default model.