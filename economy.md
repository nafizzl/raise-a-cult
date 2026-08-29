# **Raise a Cult — Mathematical Economy & Systems Specification**

This document defines the mathematical models, pacing formulas, multi-tier prestige architecture, and large-number engine design for *Raise a Cult*, balanced in the style of *Sell Lemons* and *Adventure Capitalist*.

## **1\. Core Currency & Production Formulas**

### **1.1 Base Production & Cycle Rate**

For any building $k$, total income per completed cycle is governed by owned count, milestone multipliers, purchased cash upgrades, and prestige layers:

$$\\text{IncomePerCycle}\_k \= \\text{Owned}\_k \\times \\text{BaseProd}\_k \\times M\_k \\times U\_k \\times P\_{\\text{global}} \\text{\[cite: 1\]}$$  
Where:

* $\\text{BaseProd}\_k$ \= Base Followers generated per unit per cycle.  
* $M\_k$ \= Compound milestone multiplier for building $k$ ($2^{m}$ output scaling).  
* $U\_k$ \= Product of all purchased cash upgrades for building $k$.  
* $P\_{\\text{global}}$ \= Total active multiplier across all prestige tiers.

Effective cycle duration is modified by speed milestones and speed upgrades:

$$\\text{EffectiveCycleTime}\_k \= \\frac{\\text{BaseCycleTime}\_k}{S\_{\\text{milestone}, k} \\times S\_{\\text{purchased}}}$$

$$\\text{IncomePerSecond}\_k \= \\frac{\\text{IncomePerCycle}\_k}{\\text{EffectiveCycleTime}\_k} \\text{\[cite: 1\]}$$

### **1.2 Building Purchase Cost (Geometric Series)**

Building purchase costs scale exponentially with the number of units already owned:

$$\\text{Cost}(n) \= \\text{BaseCost} \\times r^n \\text{\[cite: 1\]}$$  
Where $n$ is the 0-indexed count of currently owned units, and $r$ is the building's cost growth rate ($r \> 1$).

#### **Batch Cost Formula (Buy 10, Buy 100, Buy $m$)**

The sum of a geometric series calculates the exact cost to buy $m$ units starting from $n$ owned:

$$\\text{BatchCost}(n, m) \= \\text{BaseCost} \\times r^n \\times \\frac{r^m \- 1}{r \- 1} \\text{\[cite: 1\]}$$

#### **Buy Max Formula**

Given a current balance of Followers $C$, the maximum number of units $m$ purchasable is:

$$m \= \\left\\lfloor \\frac{\\ln\\left(1 \+ \\frac{C \\times (r \- 1)}{\\text{BaseCost} \\times r^n}\\right)}{\\ln(r)} \\right\\rfloor$$

## **2\. The 10-Tier Elevated "Sell Lemons" Economy Table**

To ensure progress requires multiple prestiges and prevents reaching endgame buildings on early runs, cost scaling between tiers jumps by up to $10,000\times$ to $10^7\times$, while base cycle times increase to create heavy, high-reward payouts:

| \# | Building Name | Base Cost ($B_k$) | Growth Rate ($r$) | Base Prod / Cycle | Base Cycle Time | Manager Cost | Progression Barrier |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **1** | **Street Corner Preacher** | **$0** (Unit 1: **$15**) | **1.12** | **$1** | $1.0\text{s}$ | **$250** | 0–3 min (Active tapping) |
| **2** | **Storage Unit Temple** | **$35,000** | **1.13** | **$500** | $3.0\text{s}$ | **$2.5\text{M}$** | 3–8 min |
| **3** | **Suburban Compound** | **$50\text{M}$** ($5 \times 10^7$) | **1.14** | **$250,000** | $6.0\text{s}$ | **$5\text{B}$** | 10–25 min |
| **4** | **Community Hall** | **$50\text{B}$** ($5 \times 10^{10}$) | **1.15** | **$200\text{M}$** | $12.0\text{s}$ | **$50\text{T}$** | 30–60 min (**Pre-Schism Wall**) |
| **5** | **Wellness Retreat Ranch** | **$100\text{T}$** ($10^{14}$) | **1.16** | **$350\text{B}$** | $24.0\text{s}$ | **$250\text{Qa}$** | Requires **Schism 1** (Zealots) |
| **6** | **Merch & Media Wing** | **$500\text{Qi}$** ($5 \times 10^{20}$) | **1.17** | **$2\text{Qa}$** | $45.0\text{s}$ | **$1\text{Sx}$** | Requires **Schism 2–3** |
| **7** | **Pirate Radio/TV Broadcast** | **$50\text{Sp}$** ($5 \times 10^{25}$) | **1.18** | **$150\text{Qi}$** | $90.0\text{s}$ | **$250\text{Oc}$** | Requires **Reformation 1** (Souls) |
| **8** | **Underground Bunker Complex** | **$250\text{Td}$** ($2.5 \times 10^{44}$) | **1.19** | **$10\text{Sp}$** | $180.0\text{s}$ | **$50\text{Qd}$** | High Reformation Tier |
| **9** | **Shell Corporation Network** | **$500\text{Vg}$** ($5 \times 10^{65}$) | **1.20** | **$50\text{Td}$** | $360.0\text{s}$ | **$100\text{Tg}$** | Requires **Ascension Layer** |
| **10**| **Global Mega-Temple HQ** | **$500\text{Sg}$** ($5 \times 10^{185}$) | **1.21** | **$5\text{Vg}$** | $720.0\text{s}$ | **$50\text{Ns}$** ($5 \times 10^{211}$) | Endgame Pantheon Meta |

