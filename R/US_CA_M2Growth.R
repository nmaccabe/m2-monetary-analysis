#install.packages(c("tidyverse", "slider", "ggdist", "scales", "forecast", "vars"))
set.seed(12341234)

library(tidyverse)
library(slider)
library(ggdist)
library(scales)
library(broom)
library(vars)

working_directory <- dirname(rstudioapi::documentPath())
setwd(working_directory)


# ── 1. Load US M2 ─────────────────────────────────────────────────────────────
us_m2 <- read_csv("../data/M2SL.csv") |>
  rename(date = observation_date, m2 = M2SL) |>
  mutate(date = as.Date(date)) |>
  arrange(date) |>
  mutate(yoy = (m2 / lag(m2, 12) - 1) * 100) |>
  mutate(mom = (m2 / lag(m2, 1) - 1) * 100)

# ── 2. Canada M2+ (gross, SA) — hardcode from Bank of Canada E1 ───────────────
# Units: millions CAD, series V41552798
raw <-readLines("../data/Canada_e1_monthly-sd-1946-01-01.csv")

# Find the OBSERVATIONS line and keep everything after it
obs_start <- which(raw == '"OBSERVATIONS"')
clean <- raw[(obs_start + 1):length(raw)]

writeLines(clean, "../data/canada_m2_clean.csv")

canada_m2 <- read_csv("../data/canada_m2_clean.csv") |>
  dplyr::select(date, m2 = V41552798) |>
  mutate(
    date = as.Date(date),
    m2   = as.numeric(m2)
  ) |>
  arrange(date) |>
  filter(!is.na(m2)) |>
  mutate(yoy = (m2 / lag(m2, 12) - 1) * 100) |>
  mutate(mom = (m2 / lag(m2, 1) - 1) * 100)

# ── 3. Define event windows ───────────────────────────────────────────────────
windows <- list(
  gfc   = list(start = "2006-01-01", end = "2011-12-01"),
  covid = list(start = "2019-01-01", end = "2025-12-01")
)

# ── 4. Extract window distributions ───────────────────────────────────────────
extract_window <- function(df, start, end, country) {
  df |>
    filter(date >= as.Date(start), date <= as.Date(end)) |>
    dplyr::select(date, yoy, mom) |>
    mutate(country = country)
}

gfc_data <- bind_rows(
  extract_window(us_m2,     windows$gfc$start, windows$gfc$end,   "US"),
  extract_window(canada_m2, windows$gfc$start, windows$gfc$end,   "Canada")
)

covid_data <- bind_rows(
  extract_window(us_m2,     windows$covid$start, windows$covid$end, "US"),
  extract_window(canada_m2, windows$covid$start, windows$covid$end, "Canada")
)

# ── 5. Raw Plots ──────────────────────────────────────────────────────────────
bind_rows(gfc_data |> mutate(event = "2008 Financial Crisis"),
          covid_data |> mutate(event = "COVID-19")) |>
  pivot_longer(cols = c(yoy, mom), names_to = "metric", values_to = "value") |>
  ggplot(aes(x = date, y = value, colour = country)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  facet_grid(metric ~ event, scales = "free") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "M2 Growth Rates (M2+ Canada)", x = NULL, y = NULL, colour = NULL) +
  theme_minimal()

# ── 6. Simple Linear Model ────────────────────────────────────────────────────
gfc_wide <- gfc_data |>
  dplyr::select(date, mom, country) |>
  pivot_wider(names_from = country, values_from = mom) |>
  rename(us = "US", canada = "Canada")

lm_gfc <- lm(us ~ canada, data = gfc_wide)
summary(lm_gfc)

covid_wide <- covid_data |>
  dplyr::select(date, mom, country) |>
  pivot_wider(names_from = country, values_from = mom) |>
  rename(us = "US", canada = "Canada")

lm_covid <- lm(us ~ canada, data = covid_wide)
summary(lm_covid)

# ── 7. ARX(1) Model ───────────────────────────────────────────────────────────

gfc_wide <- gfc_wide |>
  mutate(us_lag1 = lag(us,1))

