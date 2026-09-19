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
  * **Catalog Specification:** Published [`building_upgrades_catalog.md`]detailing 8 functional speed upgrades and intermediary cosmetic builds for all 10 tycoon buildings.

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

## September 12, 2026

* **Building 2 Full Progression Pipeline & Button Configurations:**
  * Configured 3D BillboardGuis for all 6 new Building 2 upgrades matching `building_upgrades_catalog.md`:
    * Step 6: `Donation Machine` -> Title: `"DONATION MACHINE"`, Price: `"$15.0M"`, Benefit: `"2x Speed"` ($15M, 0.375s cycle)
    * Step 7: `PosePosters` -> Title: `"WORSHIP POSTERS"`, Price: `"$1.225B"`, Benefit: `"2x Speed"` ($1.225B, 0.1875s cycle)
    * Step 8: `Shutter Door` -> Title: `"SHUTTER DOOR"`, Price: `"$14.0B"`, Benefit: `"2x Speed"` ($14.0B, 0.09375s cycle)
    * Step 9: `HVAC` -> Title: `"HVAC SYSTEM"`, Price: `"$875B"`, Benefit: `"2x Speed"` ($875B, 0.046875s cycle)
    * Step 10: `Cameras` -> Title: `"SECURITY CAMERAS"`, Price: `"$262.5T"`, Benefit: `"2x Speed"` ($262.5T, 0.0234375s cycle)
    * Step 11: `Money Safes` -> Title: `"MONEY SAFES"`, Price: `"$5.25Sx"`, Benefit: `"3x Speed"` ($5.25Sx, 0.0078125s cycle, triggers fast progress bar)
  * Extended `B2_CHAIN` in `BuildingProgressionServer.legacy.luau` across all 11 sequential steps with dynamic template stashing, touch unlocking, speed multiplier application via `MoneyManager`, and full join restoration.
  * Added all 6 stage mappings (`DonationMachineStage`, `PosePostersStage`, `ShutterDoorStage`, `HVACStage`, `CamerasStage`, `MoneySafesStage`) to `STAGE_FOLDER_MAP` in `BuildingAnimatorClient.local.luau` with smooth upwards slide-in pop animations.

* **Shutter Door Automatic Proximity Sensing:**
  * Automated `ElevatorDoor.Script` to open and close smoothly based on player proximity within $18\text{ studs}$ of the doorway.
  * Checks for ANY player character near the entrance; when any player is within range, raises slats upward and holds open. When all players leave range, automatically closes slats.
  * Disabled manual `ClickDetector` activations on `ElevatorButton` parts for a completely hands-free automatic entrance.

* **Dynamic 3D Full-Model R15 Pose Posters:**
  * Replaced 2D headshot flyers with high-definition 3D `ViewportFrame` poster displays across all 6 wall posters in the storage unit temple.
  * Dynamically spawns the player's full R15 avatar (`Players:CreateHumanoidModelFromUserId`) with full scaling, clothing, and accessories.
  * Programmed 6 distinct classic Roblox R15 poses across the posters:
    * Poster 1: Hero / Hands on Hips (`"THE LEADER"`)
    * Poster 2: Worship / Arms Raised Exaltation (`"WORSHIP"`)
    * Poster 3: The Thinker / Hand to Chin (`"VISION"`)
    * Poster 4: Crossed Arms Authoritative (`"AUTHORITY"`)
    * Poster 5: Pointing Forward Propaganda (`"OBEY"`)
    * Poster 6: Welcoming Greeting Wave (`"DEVOTION"`)

* **Storage Unit Addon Models Integrated into Base Stage:**
  * Added dynamic template stashing, purchase spawning, and join restoration in `BuildingProgressionServer.legacy.luau` for the 2 flanking `Storage Unit (addon)` models.
  * In `BuildingAnimatorClient.local.luau`, configured the addon models to pop in upwards from $Y - 6\text{ studs}$ ($1.2\text{s}$, `EasingStyle.Back`) alongside the main storage unit's directional shell assembly.