## **3\. Upgrades Architecture & Pricing**

┌────────────────────────────────────────────────────────────────────────┐  
│                          UPGRADE TAXONOMY                              │  
├───────────────────┬───────────────────────────┬────────────────────────┤  
│ Category          │ Trigger / Mechanism       │ Impact                 │  
├───────────────────┼───────────────────────────┼────────────────────────┤  
│ Unit Milestones   │ Unit count thresholds     │ 2x/4x/8x Output Only   │  
│ Floor Upgrades    │ Purchased Floor Buttons   │ 2x Faster Cycle Time   │  
│ Global Speed I-V  │ Purchased with Followers  │ 10% Cycle Reduction    │  
└───────────────────┴───────────────────────────┴────────────────────────┘

### **3.1 Unit Milestones (Automatic Unlocks - Output Multipliers Only)**

Milestones reward horizontal level expansion with geometric output multipliers ($2\times, 4\times, 8\times \dots$). Under the **Combined Economy Model**, milestones strictly boost **Dollar Yield per Cycle** (`OutputMult`), leaving cycle acceleration exclusively to physical floor upgrade buttons to eliminate premature speed collapse:

| Units Owned | Output Multiplier ($M_k$) | Speed Divisor ($S_{\text{milestone},k}$) | Cumulative Output Boost |
| :--- | :--- | :--- | :--- |
| **10** | $\times 2$ | $1.0\times$ | **$2\times$ Income / Cycle** |
| **25** | $\times 2$ | $1.0\times$ | **$4\times$ Income / Cycle** |
| **50** | $\times 2$ | $1.0\times$ | **$8\times$ Income / Cycle** |
| **100** | $\times 2$ | $1.0\times$ | **$16\times$ Income / Cycle** |
| **200** | $\times 4$ | $1.0\times$ | **$64\times$ Income / Cycle** |
| **500** | $\times 8$ | $1.0\times$ | **$512\times$ Income / Cycle** |
| **1,000** | $\times 16$ | $1.0\times$ | **$8,192\times$ Income / Cycle** |
| **2,000** | $\times 32$ | $1.0\times$ | **$262,144\times$ Income / Cycle** |
| **5,000** | $\times 64$ | $1.0\times$ | **$16.7\text{M}\times$ Income / Cycle** |
| **10,000+** | $\dots$ algorithmic scaling | $1.0\times$ | Scaling up to Centillion |

### **3.2 Purchased Building Upgrades (Followers / Floor Buttons - Speed Multipliers Only)**

Inspired by the cross-tier progression curve in *Sell Lemons*, floor upgrades **scale exponentially across subsequent building tiers**. This allows players to unlock new buildings before finishing earlier building upgrades, creating a satisfying loop where players return to max out older buildings using high-tier income.

Each building has **8 physical floor upgrades** applied **strictly to cycle speed** ($2\times$ faster for Tiers 1–7, $3\times$ faster for Tier 8 $\implies \mathbf{384\times}$ total speed divisor):