arx1_gfc <- lm(us ~ canada + us_lag1, data = gfc_wide)
summary(arx1_gfc)

covid_wide <- covid_wide |>
  mutate(us_lag1 = lag(us,1))

arx1_covid <- lm(us ~ canada + us_lag1, data = covid_wide)
summary(arx1_covid)

# ── 8. ARX(1) vs Actual Plots ─────────────────────────────────────────────────
bind_rows(
  augment(arx1_gfc) |> 
    bind_cols(gfc_wide |> drop_na(us_lag1) |> dplyr::select(date)) |> 
    mutate(event = "2008 Financial Crisis"),
  augment(arx1_covid) |> 
    bind_cols(covid_wide |> drop_na(us_lag1) |> dplyr::select(date)) |> 
    mutate(event = "COVID")
) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = us, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX1 Fitted vs Actual US M2 Monthly Growth",
       x = NULL, y = "Monthly Growth (%)", colour = NULL) +
  theme_minimal()

# ── 9. ARX(1) ACF ─────────────────────────────────────────────────────────────
par(mfrow = c(2, 2))
acf(gfc_wide$us,   main = "ACF — US Monthly Growth (2008)")
acf(gfc_wide$canada, main = "ACF — Canada Monthly Growth (2008)")
acf(covid_wide$us,   main = "ACF — US Monthly Growth (COVID)")
acf(covid_wide$canada, main = "ACF — Canada Monthly Growth (COVID)")

acf(resid(arx1_gfc),   main = "ACF — AR1 Residuals (2008)")
acf(resid(arx1_covid), main = "ACF — AR1 Residuals (COVID)")

# ── 10. Marshaled Rolling Window Regression ───────────────────────────────────
# Rolling window — COVID
rolling_covid <- covid_wide |>
  drop_na() |>
  mutate(
    coef_canada = slide_dbl(
      .x = row_number(),
      .f = ~ {
        window <- covid_wide |> drop_na() |> slice(.x)
        coef(lm(us ~ canada + us_lag1, data = window))["canada"]
      },
      .before = 11,
      .complete = TRUE
    )
  )

# Rolling window — GFC
rolling_gfc <- gfc_wide |>
  drop_na() |>
  mutate(
    coef_canada = slide_dbl(
      .x = row_number(),
      .f = ~ {
        window <- gfc_wide |> drop_na() |> slice(.x)
        coef(lm(us ~ canada + us_lag1, data = window))["canada"]
      },
      .before = 11,
      .complete = TRUE
    )
  )

