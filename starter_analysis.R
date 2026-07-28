# starter_analysis.R
#
# Starting point for all: load, merge, and orient yourself in the
# WL2 2025 Li-600 season dataset before picking a project (see project_ideas.md).
#
# This script does NOT answer any project question. It merges all five
# scan dates with their metadata, does light standardization, and makes
# four "orientation" figures so you can see what you're working with.
#
# Output:
#   - Data/merged_licor_data.csv   (one row per scan, all dates stacked)
#   - figures/*.png                (four orientation plots)

library(tidyverse)
library(janitor)
library(ggthemes)
library(ggdoctheme)

dir.create("figures", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Step 1: Load and inspect
# ---------------------------------------------------------------------------
# Five scan dates exist as separate files (the instrument exports one file
# per session), each with a matching metadata file recorded separately.

data_files <- list.files("Data", pattern = "^LI-COR_.*\\.csv$", full.names = TRUE)
meta_files <- list.files("metadata", pattern = "^[0-9]{8}\\.csv$", full.names = TRUE)

data_list <- map(data_files, read_csv, show_col_types = FALSE)
names(data_list) <- basename(data_files)

meta_list <- map(meta_files, read_csv, show_col_types = FALSE)
names(meta_list) <- basename(meta_files)

# Print dim() and names() of every file before merging anything, so column
# mismatches across dates are visible immediately.
cat("\n--- Scan data files (Data/) ---\n")
walk2(data_list, names(data_list), function(df, nm) {
  cat("\n", nm, ": ", paste(dim(df), collapse = " x "), "\n", sep = "")
  print(names(df))
})

cat("\n--- Metadata files (metadata/) ---\n")
walk2(meta_list, names(meta_list), function(df, nm) {
  cat("\n", nm, ": ", paste(dim(df), collapse = " x "), "\n", sep = "")
  print(names(df))
})

# Column names for the join key are NOT consistent across metadata files:
# "Li600" (20250723, 20250807, 20250828, 20250904) vs "Li.600" (20250923).
# janitor::clean_names() below will standardize all of these to "li600" so
# the join logic can be identical across dates.

# NOTE on dates: the scan file named "LI-COR_20250923.csv" actually contains
# Date = 2025-09-24 internally (confirmed by inspecting the raw file), while
# its metadata file is named/dated 20250923. We use the scan file's own
# Date column as the authoritative date for that batch, per project lead.
# This means the "date" column below is *not* always identical to the
# metadata file's name.

# ---------------------------------------------------------------------------
# Step 2: Join logic (per date)
# ---------------------------------------------------------------------------
# For each date, left_join metadata onto scan data by Li.600 (metadata) =
# Obs (scan data), so every scan row is kept even if some metadata fields
# are missing.

clean_join <- function(meta_df, data_df) {
  meta_clean <- meta_df |> clean_names()
  data_clean <- data_df |> clean_names()

  # The join-key column name is not consistent across raw metadata files:
  # clean_names() turns "Li600" into "li600" but "Li.600" into "li_600".
  # Standardize to "li600" so the join logic below is identical every date.
  meta_clean <- meta_clean |> rename(li600 = any_of("li_600"))

  # li600 is read as character in some metadata files because a handful of
  # rows contain the literal string "NA" (no scan that day) mixed in with
  # numeric IDs. as.numeric() below turns those into a real NA so the join
  # key types match; it will also warn (and produce NA) if anything else
  # non-numeric slipped in, which is worth noticing rather than hiding.
  meta_clean <- meta_clean |> mutate(li600 = as.numeric(li600))

  # unique_id is read as numeric in some files and character in others (the
  # 20250923 metadata quotes every field, e.g. "2549 " with a trailing
  # space). Force to character everywhere so bind_rows() doesn't error, and
  # trim whitespace so "2549 " and "2549" aren't treated as different IDs.
  meta_clean <- meta_clean |> mutate(unique_id = str_trim(as.character(unique_id)))

  # "observation" (the instrument's own row label, e.g. "001") is read as
  # character in four files but numeric in 20250828.csv (no leading
  # zeros that date) - force character so bind_rows() doesn't error.
  data_clean <- data_clean |> mutate(observation = as.character(observation))

  meta_clean |>
    left_join(data_clean, by = c("li600" = "obs"))
}

joined_20250723 <- clean_join(meta_list[["20250723.csv"]], data_list[["LI-COR_20250723.csv"]])
joined_20250807 <- clean_join(meta_list[["20250807.csv"]], data_list[["LI-COR_20250807.csv"]])
joined_20250828 <- clean_join(meta_list[["20250828.csv"]], data_list[["LI-COR_20250828.csv"]])
joined_20250904 <- clean_join(meta_list[["20250904.csv"]], data_list[["LI-COR_20250904.csv"]])
joined_20250923 <- clean_join(meta_list[["20250923.csv"]], data_list[["LI-COR_20250923.csv"]])

# Tag each batch with its own "date" column. Note 20250923 uses the scan
# file's internal date (2025-09-24), not the metadata file name — see note
# above.
joined_20250723 <- joined_20250723 |> mutate(date = as.Date("2025-07-23"), .before = 1)
joined_20250807 <- joined_20250807 |> mutate(date = as.Date("2025-08-07"), .before = 1)
joined_20250828 <- joined_20250828 |> mutate(date = as.Date("2025-08-28"), .before = 1)
joined_20250904 <- joined_20250904 |> mutate(date = as.Date("2025-09-04"), .before = 1)
joined_20250923 <- joined_20250923 |> mutate(date = as.Date("2025-09-24"), .before = 1)

# bind_rows() (not rbind()) so columns that exist in some dates but not
# others (e.g. genotype/type only appear from 20250828 onward; svc/sr only
# appear in early dates) become visible NA instead of erroring out.
merged <- bind_rows(
  joined_20250723,
  joined_20250807,
  joined_20250828,
  joined_20250904,
  joined_20250923
)

cat("\n--- Merged dataset ---\n")
cat("dim:", paste(dim(merged), collapse = " x "), "\n")

# Summary of which columns are NA-heavy per date, so students can see at a
# glance which variables are only available for some dates.
cat("\n--- Proportion NA per column, by date ---\n")
na_summary <- merged |>
  group_by(date) |>
  summarise(across(everything(), ~ mean(is.na(.x))), .groups = "drop")
print(na_summary, width = Inf)

# ---------------------------------------------------------------------------
# Step 3: Basic cleaning
# ---------------------------------------------------------------------------
# Column names are already standardized via clean_names() during the join.

# Check for duplicate unique_id + date combinations before assuming one row
# = one plant per date. We do NOT drop duplicates here — just report them,
# since students need to see this raw-data quirk themselves.
dupes <- merged |>
  count(date, unique_id, name = "n") |>
  filter(n > 1)

cat("\n--- Duplicate unique_id + date combinations ---\n")
if (nrow(dupes) > 0) {
  print(dupes, n = Inf)
} else {
  cat("None found.\n")
}

# NOTE: No imputation, outlier removal, or filtering happens in this script.
# Raw data quirks (NAs, duplicates, unmatched rows) are left visible on
# purpose — see the console output above and the missingness figure below.

# ---------------------------------------------------------------------------
# Step 4: Sample visualizations (orientation only — independent of the 5
# student projects; see project_ideas.md for the actual project questions)
# ---------------------------------------------------------------------------

png_out <- function(filename, plot, width = 1600, height = 1000, res = 150) {
  png(filename, width = width, height = height, res = res)
  print(plot)
  dev.off()
}

## 4.1 Sampling effort per date -----------------------------------------
p_sampling <- merged |>
  count(date) |>
  ggplot(aes(x = date, y = n)) +
  geom_col(fill = "#4c72b0") +
  theme_doc() +
  labs(
    title = "Observations per sampling date",
    x = "Date", y = "Number of scans"
  )

png_out("figures/sampling_overview.png", p_sampling)

## 4.2 Headline traits by date (small multiples) -------------------------
# Check actual column names after clean_names(): Tleaf -> tleaf,
# gsw -> gsw, PhiPS2 -> phi_ps2, VPDleaf -> vp_dleaf (clean_names() splits
# on the internal capital D).
headline_vars <- c("tleaf", "gsw", "phi_ps2", "vp_dleaf")

p_traits <- merged |>
  select(date, all_of(headline_vars)) |>
  pivot_longer(cols = all_of(headline_vars), names_to = "variable", values_to = "value") |>
  ggplot(aes(x = date, y = value, group = date)) +
  geom_boxplot(fill = "#dd8452") +
  facet_wrap(~variable, scales = "free_y") +
  theme_doc() +
  labs(
    title = "Headline trait spread by date (all genotypes pooled)",
    x = "Date", y = NULL
  )

png_out("figures/trait_by_date_overview.png", p_traits)

## 4.3 Variable correlation overview (all dates pooled) -------------------
# Purpose: orient students to which physiology variables move together.
# Restricted to the physiologically meaningful variables (the four buckets
# from intro_slides.md: porometer, fluorometer, stability, environmental)
# rather than every numeric column, since the raw file also carries dozens
# of instrument calibration/internal columns that aren't useful here and
# would make the heatmap unreadable.
physiology_vars <- c(
  # porometer (gas exchange)
  "gsw", "gbw", "gtw", "e_apparent", "trans", "vp_dleaf", "tleaf", "tref",
  "leaf_area",
  # fluorometer (photochemistry)
  "phi_ps2", "etr", "fv_fm", "fs", "fm_2", "fo", "fm",
  # stability (measurement quality)
  "flr1sec", "flr2sec", "flr4sec", "gsw1sec", "gsw2sec", "gsw4sec",
  # environmental (conditions during scan)
  "qamb", "rh_s", "rh_r", "p_atm"
)

numeric_vars <- merged |>
  select(any_of(physiology_vars)) |>
  select(where(~ sum(!is.na(.x)) > 1))

cor_mat <- cor(numeric_vars, use = "pairwise.complete.obs")

cor_df <- cor_mat |>
  as.data.frame() |>
  rownames_to_column("var1") |>
  pivot_longer(-var1, names_to = "var2", values_to = "correlation")

p_corr <- cor_df |>
  ggplot(aes(x = var1, y = var2, fill = correlation)) +
  geom_tile() +
  scale_fill_gradient2(low = "#4575b4", mid = "white", high = "#d73027", midpoint = 0) +
  theme_doc() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 6),
        axis.text.y = element_text(size = 6)) +
  labs(
    title = "Correlation across all numeric physiology variables (all dates pooled)",
    x = NULL, y = NULL
  )