* **Shutter Door Full Clearance & 2x Additional Speedup:**
  * Diagnosed elevator door travel cutoff: original loop only traversed $7.45\text{ studs}$ out of the required $18.75\text{ studs}$ opening height, stopping the door halfway up at player head level.
  * Recalculated dynamic travel distance to $\approx 19.05\text{ studs}$ so all 19 slats travel completely above the doorway frame and turn transparent (`Transparency = 1`) and non-collidable (`CanCollide = false`), completely opening the passage.
  * Doubled opening and closing speed again (`ANIM_STEPS = 45`), completing the entire roll-up and roll-down sequence in $\approx 0.75\text{ seconds}$ ($\approx 25.4\text{ studs/s}$) for a snappy, responsive door feel.
  * Implemented initial CFrame caching to eliminate any floating-point positional drift over infinite open/close cycles.

* **Pose Posters Clean Avatar Display & PlayerGui Adornee Architecture:**
  * Diagnosed twin root causes of blank/white ViewportFrames during gameplay:
    1. `player.Character:Clone()` in Roblox broke accessory attachment welds on runtime characters with layered clothing, displacing the oversized Kanye West head and clothing handles $\approx 85\text{ studs}$ away in world space outside the camera view frustum.
    2. In Roblox, `SurfaceGui`s parented directly to a Part in `Workspace` cannot properly render secondary 3D render-to-texture targets (`ViewportFrame`), and server `Camera` objects do not replicate to clients, leaving `CurrentCamera` as `nil`.
  * Resolved by generating pristine, fully welded avatar models directly from the player's UserId (`Players:CreateHumanoidModelFromUserId(51437187)`), bringing all 326 parts (including the Kanye head, sweater, cargo pants, and sneakers) into exact alignment centered at $(0.0, 0.4, 0.0)$.
  * Implemented the proven **PlayerGui Adornee Architecture** in [`PosePosterClient.local.luau`]in `StarterPlayerScripts` (identical to the architecture in `CollectUpgradeClient`). The client creates each `SurfaceGui` inside `player.PlayerGui` with `Adornee = posterPart`, creates a local `CameraType = Scriptable` camera, and renders the 3D models natively on the client GPU.
  * **Upright Camera Roll (+90°):** Diagnosed that `SurfaceGui` on `NormalId.Top` mapped the camera's vertical axis horizontally (displaying the character lying sideways). Applied a $+90^\circ$ camera roll (`CFrame.Angles(0, 0, math.rad(90))`), orienting the avatar completely upright with the head at the top and feet at the bottom.
  * **Side & Border Padding:** Added $24\text{px}$ inset padding to `PoseViewport` (`Size = UDim2.new(1, -48, 1, -48)`, `Position = UDim2.new(0, 24, 0, 24)`) and adjusted camera framing distance to $10.5\text{ studs}$ ($FOV = 46^\circ$), providing generous, elegant side margins around the character.
  * All 6 wall posters now cleanly render the 3D player model in the 6 distinct standard R15 poses upright against the dark whitish background (`Color3.fromRGB(222, 224, 228)`) with zero text/words.

## September 13, 2026

* **Pose Posters Camera Zoom-Out (Full Avatar View Without Cutoff):**
  * Adjusted camera framing in [`PosePosterClient.local.luau`] and all 6 poster ViewportFrames in Roblox Studio.
  * Increased camera distance from $10.5\text{ studs}$ to $13.0\text{ studs}$ and widened Field of View to $48^\circ$ (`baseCF = CFrame.lookAt(Vector3.new(0, 0.2, 13.0), Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))`).
  * At $13.0\text{ studs}$, vertical visible height is $\approx 11.6\text{ studs}$, giving generous headroom and footroom so tall accessories (such as the oversized Kanye West head), outstretched arms (Worship pose), and shoes are displayed without any clipping.