# Plot
bind_rows(
  rolling_gfc   |> mutate(event = "2008 Financial Crisis"),
  rolling_covid |> mutate(event = "COVID")
) |>
  ggplot(aes(x = date, y = coef_canada)) +
  geom_line(colour = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  labs(title = "Rolling 12-Month Canada Coefficient",
       x = NULL, y = "Coefficient Estimate") +
  theme_minimal()

# ── 11. Granger Causality Test ────────────────────────────────────────────────
# 2008 Financial Crisis
lag_gfc <- VARselect(gfc_wide[, c("us", "canada")], lag.max = 6)$selection["AIC(n)"]
var_gfc <- VAR(gfc_wide[, c("us", "canada")], p = lag_gfc)
normality.test(var_gfc)
causality(var_gfc, cause = "canada", boot = TRUE, boot.runs = 1000)
irf(var_gfc, impulse = "canada", response = "us", n.ahead = 12)

# COVID
lag_covid <- VARselect(covid_wide[, c("us", "canada")], lag.max = 6)$selection["AIC(n)"]
var_covid <- VAR(covid_wide[, c("us", "canada")], p = lag_covid)
normality.test(var_covid)
causality(var_covid, cause = "canada", boot = TRUE, boot.runs = 1000)
irf(var_covid, impulse = "canada", response = "us", n.ahead = 12)

# ── 12. Halfeye Plot ──────────────────────────────────────────────────────────
bind_rows(
  gfc_data   |> mutate(event = "2008 Financial Crisis"),
  covid_data |> mutate(event = "COVID")
) |>
  ggplot(aes(x = mom, fill = country)) +
  stat_halfeye(aes(colour = country), alpha = 0.5, position = "identity") +
  geom_vline(xintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  scale_x_continuous(labels = percent_format(scale = 1)) +
  labs(title = "Distribution of M2 MoM Growth Rates",
       x = "MoM Growth (%)", y = NULL, fill = "country") +
  theme_minimal()

# ── 13. EDFC Plot ─────────────────────────────────────────────────────────────
bind_rows(
  gfc_data   |> mutate(event = "2008 Financial Crisis"),
  covid_data |> mutate(event = "COVID")
) |>
  ggplot(aes(x = mom, colour = country)) +
  stat_ecdf() +
  geom_vline(xintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  scale_x_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ECDF of M2 MoM Growth Rates",
       x = "MoM Growth (%)", y = "Cumulative Probability", colour = "Country") +
  theme_minimal()

# ── 14. Full Dataset Tests ────────────────────────────────────────────────────
full_data <- bind_rows(
  us_m2     |> dplyr::select(date, mom, yoy) |> mutate(country = "US"),
  canada_m2 |> dplyr::select(date, mom, yoy) |> mutate(country = "Canada")
) |>
  group_by(country) |>
  filter(!is.na(mom), !is.na(yoy)) |>
  ungroup()

# Find overlapping date range
overlap_start <- max(
  min(filter(full_data, country == "US")$date),
  min(filter(full_data, country == "Canada")$date)
)

full_data <- full_data |> filter(date >= overlap_start)

# Full sample wide format
full_wide <- full_data |>
  dplyr::select(date, mom, country) |>
  pivot_wider(names_from = country, values_from = mom) |>
  rename(us = US, canada = Canada) |>
  mutate(us_lag1 = lag(us, 1)) |>
  drop_na()

# ARX(1)
arx_full <- lm(us ~ canada + us_lag1, data = full_wide)
summary(arx_full)

# ARX(1) Fitted vs Actual
augment(arx_full) |>
  bind_cols(full_wide |> drop_na() |> dplyr::select(date)) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = us, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "grey50") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX(1) Fitted vs Actual US M2 MoM Growth — Full Sample",
       x = NULL, y = "MoM Growth (%)", colour = NULL) +
  theme_minimal()

# VAR
lag_full <- VARselect(full_wide[, c("us", "canada")], lag.max = 6)$selection["AIC(n)"]
var_full <- VAR(full_wide[, c("us", "canada")], p = lag_full)

# Normality test
normality.test(var_full)

# Bootstrap Granger
causality(var_full, cause = "canada", boot = TRUE, boot.runs = 1000)

# Rolling Window
rolling_full <- full_wide |>
  drop_na() |>
  mutate(
    coef_canada = slide_dbl(
      pick(everything()),
      \(df) tryCatch(
        coef(lm(us ~ canada + us_lag1, data = df))["canada"],
        error = function(e) NA
      ),
      .before = 23,
      .complete = TRUE
    )
  )

