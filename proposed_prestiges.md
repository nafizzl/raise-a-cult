Here is the complete, consolidated PRD addendum incorporating the updated mathematical foundations, the progressive milestone scaling, the Tier-1 and Tier-2 prestige layers, and the newly introduced **Sacred Dogma ("Upgrade Fruit" equivalent)** system.

---

# PRD Addendum: Economy Scaling, Sacred Dogma & Multi-Tier Prestige

## 1. Updated Production & Economy Formulas

To ensure the game naturally bridges exponential cost jumps across 10 buildings while hitting a **10–15 hour F2P completion target**, each building's production stacks four multiplicative layers:

$$\text{CycleOutput} = \text{OwnedCount} \times \text{BaseProduction} \times \text{MilestoneMult} \times \text{DogmaMult} \times \text{Tier1Mult} \times \text{Tier2Mult}$$

$$\text{EffectiveIncomePerSec} = \frac{\text{CycleOutput}}{\text{CycleTime}}$$

Where:

* $\text{BaseProduction}$ and $\text{CycleTime}$ follow the building upgrade catalog values.


* $\text{MilestoneMult} = \prod (\text{Milestones Achieved for that specific building})$ (see Section 2).


* $\text{DogmaMult} = \text{Highest Unlocked Sacred Dogma Multiplier}$ (see Section 3).
* $\text{Tier1Mult} = 1 + (\text{EfficiencyRate} \times \text{TotalZealotPoints})$ (default $\text{EfficiencyRate} = 0.02$, upgradeable via Zealot Shop).


* $\text{Tier2Mult} = \prod (\text{Unlocked Eldritch Artifact Multipliers})$ (default $= 1$).

---

## 2. Progressive Ownership Milestone Scaling

Rather than locking milestone rewards to flat $2\times$ boosts indefinitely, higher unit tiers provide escalating multipliers to reward mass investment in earlier infrastructure:

| Milestone Count (Units Owned) | Output Multiplier per Step | Cumulative Multiplier (per building) |
| --- | --- | --- |
| **10**<br> | $\times 2$<br> | $\times 2$<br> |
| **25**<br> | $\times 2$<br> | $\times 4$<br> |
| **50**<br> | $\times 2$<br> | $\times 8$<br> |
| **100**<br> | $\times 2$<br> | $\times 16$<br> |
| **200**<br> | $\times 2$<br> | $\times 32$<br> |
| **500**<br> | $\times 2$<br> | $\times 64$<br> |
| **1,000** | $\mathbf{\times 5}$ | $\times 320$ |
| **2,500** | $\mathbf{\times 5}$ | $\times 1,600$ |
| **5,000** | $\mathbf{\times 10}$ | $\times 16,000$ |
| **10,000** | $\mathbf{\times 25}$ | $\times 400,000$ |
| **25,000+** (Every 25k) | $\mathbf{\times 100}$ | Escalating ($4 \times 10^7\dots$) |

---

## 3. Sacred Dogma Progression System (*"Upgrade Fruit"* Layer)

* **Concept:** Direct thematic equivalent to *Sell Lemons'* core fruit upgrade pipeline. Upgrading your Dogma evolves the cult's foundational belief system, permanently applying massive global multipliers to **all buildings simultaneously**.


* **Placement & UI:** Accessible via a prominent central podium button in the physical hub as well as a sticky top header in the main UI.
* **Persistence:** Resets on Tier-1 Schism, but serves as the primary intra-run cash sink that enables reaching the next building tier.



| Tier | Sacred Dogma Name | Cost (Followers) | Global Profit Multiplier | Progression Target / Pacing Role |
| --- | --- | --- | --- | --- |
| **I** | **Sidewalk Pamphleteering** | $\$4,000$ | **$\times 5$ Global** | Bridges Building 1 to Building 2 ($30\text{K}$) |
| **II** | **Esoteric Wellness Alignment** | $\$2,500,000$ | **$\times 10$ Global** | Powers through Building 2 into Building 3 ($15\text{M}$) |
| **III** | **Televangelical Mind-Lock** | $\$10\text{T}$ | **$\times 25$ Global** | Bridges the wall leading to Building 5 ($\$100\text{T}$)

 |
| **IV** | **Deep-State Shell Network** | $\$50\text{Qi}$ ($5 \times 10^{19}$) | **$\times 100$ Global** | Unlocks & accelerates Building 6 ($500\text{Qi}$)

 |
| **V** | **Sub-Crust Doomsday Prophecy** | $\$500\text{Oc}$ ($5 \times 10^{29}$) | **$\times 1,000$ Global** | Accelerates Buildings 7 & 8

 |
| **VI** | **Cosmic Anti-Gravity Transcendence** | $\$10\text{Tg}$ ($10^{94}$) | **$\times 100,000$ Global** | Major bridge for the Building 9 $\rightarrow$ 10 gap ($10^{65} \rightarrow 10^{185}$)

 |