| Tier | Pricing Multiple ($B_k$) | Building 1 Cost ($B_1 = \$15$) | Building 2 Cost ($B_2 = \$35\text{K}$) | Effect on Cycle Time | Cumulative Speed Divisor | Target Unlock Phase |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Upgrade 1** | $2.0 \times B_k$ | **$30** | **$70,000** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $2\times$ ($0.5\text{s}$) | Early Building 1 |
| **Upgrade 2** | $25 \times B_k$ | **$375** | **$875,000** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $4\times$ ($0.25\text{s}$) | Pre-Building 2 Unlock |
| **Upgrade 3** | $300 \times B_k$ | **$4,500** | **$10.5\text{M}$** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $8\times$ ($0.125\text{s}$) | Approaching Building 2 |
| **Upgrade 4** | $35,000 \times B_k$ | **$525,000** | **$1.225\text{B}$** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $16\times$ ($0.0625\text{s}$) | Mid Building 2 |
| **Upgrade 5** | $400,000 \times B_k$ | **$6.0\text{M}$** | **$14.0\text{B}$** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $32\times$ ($0.03125\text{s}$) | Approaching Building 3 ($50\text{M}) |
| **Upgrade 6** | $25\text{M} \times B_k$ | **$375\text{M}$** | **$875\text{B}$** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $64\times$ ($0.0156\text{s}$) | Mid Building 3 |
| **Upgrade 7** | $7.5\text{B} \times B_k$ | **$112.5\text{B}$** | **$262.5\text{T}$** | $\mathbf{2\times\text{ Speed}}$ (Time / 2) | $128\times$ ($0.0078\text{s}$) | Approaching Building 4 ($50\text{B}) |
| **Upgrade 8 (Final)**| **$150\text{T} \times B_k$** | **$2.25\text{Qa}$** | **$5.25\text{Sx}$** | $\mathbf{3\times\text{ Speed}}$ (Time / 3) | **$384\times$** ($0.0026\text{s}$) | Late-Game Overdrive ($50\text{Ns}$ on B10) |

*Total combined speed boost from all 8 purchased floor upgrades: $2^7 \times 3 = \mathbf{384\times \text{ Speed Divisor}}$ (Base Cycle Time divided by 384).*

### **3.3 Cross-Tier Progression Synergy (Building 1 vs Buildings 2 & 3)**

| Progression Milestone | Building 1 (Street Preachers) | Building 2 (Storage Unit Temple) | Building 3 (Suburban Compound) | Synergistic Optimal Decision |
| :--- | :--- | :--- | :--- | :--- |
| **Early Game ($0–$1,000)** | Level 1–10 ($1 $\to$ $20/cycle) | Locked | Locked | Buy **Flyers ($30)**, Manager ($250), Preachers ($375) |
| **Early-Mid ($1,000–$50,000)** | Level 25 ($100/cycle @ 0.25s) | Locked | Locked | Buy **Megaphones ($4,500)**, unlock **Building 2 ($35,000)** |
| **Mid Game ($50K–$100M)** | Level 50 ($400/cycle @ 0.125s) | Level 25 ($2,000/cycle @ 1.5s) | Locked | Level Building 2, unlock **Suburban Compound ($50\text{M})** |

### **3.4 Global Speed Upgrades (Followers)**

Global upgrades reduce cycle duration across all 10 buildings multiplicatively:

$$\\text{CycleTime}\_{\\text{new}} \= \\text{CycleTime}\_{\\text{old}} \\times 0.9 \\text{\[cite: 1\]}$$

* **Recruitment Speed I:** Cost $500,000$

* **Recruitment Speed II:** Cost $25\\text{M}$  
* **Recruitment Speed III:** Cost $1.5\\text{B}$  
* **Recruitment Speed IV:** Cost $100\\text{T}$  
* **Recruitment Speed V:** Cost $10\\text{Qi}$

## **4\. Multi-Layer Prestige Mechanics**

┌────────────────────────────────────────────────────────────────────────┐  
│                        PRESTIGE LAYER CASCADE                          │  
├────────────────────────────────────────────────────────────────────────┤  
│ Layer 1: Schism (Followers → Zealot Points)                            │  
│   └─ Formula: floor( sqrt( LifetimeFollowers / 1e9 ) )                 │  
│   └─ Gate: 1st Zealot Point \= 1 Billion Lifetime Followers             │  
│   └─ Multiplier: \+2% production per point (Additive)                   │  
├────────────────────────────────────────────────────────────────────────┤  
│ Layer 2: Reformation (Zealots → Heretic Souls)                         │  
│   └─ Formula: floor( (LifetimeZealots / 1e5) ^ 0.4 )                   │  
│   └─ Gate: 1st Soul \= 100,000 Lifetime Zealots                         │  
│   └─ Multiplier: \+10% Zealot gain \+ un-resettable automation           │  
├────────────────────────────────────────────────────────────────────────┤  
│ Layer 3: Dogma / Pantheon (Souls → Relics / "Fruit" Meta)              │  
│   └─ Formula: floor( log10( LifetimeSouls / 1,000 ) ) \+ 1             │  
│   └─ Gate: 1st Relic \= 1,000 Lifetime Souls                            │  
│   └─ Meta Effect: Alters cost base r, unlocks exponent scaling         │  
└────────────────────────────────────────────────────────────────────────┘