ggplot(rolling_full, aes(x = date, y = coef_canada)) +
  geom_line(colour = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  annotate("rect", xmin = as.Date("2006-01-01"), xmax = as.Date("2011-12-01"),
           ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "red") +
  annotate("rect", xmin = as.Date("2020-01-01"), xmax = as.Date("2025-12-01"),
           ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "blue") +
  annotate("text", x = as.Date("2009-01-01"), y = max(rolling_full$coef_canada, na.rm = TRUE),
           label = "2008 Financial Crisis", vjust = 1) +
  annotate("text", x = as.Date("2022-06-01"), y = max(rolling_full$coef_canada, na.rm = TRUE),
           label = "COVID", vjust = 1) +
  labs(title = "Rolling 24-Month Canada Coefficient — Full Sample",
       x = NULL, y = "Coefficient Estimate") +
  theme_minimal()

# Halfeye
full_data |>
  ggplot(aes(x = mom, fill = country)) +
  stat_halfeye(aes(colour = country), alpha = 0.5, position = "identity") +
  geom_vline(xintercept = 0, linetype = "dotted", colour = "purple") +
  scale_x_continuous(labels = percent_format(scale = 1)) +
  labs(title = "Distribution of M2 MoM Growth Rates — Full Sample",
       x = "MoM Growth (%)", y = NULL, fill = "country") +
  theme_minimal()

# QQ Plot
par(mfrow = c(1, 2))
qqnorm(filter(full_data, country == "US")$mom,     main = "QQ — US MoM")
qqline(filter(full_data, country == "US")$mom)
qqnorm(filter(full_data, country == "Canada")$mom, main = "QQ — Canada MoM")
qqline(filter(full_data, country == "Canada")$mom)


# ── 15. Crisis ARX(1) ─────────────────────────────────────────────────────────
full_wide <- full_wide |>
  mutate(crisis = case_when(
    date >= as.Date("1973-10-01") & date <= as.Date("1975-03-01") ~ 1,
    date >= as.Date("1980-01-01") & date <= as.Date("1982-12-01") ~ 1,
    date >= as.Date("1990-07-01") & date <= as.Date("1991-03-01") ~ 1,
    date >= as.Date("2001-03-01") & date <= as.Date("2002-12-01") ~ 1,
    date >= as.Date("2007-01-01") & date <= as.Date("2011-12-01") ~ 1,
    date >= as.Date("2020-01-01") & date <= as.Date("2023-12-01") ~ 1,
    TRUE ~ 0
  ))

arx_crisis <- lm(us ~ canada + us_lag1 + crisis, data = full_wide)
summary(arx_crisis)
# Results show Crisis dummy does not matter

# ── 16. Flipped ARX(1) ────────────────────────────────────────────────────────
# Flipped ARX(1) — event windows
arx1_gfc_flip   <- lm(canada ~ us + lag(canada, 1), data = gfc_wide)
arx1_covid_flip <- lm(canada ~ us + lag(canada, 1), data = covid_wide)

summary(arx1_gfc_flip)
summary(arx1_covid_flip)

# Flipped ARX(1) — full sample
arx_full_flip <- lm(canada ~ us + lag(canada, 1), data = full_wide)
summary(arx_full_flip)

# Flipped Granger
causality(var_gfc,   cause = "us", boot = TRUE, boot.runs = 1000)
causality(var_covid, cause = "us", boot = TRUE, boot.runs = 1000)
causality(var_full,  cause = "us", boot = TRUE, boot.runs = 1000)

# ARX(1) Fitted vs Actual Canada GFC and COVID
bind_rows(
  augment(arx1_gfc_flip) |>
    bind_cols(gfc_wide |> drop_na() |> dplyr::select(date)) |>
    mutate(event = "2008 Financial Crisis"),
  augment(arx1_covid_flip) |>
    bind_cols(covid_wide |> drop_na() |> dplyr::select(date)) |>
    mutate(event = "COVID")
) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = canada, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX(1) Fitted vs Actual Canada M2 MoM Growth",
       x = NULL, y = "MoM Growth (%)", colour = NULL) +
  theme_minimal()

# ARX(1) Fitted vs Actual Canada Everything
augment(arx_full_flip) |>
  bind_cols(full_wide |> filter(!is.na(lag(canada, 1))) |> dplyr::select(date)) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = canada, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  scale_y_continuous(labels = percent_format(scale = 1), limits = c(NA, 6)) +
  labs(title = "ARX(1) Fitted vs Actual Canada M2 MoM Growth — Full Sample",
       x = NULL, y = "MoM Growth (%)", colour = NULL) +
  theme_minimal()

# YoY
# YoY wide formats
gfc_wide_yoy <- gfc_data |>
  dplyr::select(date, yoy, country) |>
  pivot_wider(names_from = country, values_from = yoy) |>
  rename(us = US, canada = Canada) |>
  drop_na()

covid_wide_yoy <- covid_data |>
  dplyr::select(date, yoy, country) |>
  pivot_wider(names_from = country, values_from = yoy) |>
  rename(us = US, canada = Canada) |>
  drop_na()