* **Building 2 Purchase Simultaneous Animation Synchronization:**
  * Diagnosed visual artifact where the `Podium` and `Cult Member` were briefly visible hovering in empty space before the storage unit assembled, followed by buttons popping in seconds later.
  * In [`BuildingAnimatorClient.local.luau`], eliminated the `0.70s` interior props delay. Interior props (`Podium`, `Cult Member`, `CollectUpgradeGui`) now offset immediately to $Y - 4\text{ studs}$ on frame 0 and animate upwards ($1.2\text{s}$, `EasingStyle.Back`).
  * In [`BuildingProgressionServer.legacy.luau`], removed the `1.2s` delayed button reveal for the Caretaker (`ManagerButton`) and Step 1 (`Carpeting`).
  * As a result, the Building 2 outer shell, addon units, interior podium/member, and starting buttons all initiate their distinct animation cycles at the exact same moment ($t=0$) with zero lag between components.

* **Building 2 Stages Pop-In Animation Routing Fix:**
  * Diagnosed why `HVAC` and `Cameras` (along with `Donation Machine`, `PosePosters`, `Shutter Door`, and `Money Safes`) appeared instantly without pop-in animations.
  * In [`BuildingAnimatorClient.local.luau`], the `isB2` stage condition only explicitly listed the first 5 steps (`CarpetingStage` through `AltarStage`), causing all later steps to default to looking in Building 1's `StreetPreacherBuilding` where the folders didn't exist.
  * Added `DonationMachineStage`, `PosePostersStage`, `ShutterDoorStage`, `HVACStage`, `CamerasStage`, and `MoneySafesStage` to the `isB2` mapping, and added cross-building fallback discovery.
  * Synced updated script to Roblox Studio; all models (`HVAC`, `AC Vent`, 3x `Camera`, etc.) now properly slide and pop in from $Y - 4\text{ studs}$ ($1.2\text{s}$, `EasingStyle.Back`).

* **Boombox Tool Converted to Static World Model:**
  * Converted the `Boombox` object under `StorageUnitTempleBuilding.Boombox` from a player-equippable `Tool` into a standard, anchored `Model`.
  * Stripped legacy gear scripts (`Server`, `Client`), `RemoteEvent`, and `TouchTransmitter` that caused players to pick up the boombox into their inventory upon walking into it.
  * Configured `BoomboxPart` as the anchored primary part (`Anchored = true`, `CanCollide = true`), preserving its visual mesh and sound while allowing smooth slide-in animations.

* **Default Looped Background Music Active:**
  * Configured global ambient background music in `SoundService` using audio asset `rbxassetid://1840684529` (~2m06s ambient loop).
  * Set `Looped = true`, `Playing = true`, and default volume `0.35` for balanced background levels.
  * Added client controller [`MusicController.local.luau`] in `StarterPlayerScripts` to handle asset preloading via `ContentProvider:PreloadAsync`, smooth volume fade-in, and loop restart protection across joins.

* **Custom ReplicatedFirst Dynamic Loading Screen:**
  * Implemented [`LoadingScreenController.client.luau`] in `ReplicatedFirst`.
  * **Eliminated Sky Flash:** Parented `LoadingScreen` into `PlayerGui` on frame 0 *before* calling `ReplicatedFirst:RemoveDefaultLoadingScreen()`, ensuring zero gap where the raw 3D world sky is exposed.
  * **Eliminated Default Value & Font Flash:** Cleared default static `"0 / 0"` text and set `AssetsLoaded.TextTransparency = 1` initially; the script preloads the `FredokaOne` font glyphs via `ContentProvider:PreloadAsync({ assetsLabel })` and only reveals the counter once the real total count (759) and fonts are fully buffered into memory, preventing any raw text or fallback font flashes.
  * **Delayed Music Playback:** Set `SoundService.BackgroundMusic.Playing = false` by default; playback now begins with a smooth 1.5s fade-in precisely when the custom loading screen displays.
  * **Progress Bar:** Formatted `LoadingBar` with a dark crimson track (`Color3.fromRGB(80, 15, 22)`) and inner `ProgressFill` matching `CollectUpgradeGui`'s pre-fast bright red (`Color3.fromRGB(245, 45, 60)`).
  * **Replication-Aware Dynamic Asset Discovery:** Replaced premature `FindFirstChild` calls in `ReplicatedFirst` with replication-waiting for `CultTycoon` and `BuildingTemplates`, collecting all **983 downloadable asset IDs** (meshes, textures, decals, sounds, animations) across workspace and templates, ensuring the counter tracks the full game (`0/983` $\rightarrow$ `983/983`) instead of finishing early.
  * **Delayed Skip Button:** `SkipButton` starts invisible and smoothly fades in after 3.0 seconds, allowing players to skip at will.
  * **Logo Rocking Animation:** Continuous subtle oscillation ($-4.5^\circ$ to $+4.5^\circ$, `EasingStyle.Sine`) on the logo throughout loading.
  * **Slide-Up Exit Transition:** Upon completion or Skip click, smoothly slides the entire screen upwards past the top of the viewport (`Position = {0.5, 0}, {-0.65, 0}`) over 0.65s (`EasingStyle.Quart`) before destroying the GUI.

