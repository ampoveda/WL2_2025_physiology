---
marp: true
theme: default
paginate: true
size: 16:9
---

# Li-600 WL2 2025 Season Dataset
### A brief orientation of the data

Rishav Ray - UC Davis

---

## What this dataset actually is

- Multiple Li-600 scan sessions across a growing season (5 dates)
- Each scan session = porometer + fluorometer readings, one row per plant
- A separate metadata file per date links each scan to plant ID, block, bed, row, col
- Alongside: a growth dataset (height, leaf length, herbivory) tracked independently across the season

This is **not** a clean, ready-to-model dataset. Treat today as a map, not a manual.

---

## What "done" looks like

- One clear figure or small panel set
- One specific, answerable question
- 3-4 weeks, not a full study
- You are not expected to touch every variable in the dataset

Look at `project_ideas.md` for the five scoped options once you're oriented.

---

## Data anatomy: two file types

```
Data/LI-COR_20250723.csv       ← scan data (one date per file)
metadata/20250723.csv           ← plant IDs, block/bed/row/col for that date
```

- Same plant, same date, must be joined across these two files
- Join key: `Li.600` (metadata) = `Obs` (scan data)
- Five scan dates exist; check with your project lead about two dates where metadata and scan files don't fully line up

---

## Why separate files per date?

- Each Li-600 session is exported as its own file by the instrument
- Metadata (block/bed/genotype) is recorded separately per sampling day
- You'll merge these yourself — the starter script does this once for the whole season, but understanding *why* the structure looks like this will help you debug when something doesn't join

---

## Variable groups: the four buckets

1. **Porometer** — gas exchange: `gsw`, `E_apparent`, `Tleaf`, `Tref`, `VPDleaf`
2. **Fluorometer** — photochemistry: `PhiPS2`, `ETR`, `Fv/Fm`, `Fs`, `Fm'`
3. **Stability** — measurement quality: `flr1sec`, `flr2sec`, `flr4sec`
4. **Environmental** — conditions during scan: `Qamb`, ambient temp/humidity

Full definitions: [Li-600 data file documentation](https://www.licor.com/support/LI-600/topics/data-file-descriptions.html#Data)

---

## You don't need to master all four groups

- Each of the 5 projects uses **1-2 variable groups**, not all four
- Pick your project first, then read up on just those variables
- The starter script's `figures/variable_correlation_overview.png` is a fast way to see which variables move together before you commit

---

## The five project angles (one line each)

1. **Leaf energy budget** — temperature vs. light vs. cooling
2. **Light response curve** — photochemistry vs. ambient light
3. **Conductance anatomy** — stomatal vs. boundary layer resistance
4. **Water-carbon trade-off** — a composite efficiency view
5. **Herbivory** — growth/damage only, no physiology needed

Full details in `project_ideas.md`.

---

## Where to start

- `Data/merged_licor_data.csv` — one clean file, all dates joined, ready to filter
- `figures/` — four orientation plots already generated for you:
  - sampling effort per date
  - headline traits by date
  - variable correlations
  - missingness by column/date

Look at these **before** picking a project — they'll tell you what's actually usable.


---

## Start here

1. Open `Data/merged_licor_data.csv`
2. Look at the four figures in `figures/`
3. Re-read `project_ideas.md` and pick one
4. Come back with your specific question

---

## 