full_wide_yoy <- full_data |>
  dplyr::select(date, yoy, country) |>
  pivot_wider(names_from = country, values_from = yoy) |>
  rename(us = US, canada = Canada) |>
  drop_na()

# GFC YoY
lag_gfc_yoy <- VARselect(gfc_wide_yoy[, c("us", "canada")], lag.max = 6)$selection["AIC(n)"]
var_gfc_yoy <- VAR(gfc_wide_yoy[, c("us", "canada")], p = lag_gfc_yoy)
normality.test(var_gfc_yoy)
causality(var_gfc_yoy, cause = "canada", boot = TRUE, boot.runs = 1000)
causality(var_gfc_yoy, cause = "us",     boot = TRUE, boot.runs = 1000)

# COVID YoY
lag_covid_yoy <- VARselect(covid_wide_yoy[, c("us", "canada")], lag.max = 6)$selection["AIC(n)"]
var_covid_yoy <- VAR(covid_wide_yoy[, c("us", "canada")], p = lag_covid_yoy)
normality.test(var_covid_yoy)
causality(var_covid_yoy, cause = "canada", boot = TRUE, boot.runs = 1000)
causality(var_covid_yoy, cause = "us",     boot = TRUE, boot.runs = 1000)

# Full Sample YoY
lag_full_yoy <- VARselect(full_wide_yoy[, c("us", "canada")], lag.max = 6)$selection["AIC(n)"]
var_full_yoy <- VAR(full_wide_yoy[, c("us", "canada")], p = lag_full_yoy)
normality.test(var_full_yoy)
causality(var_full_yoy, cause = "canada", boot = TRUE, boot.runs = 1000)
causality(var_full_yoy, cause = "us",     boot = TRUE, boot.runs = 1000)

# ── 17. YoY Spuriousness Test ─────────────────────────────────────────────────
# First difference YoY
full_wide_yoy <- full_wide_yoy |>
  mutate(
    us_d     = us     - lag(us, 1),
    canada_d = canada - lag(canada, 1)
  ) |>
  drop_na()

gfc_wide_yoy <- gfc_wide_yoy |>
  mutate(
    us_d     = us     - lag(us, 1),
    canada_d = canada - lag(canada, 1)
  ) |>
  drop_na()

covid_wide_yoy <- covid_wide_yoy |>
  mutate(
    us_d     = us     - lag(us, 1),
    canada_d = canada - lag(canada, 1)
  ) |>
  drop_na()

# VAR and Granger on differenced YoY
# GFC
lag_gfc_yoy_d <- VARselect(gfc_wide_yoy[, c("us_d", "canada_d")], lag.max = 6)$selection["AIC(n)"]
var_gfc_yoy_d <- VAR(gfc_wide_yoy[, c("us_d", "canada_d")], p = lag_gfc_yoy_d)
normality.test(var_gfc_yoy_d)
causality(var_gfc_yoy_d, cause = "canada_d", boot = TRUE, boot.runs = 1000)
causality(var_gfc_yoy_d, cause = "us_d",     boot = TRUE, boot.runs = 1000)

# COVID
lag_covid_yoy_d <- VARselect(covid_wide_yoy[, c("us_d", "canada_d")], lag.max = 6)$selection["AIC(n)"]
var_covid_yoy_d <- VAR(covid_wide_yoy[, c("us_d", "canada_d")], p = lag_covid_yoy_d)
normality.test(var_covid_yoy_d)
causality(var_covid_yoy_d, cause = "canada_d", boot = TRUE, boot.runs = 1000)
causality(var_covid_yoy_d, cause = "us_d",     boot = TRUE, boot.runs = 1000)

# Full Sample
lag_full_yoy_d <- VARselect(full_wide_yoy[, c("us_d", "canada_d")], lag.max = 6)$selection["AIC(n)"]
var_full_yoy_d <- VAR(full_wide_yoy[, c("us_d", "canada_d")], p = lag_full_yoy_d)
normality.test(var_full_yoy_d)
causality(var_full_yoy_d, cause = "canada_d", boot = TRUE, boot.runs = 1000)
causality(var_full_yoy_d, cause = "us_d",     boot = TRUE, boot.runs = 1000)