## September 17, 2026

* **Building 3 (Suburban House) Categorization & Ground-Up Construction Pipeline:**
  * **Systematic Spatial Sorting:** Categorized all 2,829 children of the imported flat `Suburban House` model into 14 distinct construction and room section folders following the *Sell Lemons* pacing standard:
    * `01_Foundation_and_Framing` (105 parts)
    * `02_Exterior_Walls_and_Windows` (687 parts)
    * `03_Roof_and_Chimney` (187 parts: main roof, garage roof gables/shingles, and porch roof overhangs consolidated)
    * `04_Front_Porch` (203 parts)
    * `05_Driveway_and_Garden` (100 parts/models)
    * `06_Staircase_and_Hallways` (120 parts: all 71 parts of the main floating wooden staircase relocated here)
    * `07_LivingRoom_Lounge` (50 parts: couch, cushions, coffee table, rug, fireplace & mantel)
    * `08_LivingRoom_Entertainment` (9 parts: TV media console, flat screen TV, audio)
    * `09_Dining_Room` (52 parts: table, 6 chairs, plates, fruit bowl)
    * `10_Kitchen_Suite` (253 parts: marble island, counters, fridge, stove/oven, sink, cabinets)
    * `11_Master_Bedroom` (343 parts: master bed, nightstands, dressers, artwork)
    * `12_Guest_Bedrooms` (324 parts: bedrooms 2 & 3 beds, desks, wardrobes)
    * `13_Bathroom` (182 parts: bathtub/shower, vanity sink, toilet, shampoo accessories)
    * `14_Garage_and_Car` (213 parts: garage structure, roll-up door, parked car & tools)
  * **Unified Roof & Chimney Architecture:** Re-routed all 50 garage roof parts (gables, wedges, shingle planks) and 23 front porch roof overhang/gable parts from the wall, garage, and porch folders into `03_Roof_and_Chimney`, unifying all roof structures across the building.
  * **Starter Overseer Station (`00_Starter_Overseer_Station`):** Created the initial purchase asset for `NewBuildingButton` positioned out front on the entrance walkway lawn (`{118, 7.5, -105}`) containing a clean wooden `WelcomeDesk`, `Cult Member` NPC, and `CollectUpgradeGui` (`BuildingId = "Building3"`), allowing income generation to start immediately from the ground up without player navigation friction.
  * **Toolbox Legacy Cleanup:** Purged 34 leftover free-model scripts (including sit/jump scripts and an unanchored infinite `while true do wait()` loop) and removed the leftover `ThumbnailCamera`, eliminating security capability issues and lag.
  * **Semantic Part-Level Labeling:** Analyzed all 2,828 parts and models using multi-dimensional heuristics (geometric aspect ratio, WedgeParts, physical dimensions, material types, decal IDs, and functional room context), transforming generic `"Part"`, `"Circle"`, and `"Triangle"` instances into descriptive names (e.g., `DiningTable_WoodTop`, `DiningTable_DinnerPlate`, `Entertainment_TVScreen`, `KitchenIsland_MarbleTop`, `Fireplace_HearthBase`, `MasterBed_Mattress`, `Bathtub_EnclosurePiece`, `Car_ChassisPlate`, `GarageDoor_RollUpSlat`).