### **4.1 Layer 1: Schism (Zealot Points)**

Resets current Followers, Buildings, and Managers.

* **Minimum Gate for 1st Point:** $1,000,000,000$ ($10^9$) Lifetime Followers.  
* **Point Formula:**  
  $$\\text{ZealotsClaimable} \= \\left\\lfloor \\sqrt{\\frac{\\text{LifetimeFollowers}}{10^9}} \\right\\rfloor \\text{\[cite: 1\]}$$  
* **Bonus Formula:**  
  $$P\_{\\text{Zealot}} \= 1 \+ (0.02 \\times \\text{TotalZealots}) \\text{\[cite: 1\]}$$  
  *(e.g., $100\\text{ Zealots} \= \+200\\%$ Global Multiplier \[$3.0\\times$ output\]).*

### **4.2 Layer 2: Reformation / Ascension (Heretic Souls)**

Resets Followers, Buildings, Managers, and Zealot Points.

* **Minimum Gate for 1st Soul:** $100,000$ ($10^5$) Lifetime Zealot Points (requires $\\approx 10^{19}$ Lifetime Followers).  
* **Soul Formula:**  
  $$\\text{SoulsClaimable} \= \\left\\lfloor \\left(\\frac{\\text{LifetimeZealots}}{10^5}\\right)^{0.4} \\right\\rfloor$$  
* **Soul Multipliers & Perks:**  
  * **Zealot Generation Surge:** $+10\\%$ bonus Zealot Points earned per Schism per Soul.  
  * **Divine Mandate:** Each Soul grants a flat $+50\\%$ global production multiplier (compounded with Zealot bonuses).  
  * **Persistent Automation:** Unlocks permanent managers that never reset on Schisms.

### **4.3 Layer 3: Dogma / Pantheon (Relics / Meta Alterations)**

Resets all prior layers (Followers, Buildings, Zealots, and Souls).

* **Minimum Gate for 1st Relic:** $1,000$ Lifetime Souls.  
* **Relic Formula:**  
  $$\\text{RelicsClaimable} \= \\max\\left(0, \\left\\lfloor \\log\_{10}\\left(\\frac{\\text{LifetimeSouls}}{100}\\right) \\right\\rfloor\\right)$$  
* **Core Math Alterations (Purchased in Pantheon Shop):**  
  1. **Heretical Geometry:** Reduces growth rates $r$ across all buildings by a flat $-0.005$ (e.g., $1.07 \\to 1.065$). In a geometric series $r^{2000}$, this lowers late-game building costs by factors of $10^{40}+$.  
  2. **Exponential Zeal:** Converts lifetime follower count into a direct exponent multiplier on production:  
     $$\\text{ExponentBonus} \= \\text{Followers}^{0.02}$$  
  3. **Infinity Compression:** Unlocks progression beyond $10^{100}$, scaling up through $10^{210}$ (Novemsexagintillion) and into $10^{10,000}+$.

## **5\. Handling Numbers Beyond 64-bit Limits ($\> 10^{308}$ to $10^{10,000}+$)**

### **5.1 The IEEE 754 Floating-Point Boundary**

* Standard Luau number types are 64-bit double-precision floats.  
* The maximum limit is $\\approx 1.797 \\times 10^{308}$.  
* Calculations above $1.797 \\times 10^{308}$ overflow to inf.  
* Values below $10^{308}$ maintain \~15–17 decimal digits of precision.

### **5.2 Mantissa/Exponent Data Structure**

To represent numbers up to $10^{10,000}+$ (and beyond), numbers must be stored as a normalized record:

$$\\text{Value} \= m \\times 10^e$$  
Where:

* $m$ \= Mantissa ($1.0 \\le m \< 10.0$ for non-zero values)  
* $e$ \= Exponent ($\\text{integer} \\in \[-\\infty, \+\\infty\]$)

┌────────────────────────────────────────────────────────┐  
│                   BigNum Record                        │  
├─────────────────────────┬──────────────────────────────┤  
│ m (Mantissa: number)    │ Normalized: 1.0 \<= m \< 10.0  │  
│ e (Exponent: number)    │ Integer power of 10          │  
└─────────────────────────┴──────────────────────────────┘