| **VII** | **The Omniscient Hive-Mind** | $\$1\text{Og}$ ($10^{186}$) | **$\times 10^8$ Global** | Final booster to complete Building 10 Capstone ($\$50\text{Ns}$)

 |

---

## 4. Tier-1 Prestige: "Schism" (Rebirth for Zealot Points)

* **Unlock Threshold:** **$\$100\text{T}$ Lifetime Followers** (triggers upon reaching Building 5: *Wellness Retreat Ranch*).


* **Prestige Formula (Standard Square-Root):**

$$\text{ZealotPointsEarned} = \left\lfloor \sqrt{\frac{\text{LifetimeFollowersEarned}}{10^{12}}} \right\rfloor$$


* **Reset Scope:** Followers, Buildings, Managers, Base Speed Upgrades, and Dogma Tiers reset. Retains lifetime stats, permanent Zealot Points, and Zealot Shop purchases.



### 4.1 Zealot Shop Meta-Upgrades

Allows players to upgrade point efficiency directly:

| Upgrade Name | Cost (Zealot Points) | Effect |
| --- | --- | --- |
| **Zealot Fervor I** | 10 | Increases point bonus from $+2\%$ to $+3\%$ per point

 |
| **Zealot Fervor II** | 50 | Increases point bonus from $+3\%$ to $+4\%$ per point |
| **Zealot Fervor III** | 250 | Increases point bonus from $+4\%$ to $+6\%$ per point |
| **Zealot Fervor IV** | 1,500 | Increases point bonus from $+6\%$ to $+10\%$ per point |
| **Acolyte Automation** | 75 | Buildings 1–3 start pre-automated with managers on reset

 |
| **Global Tithe** | 500 | Flat $\times 3$ profit across all buildings |

---

## 5. Tier-2 Prestige: "Eldritch Ascension" (The Exponent Breaker)

* **Purpose:** Provides the necessary $10^5\times \dots 10^{15}\times$ multiplicative leaps required to conquer the late-game exponent gap ($10^{65} \rightarrow 10^{211}$).


* **Unlock Threshold:** **$\$10\text{Sp}$ ($10^{25}$) Lifetime Followers** (Building 7/8 era).


* **Currency Earned:** **Eldritch Tomes**

$$\text{EldritchTomesEarned} = \left\lfloor \log_{10}\left(\frac{\text{LifetimeFollowers}}{10^{25}}\right) \right\rfloor$$


* **Reset Scope:** Hard reset of Followers, Buildings, Managers, Dogma, and Tier-1 Zealot Points. Retains Eldritch Tomes and Ascension Artifacts.



### 5.1 Eldritch Tome Artifact Shop

| Tome Artifact | Cost (Tomes) | Multiplicative Effect |
| --- | --- | --- |
| **Cosmic Resonance** | 5 | **$\mathbf{\times 10^5}$** global output to all buildings |
| **Dimensional Tithing** | 15 | **$\mathbf{\times 10^8}$** global output to all buildings |
| **Pantheon Gateway** | 35 | **$\mathbf{\times 10^{15}}$** output boost to Buildings 8, 9, and 10

 |
| **Eternal Foundation** | 50 | Buildings 1–5 start permanently unlocked & automated

 |
| **Chrono-Distortion** | 75 | Reduces base cycle times of all buildings by flat $50\%$ |

---

## 6. End-to-End Pacing Roadmap (F2P Optimal)

| Stage | Active Runs | Primary Objective & Mechanics

 | Target Time |
| --- | --- | --- | --- |
| **Early Game** | Runs 1–5 | Push B1 $\rightarrow$ B5 ($\$0 \rightarrow \$100\text{T}$); buy Dogma I–III; first Schism at $\$100\text{T}$.

 | **1 – 1.5 hrs** |
| **Mid Game** | Runs 6–12 | Push B5 $\rightarrow$ B7 ($\$500\text{Qi} \rightarrow \$50\text{Sp}$); buy Dogma IV–V; upgrade Zealot Fervor to $+10\%$.

 | **2 – 3 hrs** |
| **Pre-Ascension** | Runs 13–18 | Reach B8 & B9 ($\$250\text{Td} \rightarrow \$500\text{Vg}$); unlock Dogma VI; trigger first **Ascension**.

 | **2.5 – 3.5 hrs** |
| **Ascension Era** | Runs 19–22 | Buy Artifacts ($10^5\times \dots 10^{15}\times$); run cycles back to B9 in minutes.

 | **2 – 3 hrs** |
| **Endgame Apex** | Runs 23–25 | Buy Dogma VII; unlock B10 ($\$500\text{Sg}$); complete Capstone ($\$50\text{Ns}$).

 | **2.5 – 4 hrs** |
| **Total Completion** | **~25 Resets** | **100% Construction & Capstone Finished**<br> | **10 – 15 hrs** |