* **Room Boundary Overhaul & Building 3 Catalog Integration:**
  * **Kitchen Suite Overhaul (`10_Kitchen_Suite`):** Stripped out 80 exterior back wall parts (brick walls, exterior red-framed windows, blinds, and shutters); recovered 28 checkered marble floor tiles, kitchen island (wood base & marble top), refrigerator, sink counter/faucet, east & south counters, cooktop range, microwave/oven station, upper cabinets, pantry, and ceiling lights (177 parts total, 0 brick walls).
  * **Dining Room Overhaul (`09_Dining_Room`):** Recovered the light-green oval floor rug (3 fabric parts), dining table & pedestals, 6 complete chairs (including 27 legs previously in exterior walls), 6 dinner plates, fruit bowl, pendant chandelier, and wall artwork (93 parts total).
  * **Staircase & Hallways Overhaul (`06_Staircase_and_Hallways`):** Reclaimed the red circular rug at the base of the stairs and 17 upper staircase components (top landing platform, upper support pillars, upper handrails, and landing balusters) previously clipped into the Master Bedroom, unifying all 92 staircase parts into a single continuous progression folder.
  * **2nd Floor & Building Shell Separation:** Cleaned `11_Master_Bedroom`, `12_Guest_Bedrooms`, and `13_Bathroom` of 210 exterior window, blind, shutter, and wall parts, routing all exterior elements cleanly into `02_Exterior_Walls_and_Windows` (1,225 parts total) and ensuring 0 exterior brick walls in any interior room folder.
  * **Building Upgrades Catalog Expansion (`building_upgrades_catalog.md`):** Replaced the 3-cosmetic placeholder with the full 24-step progression sequence for Building 3 (Suburban Compound) spanning from the $250M initial plot purchase, through 14 Ground-Up Construction cosmetic stages, 8 functional speed tiers ($384\times$ multiplier), the $5.0B Compound Overseer manager, and the $500B Gate to Building 4 (Community Hall).


## September 19, 2026

* **Server-Side Tutorial Progression & Welcome Badge (`TutorialServer.legacy.luau`):**
  * Configured `TutorialServer` to award Welcome Badge (`1830127030429571`) asynchronously upon player join via `BadgeService:AwardBadge`.
  * Implemented `TutorialInit` RemoteFunction querying `MoneyManager.GetBuildingState` and player balance to determine whether onboarding tutorial is active and which step to resume.

* **Client Onboarding Tutorial & Floating Banner UI (`TutorialController.local.luau`):**
  * Designed a 6-step player onboarding flow:
    1. Step 1: *"Buy your first building for your cult!"* (Targets free $0 starter `NewBuildingButton`)
    2. Step 2: *"Get closer and start clicking to earn money!"* (Targets `CollectUpgradeGui` stand)
    3. Step 3: *"Upgrade your cash flow!"* (Triggered at $16 cash balance; guides player to level up Building 1)
    4. Step 4: *"Keep getting money and buy your first speed upgrade!"* (Triggered at Level 2+; targets `Flyers` floor upgrade button)
    5. Step 5: *"Earn money and buy your first manager!"* (Triggered after buying Flyers; targets `Manager` button)
    6. Step 6: *"Well done, keep earning more money and grow your cult!"* (Displays completion congratulation, then cleanly fades out after 5s).
  * **Floating Center-Bottom Banner UI:** Positioned at `UDim2.new(0.5, 0, 1, -145)` in pure transparent container with FredokaOne font, black `UIStroke` (thickness 4.5), and scaled 25% larger (`UITextSizeConstraint.MaxTextSize = 68`, container height 110px).
  * **Step 1 Targeting Bug Resolution:** Fixed race condition where `initArrowNodes()` inadvertently called internal cleanup that wiped `activeTargetPart` to `nil` before the first frame rendered, restoring reliable Step 1 guidance.
  * **Respawn Persistence:** Added `localPlayer.CharacterAdded` connection to ensure guidance arrows seamlessly re-link upon character spawn or respawn.

