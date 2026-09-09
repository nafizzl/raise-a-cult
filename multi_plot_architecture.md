# Multi-Plot & Multi-Player Tycoon Architecture

## 📌 Executive Summary
This document outlines the architectural roadmap to transition **Raise a Cult** from a single-plot developer environment into a scalable, multi-player tycoon experience where:
1. **Studio Edit Mode**: The `CultTycoon` model remains **100% visible, fully assembled, and editable** directly inside `Workspace`.
2. **Server Runtime**: The server clones `CultTycoon` into `ServerStorage` as a pristine **Master Template**, assigns independent plots to joining players, and clones unlocked props/buttons piece-by-piece per player.
3. **Cross-Player Visibility**: Players can walk over to neighboring plots to visually inspect other players' cult progress, while button touch collisions and interactive GUIs remain strictly isolated to the respective plot owner.

---

## 🎨 Studio Edit Mode vs. Server Runtime

| State | Workspace State | Behavior & Purpose |
| :--- | :--- | :--- |
| **Edit Mode (Studio)** | `workspace.CultTycoon` intact | All 10 upgrade stages, NPCs, props, and buttons remain fully rendered in 3D space. Allows uninterrupted building, positioning, texturing, and asset management. |
| **Server Runtime (`IsRunning`)** | Master Template cloned to `ServerStorage` | Server clones `CultTycoon` to `ServerStorage.TycoonMasterTemplate`. Workspace plots are stripped of unearned props and initialized with starter state. |
| **Playtest Teardown** | Automatic Studio Reversion | When stopping a playtest in Studio, Roblox automatically reverts the DataModel back to the edit-mode snapshot. |

---

## 🗺️ Plot Discovery & Placement

The multi-plot manager supports two layout workflows:

### Workflow A: Manual Plot Placement (Recommended for Map Design)
* In Studio, the developer duplicates `CultTycoon` across the map (e.g. `CultTycoon_1`, `CultTycoon_2`, `CultTycoon_3`, `CultTycoon_4` or inside a folder `Workspace.TycoonPlots`).
* Each plot can be rotated or positioned anywhere on the map (e.g., surrounding a central town square).
* The server detects all models matching `CultTycoon*` or having the attribute `IsTycoonPlot = true`.

### Workflow B: Automatic Procedural Spacing
* If only **1** `CultTycoon` is present in Workspace at runtime, the server automatically clones 3 additional plots spaced along the X-axis (e.g., $+120\text{ studs}$ offset per plot).
* Enables instant multi-player local testing without requiring manual layout work beforehand.

---

## 🔑 Plot Ownership & Data Model Attributes

Each plot model in Workspace is tagged with the following attributes:

```luau
plot:SetAttribute("IsTycoonPlot", true)
plot:SetAttribute("PlotId", plotIndex)        -- e.g. 1, 2, 3, 4
plot:SetAttribute("OwnerUserId", 0)           -- 0 = Unclaimed, > 0 = Player.UserId
plot:SetAttribute("OwnerName", "")            -- Player DisplayName / Name
```

### Player Join Lifecycle
1. When a player connects (`Players.PlayerAdded`), the server queries `MoneyManager` for saved data.
2. The server searches for an available plot (`OwnerUserId == 0`).
3. The plot is assigned:
   ```luau
   plot:SetAttribute("OwnerUserId", player.UserId)
   plot:SetAttribute("OwnerName", player.Name)
   ```
4. **Progression Restoration**:
   - If `OwnedCount == 0`: Spawns only `NewBuildingButton` ($0).
   - If `OwnedCount > 0`:
     - Clones Starter Props (`Table`, `Cult Member`, `CollectUpgradeGui`) from `MasterTemplate` into the plot.
     - Restores Manager props if hired, or reveals `ManagerButton` ($250).
     - Clones all owned sequential upgrade stages (Steps 1–10).
     - Clones and reveals the **first unowned step button** in the chain.

### Player Leave Lifecycle
1. When a player disconnects (`Players.PlayerRemoving`):
2. All owned props, members, and buttons are cleared from their plot.
3. Attributes are reset: `OwnerUserId = 0`, `OwnerName = ""`.
4. The plot spawns a fresh `NewBuildingButton` ($0), making it immediately claimable for new players.

---

## 🛡️ Button & GUI Security (Owner Isolation)

### 1. Physical Touch Buttons (`BuildingProgressionServer`)
Floor buttons verify ownership prior to executing any purchase or data mutation:
```luau
local function onButtonTouched(hit: BasePart, plot: Model, cost: number, unlockId: string)
    local character = hit:FindFirstAncestorWhichIsA("Model")
    if not character then return end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    -- Verify that the stepping player owns this specific plot
    if plot:GetAttribute("OwnerUserId") ~= player.UserId then
        return -- Ignore touches from visitors
    end

    -- Process authoritative purchase via MoneyManager
    if cost == 0 or MoneyManager.DeductMoney(player, cost) then
        -- Clone newly unlocked props from MasterTemplate to plot
        -- Fire pop-in animation to all clients
    end
end
```

### 2. Client Billboard GUIs (`CollectUpgradeClient`)
To keep screens clean and prevent cross-player interaction conflicts, `CollectUpgradeClient.local.luau` only attaches interactive BillboardGUIs to the local player's plot:
```luau
local function getPlotForPart(part: BasePart): Model?
    local current: Instance? = part
    while current and current ~= workspace do
        if current:IsA("Model") and (current:GetAttribute("IsTycoonPlot") or current.Name:match("^CultTycoon")) then
            return current :: Model
        end
        current = current.Parent
    end
    return nil
end

local plot = getPlotForPart(part)
if plot and plot:GetAttribute("OwnerUserId") ~= localPlayer.UserId then
    return -- Do not mount interactive collect/upgrade buttons on other players' plots
end
```

---

## 🎬 Universal Pop-In Animations (`BuildingAnimatorClient`)

When an upgrade is unlocked on any plot, the server fires:
```luau
UnlockStageEvent:FireAllClients(unlockName, targetPlot)
```
Clients receive the specific `targetPlot` and execute the slide-up pop animation on the newly spawned model inside that plot:
* All players in proximity see the props rise and settle into place smoothly.
* Uses the existing `PivotTo()` and `CFrameValue` tweening pipeline.

---

## 📋 Implementation Checklist (When Ready to Activate)

- [ ] **Step 1:** In `BuildingProgressionServer.legacy.luau`, clone `workspace.CultTycoon` into `ServerStorage.TycoonMasterTemplate` before modifying workspace.
- [ ] **Step 2:** Implement plot initialization loop to iterate over all `CultTycoon*` models and clear unowned parts.
- [ ] **Step 3:** Convert prop stashing/moving logic from `part.Parent = ReplicatedStorage` to `local clone = MasterTemplate[...]:Clone(); clone.Parent = plot[...]`.
- [ ] **Step 4:** Add `plot:GetAttribute("OwnerUserId") == player.UserId` check inside `setupTouchButton`.
- [ ] **Step 5:** Add plot ownership filter in `CollectUpgradeClient.local.luau` to only attach BillboardGUIs to the local player's plot.
- [ ] **Step 6:** Pass `targetPlot` in `UnlockStageEvent:FireAllClients` and update `BuildingAnimatorClient.local.luau` to animate models within `targetPlot`.