png_out("figures/variable_correlation_overview.png", p_corr)

## 4.4 Missingness overview (NA counts per column per date) --------------
# naniar::vis_miss() is not installed in this environment, so this uses a
# manual is.na() summary + geom_tile(), as the handoff allows. Every column
# is summarized in the console output above (Step 2); this plot shows all
# of them too, but text is necessarily small given how many columns the
# raw Li-600 export carries (100+, including internal calibration fields).
missing_df <- merged |>
  group_by(date) |>
  summarise(across(everything(), ~ mean(is.na(.x))), .groups = "drop") |>
  pivot_longer(-date, names_to = "column", values_to = "prop_na")

p_missing <- missing_df |>
  ggplot(aes(x = date, y = column, fill = prop_na)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "#c0392b", limits = c(0, 1)) +
  theme_doc() +
  theme(axis.text.y = element_text(size = 4)) +
  labs(
    title = "Proportion missing (NA) per column, by date",
    subtitle = "Every raw column is shown; see console output for exact values",
    x = "Date", y = NULL, fill = "Prop. NA"
  )

png_out("figures/missingness_overview.png", p_missing)

# ---------------------------------------------------------------------------
# Step 5: Save merged data
# ---------------------------------------------------------------------------
write_csv(merged, "Data/merged_licor_data.csv")

