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

* **Full 11-Step Building 1 Sequential Upgrade & Model Spawning Chain:**
  * **11-Step Pipeline:** Configured and chained all sequential upgrades: `Buy Building ($0)` $\rightarrow$ `Manager ($250, Auto Collect)` immediately available alongside `Worship Flyers ($30)` $\rightarrow$ `More Preachers ($375)` $\rightarrow$ `Canopy Tents ($1,500)` $\rightarrow$ `Street Megaphones ($4,500)` $\rightarrow$ `FloorChalk ($10,000)` $\rightarrow$ `Outreach Booth ($525K)` $\rightarrow$ `Printed Booklets ($6.0M)` $\rightarrow$ `Speaker Towers ($375M)` $\rightarrow$ `LED Street Signs ($112.5B)` $\rightarrow$ `Holy Podium ($2.25Qa)`.
  * **Studio Billboard Styling:** Configured 3-tier billboards on all 11 buttons with FredokaOne Bold, custom Cyan/Lime/Magenta tints, benefit subtitles, and catalog pricing.
  * **Universal Slide-Up Pop-In Animation:** Extended `BuildingAnimatorClient.local.luau` with a universal stage-to-folder mapping to trigger `PivotTo()` spring pop-ins on all models across every upgrade.
  * **DataStore Persistence:** Updated `MoneyManager.luau` to serialize `PurchasedUpgrades` map, ensuring all 11 upgrades restore accurately upon rejoin.

* **Building 1 Asset Polish & Visual Refinements:**
  * **Holy Podium Statue (`AvatarScript.luau`):** Starts at `Transparency = 1` until avatar assets are fetched, then applies `2.0x` scaling on all body dimensions, cleans out residual cultist hood/mask props, anchors all parts, and rotates 180° forward onto the podium stand.
  * **Chalk Drawing Transparency & Alignment:** Set `FloorChalkDrawing.Transparency = 1` and rotated the chalk surface GUI by 90° so only the red chalk boundary and portrait render directly on the floor. Anchored all chalk cartons and sticks.
  * **Single-Faced Street Sign:** Attached `SurfaceGui` strictly to the front-facing `Right` face of `StreetSign` with unshaded lighting and portrait headshot.
  * **Interactive READY Progress Bar:** Configured manual progress bar to display 100% full bright red (`fill.Size = UDim2.new(1, 0, 1, 0)`) when idle/ready, and instantly sweep from 0% to 100% over the dark red track background when clicked.
  * **Smart Dynamic Time Units (`EconomyMath.FormatTime`):** Automatically switches from seconds (`every 0.25s`) to milliseconds (`every 63ms`, `every 3ms`, `every 2.6ms`), microseconds (`every 500μs`), and nanoseconds (`every 250ns`) when durations fall below $0.10\text{s}$.

* **Early-Game Pricing Curve Alignment (Buildings 1–4):**
  * **Smooth 15–45s Purchase Cadence:** Adjusted early-game speed upgrades and cosmetics for Buildings 1–4 to create a continuous progression flow, eliminating downtime on Run 1.
  * **Building 1 Adjusted Costs:** Updated `B1_CHAIN` and Studio billboards: Worship Flyers ($50), More Preachers ($600), Canopy Tents ($2.5K), Megaphones ($10K), and Floor Chalk ($50K).
  * **Base Unlock Realignment:** Updated `EconomyConfig.luau` with clean geometric tiers: Building 2 ($250K), Building 3 ($250M), and Building 4 ($500B), leading up to the Building 5 ($100T) First Rebirth Gate (Schism).
  * **Catalog & PRD Synchronized:** Updated `building_upgrades_catalog.md` and `proposed_prestiges.md` with the progressive milestone scaling and 7-tier Sacred Dogma pipeline.
* **Holy Podium PlayerModel Rig Assembly:**
  * Diagnosed disjointed R15 statue parts where the `HumanoidRootPart` was positioned on the podium stand (`-1.23, 5.99, -40.71`) while the anatomical mesh parts (`Head`, `Torso`, `Limbs`) were stranded 90 studs away near the test area (`14.1, 8.29, 48.02`).
  * Solved and aligned all 15 Motor6D joints to the `HumanoidRootPart` at the podium stand surface ($Y = 0.99\text{ studs}$), anchoring all limbs and restoring the complete avatar onto the podium.