#### **Core Arithmetic Operations**

> 1. **Normalization:**  
>    $$\\text{normalize}(m, e): \\quad \\text{while } m \\ge 10.0 \\implies m \= m / 10.0, e \= e \+ 1$$  
>    $$\\text{normalize}(m, e): \\quad \\text{while } 0 \< m \< 1.0 \\implies m \= m \\times 10.0, e \= e \- 1$$  
> 2. **Multiplication:**  
>    $$(m\_1 \\times 10^{e\_1}) \\times (m\_2 \\times 10^{e\_2}) \= (m\_1 \\times m\_2) \\times 10^{e\_1 \+ e\_2} \\longrightarrow \\text{normalize}$$  
> 3. **Division:**  
>    $$\\frac{m\_1 \\times 10^{e\_1}}{m\_2 \\times 10^{e\_2}} \= \\left(\\frac{m\_1}{m\_2}\\right) \\times 10^{e\_1 \- e\_2} \\longrightarrow \\text{normalize}$$  
> 4. **Addition:**  
>    Given $e\_1 \\ge e\_2$:  
   * If $(e\_1 \- e\_2) \> 16$, the smaller number is below the precision threshold $\\implies \\text{Result} \= (m\_1, e\_1)$.  
   * Otherwise:  
     $$(m\_1 \\times 10^{e\_1}) \+ (m\_2 \\times 10^{e\_2}) \= \\left(m\_1 \+ m\_2 \\times 10^{-(e\_1 \- e\_2)}\\right) \\times 10^{e\_1} \\longrightarrow \\text{normalize}$$  
> 5. **Powers ($A^k$):**  
>    $$(m \\times 10^e)^k \= m^k \\times 10^{e \\times k} \\longrightarrow \\text{normalize}$$

### **5.3 Number Suffix & Formatting Architecture**

For standard display:

* **$e \< 3$:** Plain integer (e.g., 850).  
* **$3 \\le e \< 303$:** Short-scale prefix abbreviations.  
* **$e \\ge 303$ (Past Centillion):** Engineering notation or scientific notation (e.g., 5.05e450, 1.22e1250).

#### **Short-Scale Suffix Mapping Table ($10^3$ to $10^{303}$ — Centillion)**

The formatting engine uses the complete continuous short-scale series up to $10^{303}$ ($100$ total standard suffixes):

| Exponent | Suffix | Full Name | Exponent | Suffix | Full Name |
| :---- | :---- | :---- | :---- | :---- | :---- |
| $10^3$ | **K** | Thousand | $10^{36}$ | **UnDc** | Undecillion |
| $10^6$ | **M** | Million | $10^{39}$ | **DuDc** | Duodecillion |
| $10^9$ | **B** | Billion | $10^{42}$ | **TrDc** | Tredecillion |
| $10^{12}$ | **T** | Trillion | $10^{45}$ | **QaDc** | Quattuordecillion |
| $10^{15}$ | **Qa** | Quadrillion | $10^{48}$ | **QiDc** | Quindecillion |
| $10^{18}$ | **Qi** | Quintillion | $10^{51}$ | **SxDc** | Sexdecillion |
| $10^{21}$ | **Sx** | Sextillion | $10^{54}$ | **SpDc** | Septendecillion |
| $10^{24}$ | **Sp** | Septillion | $10^{57}$ | **OcDc** | Octodecillion |
| $10^{27}$ | **Oc** | Octillion | $10^{60}$ | **NoDc** | Novemdecillion |
| $10^{30}$ | **No** | Nonillion | $10^{63}$ | **Vg** | Vigintillion |
| $10^{33}$ | **Dc** | Decillion | $10^{66}\text{--}10^{90}$ | **UnVg–NoVg** | Vigintillion series |
| $10^{93}\text{--}10^{120}$ | **Tg–NoTg** | Trigintillion series | $10^{123}\text{--}10^{150}$ | **Qd–NoQd** | Quadragintillion series |
| $10^{153}\text{--}10^{180}$ | **Qn–NoQn** | Quinquagintillion series | $10^{183}\text{--}10^{210}$ | **SxG–NoSxG** | Sexagintillion series |
| $10^{213}\text{--}10^{240}$ | **SpG–NoSpG** | Septuagintillion series | $10^{243}\text{--}10^{270}$ | **Og–NoOg** | Octogintillion series |
| $10^{273}\text{--}10^{300}$ | **Nn–NoNn** | Nonagintillion series | $10^{303}$ | **Ce** | **Centillion** |
| $> 10^{303}$ | — | **Scientific Notation (e.g. 1.23e306, 5.00e1000)** | — | — | — |