* **Work at a Pizza Place Style Guidance Beam System (`TutorialController.local.luau`):**
  * Replaced discrete floating billboard triangles and yellow floor pads with a continuous ground-level Roblox `Beam` with repeating chevrons (`rbxassetid://705372919`, Road Chevron White).
  * **100% Flat Ground Alignment (`FaceCamera = false`):** Dynamically sets attachment surface normal straight up (`Axis = Vector3.new(0, 1, 0)`) and computes width vector as `SecondaryAxis = dir:Cross(up).Unit` every frame. This keeps the beam strictly flat on the ground plane like road paint markings, eliminating camera-tilt distortion while preventing the beam from collapsing into a thin line at side angles.
  * **Forward Chevron Direction & Flow:** Reassigned `Attachment0 = targetAttachment` (destination) and `Attachment1 = playerAttachment` (player origin) with `TextureSpeed = -3.0`, ensuring the chevron vertices point forward toward the objective (`>>>>>>`) and the animation scrolls outward from the player to the destination.
  * **Color & Transparency Gradient:** Vibrant cyan-green at the player's feet (`Color3.fromRGB(0, 235, 140)`), smoothly transitioning into bright mint and pure white at the destination, with subtle distance transparency fading.
  * **Flush Floor Raycasting:** Start and target anchors are pinned +0.08 studs above the floor surface to prevent z-fighting with the baseplate.
  * **Early Milestone Continuity:** Extended guidance beam continuously across Steps 1 through 5, seamlessly guiding the player from the free building button, to clicking the stand, to cash flow upgrade, to floor speed upgrade, to manager hire.

* **Building 3 Bunker Hatch Integration (`BuildingProgressionServer.legacy.luau` & `BuildingAnimatorClient.local.luau`):**
  * **Studio 3D PricingTag:** Updated `workspace.CultTycoon.Building3["Suburban Compound Building"]["Bunker Hatch"].UpgradeButton.PricingTag`:
    * Title: `"Bunker Hatch"`
    * Pricing: `"$375Qi"` ($375 Quintillion / `3.75e20`)
    * Benefit: `"2x Speed"`
  * **Server Progression Chain:** Inserted `Bunker Hatch` into `B3_CHAIN` at Step 19 (Speed Tier 7, Cost `$375Qi`, `UnlockId = "BunkerHatchStage"`), moving `Gates` to Step 20 (`$7.5Vg`, Speed Tier 8). The server dynamically stashes the hatch model and upgrade button, revealing them sequentially after `Watchtower` is purchased.
  * **Pop-In Slide Animation:** Mapped `["BunkerHatchStage"] = "Bunker Hatch"` in `BuildingAnimatorClient.local.luau` for spring pop-in upon purchase.

* **CollectUpgradeGui Canvas & Upgrade Cost Visibility Fix (`CollectUpgradeClient.local.luau`):**
  * **Root Cause Diagnostics:** Identified that scaling `CollectUpgradeGui` by 25% (`UIScale.Scale = 1.25`) expanded the inner `Container` height from 220px to 275px. Because `BillboardGui.Size` was left at `{0, 360}, {0, 220}`, `PriceText` (at $Y = 184\text{px}$) was scaled down to $Y = 230\text{px}$, pushing it past the 220px boundary and clipping the `$16` upgrade cost completely off the billboard.
  * **Expanded Billboard Canvas:** Resized `BillboardGui.Size` from `{0, 360}, {0, 220}` to `{0, 480}, {0, 290}` and `StudsOffset` to `Vector3.new(0, 4.5, 0)` across all buildings in Studio and enforced in `CollectUpgradeClient.local.luau`.
  * **Symmetric Centered Scaling:** Updated `Container.AnchorPoint` to `Vector2.new(0.5, 0.5)` and `Position` to `UDim2.new(0.5, 0, 0.5, 0)` so UI scaling radiates evenly from the center without pushing lower elements off the bottom.
  * **Guaranteed Text Rendering:** Enforced `Font = Enum.Font.FredokaOne`, `ZIndex = 5`, and `Visible = true` on `PriceText` during both initial setup and runtime `UpgradeSuccess` events, ensuring the upgrade cost is permanently visible right below the `UPGRADE [E]` button.