cat("\nDone. Merged data written to Data/merged_licor_data.csv\n")
cat("Figures written to figures/:\n")
print(list.files("figures", full.names = TRUE))

data = read_csv("Data/merged_licor_data.csv")

P1 = data |>
  filter(date == "2025-09-04") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() +
  theme_minimal()
print(P1)
ggsave("figures/Scatter.png",P1)

P2 = data |>
  filter(date == "2025-07-23") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() +
  theme_minimal()
print(P2)
ggsave("figures/Scatter2.png",P2)

P1 = data |>
  filter(date == as.Date("2025-09-04")) |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() +
  theme_minimal()
print(P1)
ggsave("figures/Scatter.png",P1)

P3 = data |>
  filter(date == "2025-08-07") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P3)
ggsave("figures/Scatter3.png",P3)

P1 = data |>
  filter(date == "2025-08-07") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P1)
ggsave("figures/Scatter2025-08-07.png",P1)

P1 = data |>
  filter(date == "2025-07-23") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P1)
ggsave("figures/Scatter2025-07-23.png",P1)

P2 = data |>
  filter(date == "2025-08-07") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P2)
ggsave("figures/Scatter2025-08-07.png",P2)


P3 = data |>
  filter(date == "2025-08-28") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P3)
ggsave("figures/Scatter2025-08-28.png",P3)