## **6\. Complete Luau Implementation Module**

Below is the complete, drop-in engine module (BigEconomy.luau) supporting arbitrary-precision math up to $10^{10,000}+$, building calculations, milestone triggers, and multi-tier prestiges.

Code snippet  
\--\!strict  
local BigEconomy \= {}  
BigEconomy.\_\_index \= BigEconomy

export type BigNum \= {  
    m: number, \-- Mantissa: 1.0 \<= m \< 10.0 (or 0 for zero)  
    e: number, \-- Exponent: integer power of 10  
}

local SUFFIXES: { \[number\]: string } \= {  
    \[0\] \= "", \[1\] \= "K", \[2\] \= "M", \[3\] \= "B", \[4\] \= "T",  
    \[5\] \= "Qa", \[6\] \= "Qi", \[7\] \= "Sx", \[8\] \= "Sp", \[9\] \= "Oc", \[10\] \= "No",  
    \[11\] \= "Dc", \[12\] \= "UnDc", \[13\] \= "DuDc", \[14\] \= "TrDc", \[15\] \= "QaDc",  
    \[16\] \= "QiDc", \[17\] \= "SxDc", \[18\] \= "SpDc", \[19\] \= "OcDc", \[20\] \= "NoDc",  
    \[21\] \= "Vg", \[70\] \= "NoSx", \[100\] \= "Ce"  
}

\--------------------------------------------------------------------------------  
\-- BIGNUM ARITHMETIC CORE  
\--------------------------------------------------------------------------------

function BigEconomy.new(m: number, e: number?): BigNum  
    local exp \= e or 0  
    if m \== 0 then  
        return { m \= 0, e \= 0 }  
    end

    \-- Normalize  
    local sign \= math.sign(m)  
    local absM \= math.abs(m)

    if absM \> 0 then  
        local shift \= math.floor(math.log10(absM))  
        absM \= absM / (10 ^ shift)  
        exp \= exp \+ shift  
    end

    return { m \= absM \* sign, e \= exp }  
end

function BigEconomy.fromNumber(n: number): BigNum  
    if n \== 0 then return BigEconomy.new(0, 0\) end  
    local e \= math.floor(math.log10(math.abs(n)))  
    local m \= n / (10 ^ e)  
    return BigEconomy.new(m, e)  
end

function BigEconomy.add(a: BigNum, b: BigNum): BigNum  
    if a.m \== 0 then return b end  
    if b.m \== 0 then return a end

    local diff \= a.e \- b.e  
    if diff \>= 16 then return a end  
    if diff \<= \-16 then return b end

    if diff \>= 0 then  
        local newM \= a.m \+ b.m \* (10 ^ (-diff))  
        return BigEconomy.new(newM, a.e)  
    else  
        local newM \= a.m \* (10 ^ diff) \+ b.m  
        return BigEconomy.new(newM, b.e)  
    end  
end

function BigEconomy.sub(a: BigNum, b: BigNum): BigNum  
    return BigEconomy.add(a, { m \= \-b.m, e \= b.e })  
end

function BigEconomy.mul(a: BigNum, b: BigNum): BigNum  
    if a.m \== 0 or b.m \== 0 then return BigEconomy.new(0, 0\) end  
    return BigEconomy.new(a.m \* b.m, a.e \+ b.e)  
end

function BigEconomy.div(a: BigNum, b: BigNum): BigNum  
    if a.m \== 0 then return BigEconomy.new(0, 0\) end  
    assert(b.m \~= 0, "Division by zero in BigNum")  
    return BigEconomy.new(a.m / b.m, a.e \- b.e)  
end

function BigEconomy.pow(a: BigNum, p: number): BigNum  
    if a.m \== 0 then return BigEconomy.new(0, 0\) end  
    if p \== 0 then return BigEconomy.new(1, 0\) end

    local log10Val \= (math.log10(a.m) \+ a.e) \* p  
    local newE \= math.floor(log10Val)  
    local newM \= 10 ^ (log10Val \- newE)  
    return BigEconomy.new(newM, newE)  
end

function BigEconomy.gte(a: BigNum, b: BigNum): boolean  
    if a.e \~= b.e then return a.e \> b.e end  
    return a.m \>= b.m  
end

\--------------------------------------------------------------------------------  
\-- FORMATTING & DISPLAY  
\--------------------------------------------------------------------------------