* **Building 2 (Storage Unit Temple) UI, Directional Animation & Pipeline:**
  * **UI Configuration:** Configured `NewBuildingButton.PricingTag` (Benefit: `"New Building"`, Title: `"Storage Temple"`, Pricing: `"$250K"`) and `CollectUpgradeGui` (Title: `"STORAGE UNIT TEMPLE"`, Yield: `"$500"`, Timer: `"READY"`, Level: `"x1"`, Price: `"$282K"`). Removed obsolete `ClickDetector` and tagged `BuildingId = 2`.
  * **Custom Directional Assembly Animation:** Implemented world-space directional pop-in in `BuildingAnimatorClient.local.luau`:
    * `Ceiling` drops down from $+Y$ ($+10\text{ studs}$).
    * `Floor` pops up from $-Y$ ($-6\text{ studs}$).
    * `LeftWall` pops rightwards from $-X$ ($-8\text{ studs}$).
    * `RightWall` pops leftwards from $+X$ ($+8\text{ studs}$).
    * `FrontWall` & `BackWall` pop along $Z$ into place ($\pm 8\text{ studs}$).
    * `Light` drops down with bounce easing.
    * Staggered $0.35\text{s}$ interior pop-in for `Podium`, `Cult Member`, and `CollectUpgradeGui`.
  * **Server Pipeline Integration:** Added Building 2 base asset stashing to `ReplicatedStorage.BuildingTemplates.Building2`, wired `NewBuildingButton` ($250,000) touch handler, and added persistence restoration on player join in `BuildingProgressionServer.legacy.luau`.
  * **Building 2 Unlock Gate via FloorChalk ($50K):** Gated `NewBuildingButton` ($250,000) so it remains hidden in `ReplicatedStorage.BuildingTemplates.Building2` until `FloorChalk` (Sidewalk Chalk Circle) is purchased in Building 1. Purchasing `FloorChalk` simultaneously reveals the next Building 1 upgrade button (`OutreachBooth`, $525K) and triggers `Building2_ButtonReveal` to pop up Building 2's purchase button.

* **Animation Pacing Calibration (2x Slower):**
  * Doubled the slide-in pop animation duration for all Building 1 upgrades and base structures from $0.6\text{s} \to 1.2\text{s}$ using `EasingStyle.Back` in `BuildingAnimatorClient.local.luau`.
  * Slowed down the Building 2 Storage Unit directional shell assembly from $0.55\text{s} \to 1.1\text{s}$ (ceiling light to $1.3\text{s}$), and doubled the interior props stagger delay from $0.35\text{s} \to 0.70\text{s}$ ($1.2\text{s}$ duration).

* **Universal Button Pop-In Animations:**
  * Added `animateButtonPopIn()` in `BuildingAnimatorClient.local.luau`, animating the button pad and 3D pricing tag smoothly upwards from $Y - 3\text{ studs}$ over $1.0\text{s}$ (`EasingStyle.Back`).
  * Updated `showButtonForStep` and `showManagerButton` in `BuildingProgressionServer.legacy.luau` to broadcast `ButtonReveal_<FolderName>` to active purchasing players during gameplay, while keeping join restoration instant without redundant animations.

* **Zero-Flicker GUI Registration (Studio Edit Mode Preserved):**
  * Preserved full visibility and editing workflow by keeping all physical `BillboardGui`s permanently `Enabled = true` in Roblox Studio Edit Mode and on the server.
  * Implemented instant event-driven client suppression in `CollectUpgradeClient.local.luau` using `workspace.DescendantAdded` to set physical `BillboardGui.Enabled = false` locally as soon as buttons replicate to the client.
  * Cloned `PlayerGui` adornees are initialized with `Enabled = false` and `UIScale.Scale = 0`, immediately testing proximity against the player character to eliminate the split-second faraway GUI flash when new buttons are revealed.

## September 11, 2026

* **Collect & Upgrade GUI Clean-Up (Robux Speed Button Removal & Centered Title):**
  * Removed the yellow Robux speed boost button (`RobuxBoostButton`) from the top right of `CollectUpgradeGui` across the workspace template, Building 1 (`StreetPreacherBuilding`), and Building 2 (`StorageUnitTempleBuilding`).
  * Expanded `BuildingTitle` to span the full 360px container width (`Size = UDim2.new(1, 0, 0, 36)`, `Position = UDim2.new(0, 0, 0, 0)`), centered its alignment (`TextXAlignment = Center`), and increased font size from `20` to `24` with its black `UIStroke` intact.

* **Fast-Bar Seamless Barber-Pole Animation (Industry-Standard Tiled ImageLabel Architecture):**
  * Transitioned from procedural rotated frame containers to an industry-standard barber-pole implementation using an inner `ImageLabel` (`rbxassetid://17150049935`, AssetTypeId 1 Image) with `ScaleType = Enum.ScaleType.Tile` (`TileSize = UDim2.new(0, 40, 1, 0)`) nested inside the clipped `FastBarOverlay` (`CanvasGroup`, `CornerRadius = 13`).
  * Set the `ImageLabel` dimensions to $100\% + 1\text{ tile width}$ (`Size = UDim2.new(1, 40, 1, 0)`) and initial position offset left by 1 tile width (`Position = UDim2.new(0, -40, 0, 0)`).
  * Implemented an infinite linear looping tween via `TweenService` translating from `UDim2.new(0, -40, 0, 0)` to `UDim2.new(0, 0, 0, 0)` over $0.35\text{s}$ (`Speed = ~114px/s`).
  * Because the image is continuously rendered across the entire width $+40\text{px}$ and shifts right by exactly one tile width, the looping cut point is mathematically identical to the starting frame, completely eliminating any right-side gaps, early stripe cutoffs, or stutter.
  * Maintained strict $1\text{px}$ container inset (`Position = UDim2.new(0, 1, 0, 1)`, `Size = UDim2.new(1, -2, 1, -2)`) within the 3px black `UIStroke` border, with `ProgressFill` hidden during fast-bar mode.
