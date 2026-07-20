# Li-600 Data Visualization Projects 

## Project 1: The Leaf Energy Budget Dashboard

**Core question:** How does leaf temperature track ambient light and transpirational cooling?

**Variables:** `Tleaf`, `Tref`, `Qamb`, `E_apparent`, `gsw`

**What to build:**
- Pick one genotype, or a handful of representative ones
- Plot `Tleaf - Tref` (how much the leaf is cooler or hotter than the air) against `Qamb`, colored by `gsw`
- Optionally add a time series panel: `Tleaf` and `Tref` overlaid across a day or across the season, with `E_apparent` shown as point size or a secondary axis

When conductance is high, transpiration decouples leaf temperature from the ambient light load — the plot should make that decoupling visible.

---

## Project 2: Photochemistry vs. Light Response Curve

**Core question:** How does photochemical efficiency and electron transport change as ambient light increases?

**Variables:** `Qamb`, `PhiPS2`, `ETR`, `abs`

**What to build:**
- `PhiPS2` vs `Qamb` — efficiency usually declines as light goes up (downregulation)
- `ETR` vs `Qamb` — usually rises then plateaus (light saturation)
- A small facet or inset showing `abs` (leaf light absorptance) to explain genotype-level offsets

This is a standard plant physiology figure type, so it's a good way to practice building something that reads clearly to someone in the field, with real biological meaning attached to the curve shape.

---

## Project 3: Conductance Anatomy — Where Does Resistance Live?

**Core question:** How much of total leaf conductance is limited by the stomata vs. the leaf boundary layer?

**Variables:** `gsw`, `gbw`, `gtw`, `leaf_width`

**What to build:**
- A stacked bar or slope chart per genotype, showing `gsw` and `gbw` as components of `gtw`
- A scatter of `gbw` vs `leaf_width`, colored or grouped by genotype

Conductance is abstract until you break it into its parts. This is also good practice with a composition-style chart instead of another plain scatter plot.

---

## Project 4: The Water-Carbon Trade-off Map

**Core question:** Which genotypes are efficient water users, and which trade water for carbon gain?

**Variables:** `E_apparent`, `ETR`, `gsw`, `Tleaf`

**What to build:**
- One bubble plot: `E_apparent` (x) vs `ETR` (y), bubble size = `gsw`, color = mean `Tleaf`
- Add a reference line (diagonal or loess trend) so genotypes above/below it read as efficient vs. inefficient

This is the only project that combines porometry and fluorometry into one composite view. It's a good exercise in encoding four variables at once (x, y, size, color) without the plot turning into noise — the legend and annotation choices matter as much as the data here.

---

## Project 5: Herbivory

**Core question:** Does herbivory incidence change across the season, and does it track with plant size?

**Variables:** herbiv.y.n, survey_date, height.cm, long.leaf.cm

**What to build:** A simple line or bar chart of the proportion of plants with herbivory damage (herbiv.y.n == "Y") at each survey date across the season
A paired boxplot or jittered scatter comparing height.cm (or long.leaf.cm) between herbivorized and non-herbivorized plants


This project only needs the growth/herbivory dataset, which is already clean and complete. It's also a nice contrast to the other four: categorical damage data and a simple seasonal trend, rather than continuous physiology.