function BigEconomy.format(n: BigNum): string  
    if n.m \== 0 then return "0" end  
    if n.e \< 3 then  
        local raw \= n.m \* (10 ^ n.e)  
        return string.format("%.0f", raw)  
    end

    local tier \= math.floor(n.e / 3\)  
    local suffix \= SUFFIXES\[tier\]

    if suffix and n.e \< 303 then  
        local remainder \= n.e % 3  
        local displayM \= n.m \* (10 ^ remainder)  
        return string.format("%.2f %s", displayM, suffix)  
    else  
        return string.format("%.2fe%d", n.m, n.e)  
    end  
end

\--------------------------------------------------------------------------------  
\-- ECONOMY & PROGRESSION EQUATIONS  
\--------------------------------------------------------------------------------

export type BuildingData \= {  
    Name: string,  
    BaseCost: BigNum,  
    GrowthRate: number,  
    BaseProd: BigNum,  
    BaseCycleTime: number,  
    ManagerCost: BigNum,  
}

BigEconomy.Buildings \= {  
    \[1\]  \= { Name \= "Street Corner Preacher",    BaseCost \= BigEconomy.new(4, 0),    GrowthRate \= 1.07, BaseProd \= BigEconomy.new(1, 0),     BaseCycleTime \= 1.0, ManagerCost \= BigEconomy.new(100, 0\) },  
    \[2\]  \= { Name \= "Storage Unit Temple",        BaseCost \= BigEconomy.new(60, 0),   GrowthRate \= 1.08, BaseProd \= BigEconomy.new(12, 0),    BaseCycleTime \= 3.0, ManagerCost \= BigEconomy.new(1500, 0\) },  
    \[3\]  \= { Name \= "Suburban Compound",          BaseCost \= BigEconomy.new(1.8, 3),  GrowthRate \= 1.09, BaseProd \= BigEconomy.new(80, 0),    BaseCycleTime \= 6.0, ManagerCost \= BigEconomy.new(4.5, 4\) },  
    \[4\]  \= { Name \= "Community Hall",             BaseCost \= BigEconomy.new(9, 4),    GrowthRate \= 1.10, BaseProd \= BigEconomy.new(720, 0),   BaseCycleTime \= 12.0, ManagerCost \= BigEconomy.new(2.5, 6\) },  
    \[5\]  \= { Name \= "Wellness Retreat Ranch",     BaseCost \= BigEconomy.new(9, 6),    GrowthRate \= 1.11, BaseProd \= BigEconomy.new(1.2, 4),   BaseCycleTime \= 24.0, ManagerCost \= BigEconomy.new(3, 8\) },  
    \[6\]  \= { Name \= "Merch & Media Wing",         BaseCost \= BigEconomy.new(2.5, 9),  GrowthRate \= 1.12, BaseProd \= BigEconomy.new(3.5, 5),   BaseCycleTime \= 45.0, ManagerCost \= BigEconomy.new(1, 11\) },  
    \[7\]  \= { Name \= "Pirate Radio/TV Broadcast",  BaseCost \= BigEconomy.new(1.5, 12), GrowthRate \= 1.13, BaseProd \= BigEconomy.new(1.2, 7),   BaseCycleTime \= 90.0, ManagerCost \= BigEconomy.new(7.5, 13\) },  
    \[8\]  \= { Name \= "Underground Bunker Complex", BaseCost \= BigEconomy.new(2, 15),   GrowthRate \= 1.14, BaseProd \= BigEconomy.new(6, 8),     BaseCycleTime \= 180.0, ManagerCost \= BigEconomy.new(1.2, 17\) },  
    \[9\]  \= { Name \= "Shell Corporation Network",  BaseCost \= BigEconomy.new(5, 18),   GrowthRate \= 1.15, BaseProd \= BigEconomy.new(4, 10),    BaseCycleTime \= 360.0, ManagerCost \= BigEconomy.new(3.5, 20\) },  
    \[10\] \= { Name \= "Global Mega-Temple HQ",      BaseCost \= BigEconomy.new(2.5, 22), GrowthRate \= 1.16, BaseProd \= BigEconomy.new(3.5, 12),   BaseCycleTime \= 720.0, ManagerCost \= BigEconomy.new(2, 24\) },  
}