* **Simulator Lighting Architecture Applied:**
  * Configured studio lighting to the industry-standard simulator recipe: `GlobalShadows = false`, `Ambient = Color3.fromRGB(150, 150, 150)`, `OutdoorAmbient = Color3.fromRGB(150, 150, 150)`, `Brightness = 2.2`, and `ClockTime = 14.0`.
  * Added `ColorCorrectionEffect` with `Saturation = 0.2` and `Contrast = 0.08` for vibrant arcade colors without washed-out highlights.
  * Disabled `DepthOfFieldEffect` and reduced `Atmosphere.Density = 0.15` to ensure all tycoon plots, buttons, and buildings stay razor-sharp at any camera distance.

* **Collect & Upgrade GUI 25% Scale Enlargement & Tighter Render Distance:**
  * Scaled all `CollectUpgradeGui` instances up by 25% (`UIScale.Scale = 1.25`) across the workspace template, Building 1, and Building 2, and raised `StudsOffset` from `3.5` to `4.2` studs for clean clearance above stands/podiums.
  * In `CollectUpgradeClient.local.luau`, configured `setGuiState` to tween `UIScale.Scale` to `1.25` on proximity for `CollectUpgradeGui`.
  * Slightly reduced the render distance thresholds (`COLLECT_IN_DIST = 5.5`, `COLLECT_OUT_DIST = 7.5`, down from 7 and 9) to keep the screen uncluttered when players walk around the plot.

* **Building 2 Upgrade Pipeline, Button GUI Displays & Pop-In Animations:**
  * Configured all 6 button 3D Billboard GUIs under `StorageUnitTempleBuilding` based on the design sequence catalog:
    * Step 1: `Carpeting` (Cosmetic) -> Title: `"CARPETING"`, Price: `"$350K"`, Benefit: `""` ($350,000)
    * Step 2: `Folding Chairs` (Speed 1) -> Title: `"FOLDING CHAIRS"`, Price: `"$500K"`, Benefit: `"2x Speed"` ($500,000, 1.5s cycle)
    * Step 3: `Microphone` (Cosmetic) -> Title: `"MICROPHONE"`, Price: `"$1.0M"`, Benefit: `""` ($1,000,000)
    * Step 4: `Boombox` (Speed 2) -> Title: `"BOOMBOX"`, Price: `"$1.75M"`, Benefit: `"2x Speed"` ($1,750,000, 0.75s cycle)
    * Step 5: `Manager` (Caretaker) -> Title: `"CARETAKER"`, Price: `"$2.5M"`, Benefit: `"Auto Collect"` ($2,500,000, automated collection)
    * Step 6: `Altar` (Cosmetic) -> Title: `"CINDERBLOCK ALTAR"`, Price: `"$5.0M"`, Benefit: `""` ($5,000,000)
  * Integrated full progression pipeline in `BuildingProgressionServer.legacy.luau`:
    * Configured the **Caretaker (Manager)** button ($2.5M) to be available immediately from the start upon unlocking Building 2, alongside Step 1 (`Carpeting`), matching Building 1's manager structure.
    * Defined `B2_CHAIN` (5 sequential steps: Carpeting $350K -> Folding Chairs $500K -> Microphone $1.0M -> Boombox $1.75M -> Cinderblock Altar $5.0M).
    * Server stashes unpurchased Building 2 assets and buttons in `ReplicatedStorage.BuildingTemplates.Building2` at startup, keeping Studio Edit mode fully intact.
    * Wired touch pads for all 6 buttons, triggering stage reveals, speed upgrades, manager auto-collection, and data persistence via `MoneyManager`.
    * Implemented player join restoration for Building 2 upgrades, Caretaker state, and active step button.
  * Enhanced `BuildingAnimatorClient.local.luau`:
    * Added Building 2 stages (`CarpetingStage`, `FoldingChairsStage`, `MicrophoneStage`, `BoomboxStage`, `Building2_ManagerStage`, `AltarStage`) to `STAGE_FOLDER_MAP`.
    * Added universal upwards pop-in animation (`animateModelSlideIn`, $1.2\text{s}$, `EasingStyle.Back`) supporting `Model`, `BasePart` (MeshParts, Unions), and `Tool` (PVInstance).
* **Developer Console `:unlockall` Command Removal:**
  * Removed `:unlockall` command from `AdminServer.legacy.luau` and its reference in `:help`.
  * Updated `AdminClient.local.luau` placeholder text to `Type command (e.g. :give 1M, :set 50B, :help)...`.
  * Updated system documentation in `context.md`.
