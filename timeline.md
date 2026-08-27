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