\-- Batch purchase cost  
function BigEconomy.GetBatchCost(baseCost: BigNum, r: number, owned: number, amount: number): BigNum  
    if amount \<= 0 then return BigEconomy.new(0, 0\) end  
    local rOwned \= BigEconomy.pow(BigEconomy.fromNumber(r), owned)  
    local rAmount \= BigEconomy.pow(BigEconomy.fromNumber(r), amount)  
    local rMinusOne \= BigEconomy.fromNumber(r \- 1\)

    local numerator \= BigEconomy.sub(rAmount, BigEconomy.new(1, 0))  
    local factor \= BigEconomy.div(numerator, rMinusOne)

    return BigEconomy.mul(baseCost, BigEconomy.mul(rOwned, factor))  
end

\-- Buy Max calculation  
function BigEconomy.CalculateMaxAffordable(baseCost: BigNum, r: number, owned: number, balance: BigNum): (number, BigNum)  
    local rOwned \= BigEconomy.pow(BigEconomy.fromNumber(r), owned)  
    local denominator \= BigEconomy.mul(baseCost, rOwned)  
    local rMinusOne \= BigEconomy.fromNumber(r \- 1\)

    local term \= BigEconomy.mul(balance, rMinusOne)  
    local ratio \= BigEconomy.div(term, denominator)  
    local inner \= BigEconomy.add(BigEconomy.new(1, 0), ratio)

    if inner.m \<= 0 then return 0, BigEconomy.new(0, 0\) end

    local log10Val \= math.log10(inner.m) \+ inner.e  
    local maxCount \= math.floor(log10Val / math.log10(r))

    if maxCount \<= 0 then return 0, BigEconomy.new(0, 0\) end

    local exactCost \= BigEconomy.GetBatchCost(baseCost, r, owned, maxCount)  
    return maxCount, exactCost  
end

\-- Milestone calculation  
function BigEconomy.GetMilestoneMultipliers(owned: number): (BigNum, number)  
    local mult \= 1  
    local speedDivisor \= 1

    if owned \>= 10 then mult \= mult \* 2 end  
    if owned \>= 25 then mult \= mult \* 2 end  
    if owned \>= 50 then mult \= mult \* 2; speedDivisor \= speedDivisor \* 2 end  
    if owned \>= 100 then mult \= mult \* 2; speedDivisor \= speedDivisor \* 2 end  
    if owned \>= 200 then mult \= mult \* 4 end  
    if owned \>= 500 then mult \= mult \* 8 end  
    if owned \>= 1000 then mult \= mult \* 16; speedDivisor \= speedDivisor \* 2 end  
    if owned \>= 2000 then mult \= mult \* 32; speedDivisor \= speedDivisor \* 2 end

    return BigEconomy.fromNumber(mult), speedDivisor  
end

\--------------------------------------------------------------------------------  
\-- PRESTIGE CALCULATORS  
\--------------------------------------------------------------------------------

\-- Layer 1: Schism (Zealot Points)  
function BigEconomy.CalculateZealotPoints(lifetimeFollowers: BigNum): BigNum  
    \-- floor( sqrt( Lifetime / 1e9 ) )  
    if lifetimeFollowers.e \< 9 then return BigEconomy.new(0, 0\) end  
    local adjusted \= BigEconomy.div(lifetimeFollowers, BigEconomy.new(1, 9))  
    local log10Val \= (math.log10(adjusted.m) \+ adjusted.e) \* 0.5  
    local newE \= math.floor(log10Val)  
    local newM \= math.floor(10 ^ (log10Val \- newE))  
    return BigEconomy.new(newM, newE)  
end

\-- Layer 2: Reformation (Heretic Souls)  
function BigEconomy.CalculateHereticSouls(lifetimeZealots: BigNum): BigNum  
    \-- floor( ( LifetimeZealots / 1e5 ) ^ 0.4 )  
    if lifetimeZealots.e \< 5 then return BigEconomy.new(0, 0\) end  
    local adjusted \= BigEconomy.div(lifetimeZealots, BigEconomy.new(1, 5))  
    local log10Val \= (math.log10(adjusted.m) \+ adjusted.e) \* 0.4  
    local newE \= math.floor(log10Val)  
    local newM \= math.floor(10 ^ (log10Val \- newE))  
    return BigEconomy.new(newM, newE)  
end

\-- Layer 3: Dogma (Pantheon Relics)  
function BigEconomy.CalculatePantheonRelics(lifetimeSouls: BigNum): number  
    \-- floor( log10( LifetimeSouls / 100 ) )  
    if lifetimeSouls.e \< 3 then return 0 end  
    local rawLog \= math.log10(lifetimeSouls.m) \+ (lifetimeSouls.e \- 2\)  
    return math.max(0, math.floor(rawLog))  
end

return BigEconomy  
