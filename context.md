# Project Context: Raise a Cult (Roblox Tycoon)

## 📌 Project Overview
**Raise a Cult** is an idle tycoon game inspired by *Adventure Capitalist* mechanics. Players grow a cult from a lone street preacher into a global movement, collecting cash, upgrading floor structures, unlocking milestone speed boosts, hiring managers for automation, and executing "Schism" prestige resets for Followers.

---

## 🏗️ Implemented Architecture & Systems

### 1. Economy & Data Storage (`MoneyManager.luau`)
* **Location:** `ServerScriptService.MoneyManager` (ModuleScript)
* **Functionality:** 
  * Tracks player `$` Cash balance with persistent `DataStoreService` saving.
  * Implements **0.25x offline earnings** multiplier upon rejoin based on timestamp delta.
  * Provides in-memory fallback pcall for local Studio playtests when DataStore API access is disabled.
  * Fires `MoneyUpdated` RemoteEvent to sync client HUDs instantly.

### 2. Live Money HUD (`HUDController.luau`)
* **Location:** `StarterPlayer.StarterPlayerScripts.HUDController` (LocalScript)
* **Functionality:** 
  * Syncs `StarterGui.HUD.MoneyLabel` live with player cash balance.
  * Formats large cash amounts (`$0`, `$100`, `$1.5K`, `$2.4M`, `$3.8B`).

### 3. Production Engine & Milestone Scaling (`ProductionEngine.luau`)
* **Location:** `ServerScriptService.ProductionEngine` (Script)
* **Functionality:**
  * Handles cycle calculation, yield math, and upgrade leveling.
  * **Exponential Growth Formula:** Cost $= \text{BaseCost} \times (1.07)^{\text{Level}}$.
  * **2x Speed Boost Milestones:** 25, 50, 100, 200, and 500 total upgrades halve cycle times.
  * **Yield Multipliers:** 1,000, 2,500, 5,000, and 10,000 total upgrades grant $\times 2, \times 4, \times 10$ income boosts.
  * Fast-bar threshold: Cycles $\le 0.1\text{s}$ switch to instant green fill.

### 4. Progression Pipeline (`BuildingProgressionServer.luau`)
* **Location:** `ServerScriptService.BuildingProgressionServer` (Script)
* **Functionality:**
  * Manages sequential step-by-step floor unlocks for Building 1 (Street Preacher):
    1. **`NewBuildingButton` ($0):** Free initial unlock $\rightarrow$ spawns Table, Cult Member, and CollectUpgradeGui.
    2. **`Flyers UpgradeButton` ($100):** Unlocks `WorshipFlyers` posters on the table + 2x speed boost.
    3. **`MorePreachers UpgradeButton` ($500):** Unlocks extra cult members and `FriendNPC` + 2x speed boost.
    4. **`ManagerButton` ($10,000):** Hires manager for continuous automated collection.
  * Hides unbought models in `ReplicatedStorage.BuildingTemplates.Building1` on server startup.

### 5. Client 3D UI & Interaction (`CollectUpgradeClient.local.luau`)
* **Location:** `StarterPlayer.StarterPlayerScripts.CollectUpgradeClient` (LocalScript)
* **Architecture:** **PlayerGui Adornee Architecture**
  * Clones 3D `BillboardGui`s into `Players.LocalPlayer.PlayerGui` and sets `Adornee = workspacePart`. This guarantees 100% reliable 2D UI mouse clicks and screen taps in Roblox.
  * **Live Countdown Timer:** Displays real-time frame-by-frame countdown ($1.0\text{s} \rightarrow 0.8\text{s} \rightarrow 0.5\text{s} \rightarrow \text{"READY"}$) as the green bar fills.
  * **Pop-In / Pop-Out Animations:** Distance check (12–16 studs) triggers spring-tweened `UIScale` (`Back.Out` 0.25s pop-in, `Back.In` 0.18s pop-out).
  * **Tactile Bounce Feedback:** Buttons expand $\times 1.08$ on click before snapping back.
  * Keyboard keybind support (`[E]` for upgrade).

### 6. Structure Slide-In Animator (`BuildingAnimatorClient.luau`)
* **Location:** `StarterPlayer.StarterPlayerScripts.BuildingAnimatorClient` (LocalScript)
* **Functionality:**
  * Standardized `PivotTo()` slide-up pop-in animation for all purchased models/parts coming up from underneath the floor.

### 7. Custom Props & NPCs
* **`WorshipFlyers` Poster:** `SurfaceGui` with 0.9 margins, 90° rotation, `"WORSHIP"` header text, and paper-colored part (`RGB(245, 240, 225)`).
* **`FriendNPC` Script:** Dynamically fetches player friends via `Players:GetFriendsAsync()` and applies HumanoidDescription avatar, with fallback to default model.


NEED TO FIX:
- collectandupgradegui keeps "collapsing"
- floor buttons not working properly(?)