P4 = data |>
  filter(date == "2025-09-04") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P4)
ggsave("figures/Scatter2025-09-04.png",P4)

P5 = data |>
  filter(date == "2025-09-24") |>
  ggplot(aes(x = phi_ps2, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P5)
ggsave("figures/Scatter2025-09-24.png",P5)

P6 = data |>
  filter(date == "2025-09-24", etr >= 0) |>
  ggplot(aes(x = etr, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P6)
ggsave("figures/etr vs qamb2025-09-24.2.png",P6)

P7 = data |>
  filter(date == "2025-09-04", etr >= 0) |>
  ggplot(aes(x = etr, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P7)
ggsave("figures/etr vs qamb2025-09-04.png",P7)

P8 = data |>
  filter(date == "2025-08-28", etr >= 0) |>
  ggplot(aes(x = etr, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P8)
ggsave("figures/etr vs qamb2025-08-28.png",P8)

P9 = data |>
  filter(date == "2025-08-07", etr >= 0) |>
  ggplot(aes(x = etr, y = qamb)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P9)
ggsave("figures/etr vs qamb2025-08-07.png",P9)

P10 = data |>
  filter(date == "2025-07-23", etr >= 0) |>
  ggplot(aes(x = etr, y = qamb, color = Type)) +
  geom_point() + geom_smooth(method=lm , color="red", se=FALSE) +
  theme_minimal()
print(P10)
ggsave("figures/etr vs qamb2025-07-23.png",P10)

metadata_723 = read_csv("metadata/20250723.csv")
metadata_904 = read_csv("metadata/20250904.csv")
x_nonum <- which(is.na(as.numeric(metadata_904$Unique.ID)))
x_nonum
metadata_723 = left_join(x = metadata_723, y = metadata_904[c("Unique.ID", "Genotype", "Type")], by = "Unique.ID")
#master_meta <- read_csv("fill in file name") #this file will have all the genotype and type info for each individual (unique ID)
#data_geno = left_join(x = data, y = master_meta, by = Unique.ID")
x_nonum <- which(is.na(as.numeric(merged$unique_id)))
x_nonum

# Below we are figuring out sample sizes for each parent genotype and each date
date_geno_parent_n <- data_geno |> 
  filter(Type=="Parent") |> # take  only the rows where the type is Parent
  group_by(date, Type, Genotype) |> #for each date and genotype
  summarise(TotalIndivs=n()) #count the number of rows 
date_geno_parent_n_overall <- data_geno |> 
  filter(Type=="Parent") |> # take  only the rows where the type is Parent
  group_by(Type, Genotype) |> #for each genotype
  summarise(TotalIndivs=n()) #count the number of rows 

metadata_807 = read_csv("metadata/20250807.csv")