* **Early-Game Progression & Pacing Rebalance (Buildings 1–4):**
  * **Systematic Pacing Recalibration:** Eliminated progression stalls between Building 1 and Building 2, dropping maximum player downtime from >360 seconds down to <25 seconds.
  * **Base Parameters Rebalanced (`EconomyConfig.luau`):**
    * Building 1 (Street Preacher): $r = 1.10$, Base Prod = $2/cycle ($2.0/s), Manager = $250.
    * Building 2 (Storage Temple): Base Cost $30,000, $r = 1.12$, Base Prod = $3,600 ($1,200/s), Manager = $500,000 ($500K).
    * Building 3 (Suburban Compound): Base Cost $15,000,000 ($15M), $r = 1.13$, Base Prod = $1,500,000 ($250K/s), Manager = $150,000,000 ($150M).
    * Building 4 (Community Hall): Base Cost $10,000,000,000 ($10B), $r = 1.14$, Base Prod = $800,000,000 ($80M/s), Base Cycle Time = 10.0s, Manager = $100,000,000,000 ($100B).
  * **Sacred Dogma Bridges Configured:** Canonical 7-tier Dogma table added to `EconomyConfig.luau` with Tier I (*Sidewalk Pamphleteering*) at $4,000 (x5 Global) and Tier II (*Esoteric Wellness Alignment*) at $2,500,000 (x10 Global).
  * **Server Chains & Unlock Handlers Synchronized (`BuildingProgressionServer.legacy.luau`):**
    * Building 1: More Preachers ($500), Canopy Tents ($1,500), Megaphones ($8,500), Floor Chalk ($15,000).
    * Building 2: Unlock ($30,000), Carpeting ($45,000), Folding Chairs ($60,000), Microphone ($125,000), Boombox ($250,000), Caretaker Manager ($500,000), Altar ($750,000), Donation Machine ($5.0M), PosePosters ($75M), Shutter Door ($500M), HVAC ($2.5B), Cameras ($7.5B), Money Safes ($250B).
    * Building 3: Unlock ($15M), 20-step construction & speed chain smoothly scaled from $20M (Foundation) through Compound Overseer Manager ($150M) up to $100T (Gates Capstone) directly launching into Building 5 ($100T First Rebirth Gate).
  * **Roblox Studio 3D PricingTags Synchronized:** Updated all 39 physical billboard text labels across Buildings 1, 2, and 3 in the live Studio Edit session.

* **Manager Progression & Active Play Pacing Recalibration (Option B Selected):**
  * **Pacing Problem Solved:** Addressed feedback that managers were too cheap relative to building unlock costs (e.g. Building 2 manager at $75,000 allowed instant automated purchase within 2 taps after building purchase, bypassing manual operation).
  * **Strict Manager Cost Ratios Enforced:**
    * **Building 2 Caretaker:** Raised from $75,000 to **$500,000** (~$16.7\times$ base cost ratio, matching Building 1's $250 / $15 = 16.7x ratio). Requires ~45s of active manual clicking (~15–25 manual collections depending on upgrade level), creating a genuine active play phase that incentivizes purchasing earlier speed upgrades (Carpeting, Chairs, Microphone, Boombox) first.
    * **Building 3 Compound Overseer:** Raised from $45,000,000 to **$150,000,000 ($150M)** ($10\times$ base cost ratio).
    * **Building 4 Grand Reverend Director:** Raised from $35,000,000,000 to **$100,000,000,000 ($100B)** ($10\times$ base cost ratio).
  * **Code & Studio Sync:** Updated `EconomyConfig.luau`, `BuildingProgressionServer.legacy.luau`, documentation, and Studio 3D PricingTags (`$500K` for Caretaker, `$150M` for Compound Overseer).