# ── 17. YoY Fitted vs Actual ──────────────────────────────────────────────────
# YoY wide formats with lag
gfc_wide_yoy <- gfc_wide_yoy |> mutate(us_lag1 = lag(us, 1), canada_lag1 = lag(canada, 1))
covid_wide_yoy <- covid_wide_yoy |> mutate(us_lag1 = lag(us, 1), canada_lag1 = lag(canada, 1))
full_wide_yoy <- full_wide_yoy |> mutate(us_lag1 = lag(us, 1), canada_lag1 = lag(canada, 1))

# ARX(1) YoY — original direction
arx_gfc_yoy   <- lm(us ~ canada + us_lag1, data = gfc_wide_yoy)
arx_covid_yoy <- lm(us ~ canada + us_lag1, data = covid_wide_yoy)
arx_full_yoy  <- lm(us ~ canada + us_lag1, data = full_wide_yoy)

summary(arx_gfc_yoy)
summary(arx_covid_yoy)
summary(arx_full_yoy)

# ARX(1) YoY — flipped direction
arx_gfc_yoy_flip   <- lm(canada ~ us + canada_lag1, data = gfc_wide_yoy)
arx_covid_yoy_flip <- lm(canada ~ us + canada_lag1, data = covid_wide_yoy)
arx_full_yoy_flip  <- lm(canada ~ us + canada_lag1, data = full_wide_yoy)

summary(arx_gfc_yoy_flip)
summary(arx_covid_yoy_flip)
summary(arx_full_yoy_flip)

# Fitted vs Actual — US YoY
bind_rows(
  augment(arx_gfc_yoy) |>
    bind_cols(gfc_wide_yoy |> drop_na(us_lag1) |> dplyr::select(date)) |>
    mutate(event = "2008 Financial Crisis"),
  augment(arx_covid_yoy) |>
    bind_cols(covid_wide_yoy |> drop_na(us_lag1) |> dplyr::select(date)) |>
    mutate(event = "COVID")
) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = us, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX(1) Fitted vs Actual US M2 YoY Growth",
       x = NULL, y = "YoY Growth (%)", colour = NULL) +
  theme_minimal()

# Fitted vs Actual — Canada YoY
bind_rows(
  augment(arx_gfc_yoy_flip) |>
    bind_cols(gfc_wide_yoy |> drop_na(canada_lag1) |> dplyr::select(date)) |>
    mutate(event = "2008 Financial Crisis"),
  augment(arx_covid_yoy_flip) |>
    bind_cols(covid_wide_yoy |> drop_na(canada_lag1) |> dplyr::select(date)) |>
    mutate(event = "COVID")
) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = canada, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  facet_wrap(~ event, scales = "free_x") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX(1) Fitted vs Actual Canada M2 YoY Growth",
       x = NULL, y = "YoY Growth (%)", colour = NULL) +
  theme_minimal()

# Full sample versions
augment(arx_full_yoy) |>
  bind_cols(full_wide_yoy |> drop_na(us_lag1) |> dplyr::select(date)) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = us, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX(1) Fitted vs Actual US M2 YoY Growth — Full Sample",
       x = NULL, y = "YoY Growth (%)", colour = NULL) +
  theme_minimal()

augment(arx_full_yoy_flip) |>
  bind_cols(full_wide_yoy |> drop_na(canada_lag1) |> dplyr::select(date)) |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = canada, colour = "Actual")) +
  geom_line(aes(y = .fitted, colour = "Fitted"), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dotted", colour = "purple") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(title = "ARX(1) Fitted vs Actual Canada M2 YoY Growth — Full Sample",
       x = NULL, y = "YoY Growth (%)", colour = NULL) +
  theme_minimal()
# These full sample plots are less interesting because in the summary() they have a massive R squared
# due to the fact that 11/12ths of the YoY growth rate are contained in the lag.