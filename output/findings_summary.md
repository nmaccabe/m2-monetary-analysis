# M2 Monetary Aggregate Growth Rate Analysis — Findings Summary

**US M2SL vs Canada M2+ (Gross, Seasonally Adjusted)**  
**Monthly Data: January 1970 — February 2026**  
*Seed: `set.seed()` used for reproducibility of bootstrap Granger results*

---

## Data

| | US | Canada |
|---|---|---|
| Series | FRED M2SL | Bank of Canada E1, V41552798 |
| Units | Billions USD, seasonally adjusted | Millions CAD, seasonally adjusted |
| Raw coverage | Jan 1959 — Mar 2026 | Jan 1968 — Feb 2026 |
| Overlapping sample | January 1970 — February 2026 | January 1970 — February 2026 |

Growth rates computed as:

```
MoM = (m2 / lag(m2, 1)  - 1) * 100
YoY = (m2 / lag(m2, 12) - 1) * 100
```

> **M2 Reclassification Note:** The May 2020 Fed reclassification moved savings deposits from non-M1 to M1 within M2. This was purely internal — the M2 aggregate level was unaffected. The COVID right tail is not a definitional artifact.

---

## Event Windows

| Event | Window | n (per country) |
|---|---|---|
| GFC | January 2006 — December 2011 | 72 |
| COVID | January 2019 — December 2025 | 84 |

---

## Reframing Note

Analysis framed as **comparative monetary analysis** rather than DFL counterfactual. Granger, VAR, and ARX results collectively argue against Canada being a credible counterfactual for the US — the two countries are largely independent monetary regimes that co-move during crises but are not exchangeable. The paper's central contribution is characterizing how the Canada-US monetary relationship evolves across crisis regimes, with the **rolling 24-month window coefficient as the centerpiece finding**.

---

## Simple OLS — MoM (Baseline)

$$US_t = \alpha + \beta_1 Canada_t + \epsilon_t$$

| Window | Canada coef | p-value | R² |
|---|---|---|---|
| GFC | 0.478 | 0.000484 *** | 0.161 |
| COVID | 1.597 | < 2e-16 *** | 0.631 |

---

## ARX(1) Model — MoM, Original Direction

$$US_t = \alpha + \beta_1 Canada_t + \beta_2 US_{t-1} + \epsilon_t$$

| Window | Canada coef | p-value | US lag coef | p-value | R² |
|---|---|---|---|---|---|
| GFC | 0.380 | 0.0106 * | 0.192 | 0.1175 (ns) | 0.192 |
| COVID | 1.077 | 5.85e-09 *** | 0.383 | 1.17e-05 *** | 0.712 |
| Full Sample | 0.185 | 6.95e-10 *** | 0.587 | < 2e-16 *** | 0.462 |

**GFC:** Canada marginally significant. No meaningful US persistence. US largely on its own trajectory.

**COVID:** Strong co-movement and strong US persistence. 1pp Canadian growth associated with 1.08pp US growth.

**Full Sample:** Canada has significant but secondary explanatory power. US is primarily autoregressive.

---

## ARX(1) Model — MoM, Flipped Direction

$$Canada_t = \alpha + \beta_1 US_t + \beta_2 Canada_{t-1} + \epsilon_t$$

| Window | US coef | p-value | Canada lag coef | p-value | R² |
|---|---|---|---|---|---|
| GFC | 0.154 | 0.0384 * | 0.655 | 1.71e-10 *** | 0.542 |
| COVID | 0.323 | 1.28e-10 *** | 0.217 | 0.0157 * | 0.659 |
| Full Sample | 0.246 | 2.12e-13 *** | 0.490 | < 2e-16 *** | 0.378 |

> **Asymmetry finding:** The Canada coefficient in the US model (1.077, COVID) is much larger than the US coefficient in the Canada model (0.323, COVID). Both countries respond to the same contemporaneous shock, but the US responds with greater magnitude — reflecting the larger US fiscal and monetary policy response, not causal amplification.

---

## Crisis ARX(1) — Full Sample With Crisis Dummy

$$US_t = \alpha + \beta_1 Canada_t + \beta_2 US_{t-1} + \beta_3 Crisis_t + \epsilon_t$$

Crisis periods: Oil Shock (1973-10 to 1975-03), Volcker (1980-01 to 1982-12), Gulf War (1990-07 to 1991-03), Dot-com (2001-03 to 2002-12), GFC (2007-01 to 2011-12), COVID (2020-01 to 2023-12)

| Term | Estimate | p-value |
|---|---|---|
| Canada | 0.183 | 1.09e-09 *** |
| US lag | 0.587 | < 2e-16 *** |
| Crisis dummy | 0.016 | 0.615 (ns) |
| R² | 0.462 | |

> Crisis dummy completely insignificant. Canada coefficient virtually unchanged from baseline ARX(1). The Canada-US relationship is **stable across regimes**.

---

## MoM VAR and Granger Causality (Bootstrap, 1000 runs)

**VAR residual normality (JB test) — all non-normal, bootstrap required:**

| Window | JB statistic | p-value |
|---|---|---|
| Full sample | 18,059 | < 2.2e-16 |
| GFC | 35.003 | 4.638e-07 |
| COVID | 194.45 | < 2.2e-16 |

**Bootstrap Granger results:**

| Window | Canada→US | US→Canada | Instantaneous |
|---|---|---|---|
| Full Sample | p = 0.143 (ns) | p = 0.007 ** | p = 7.15e-10 *** |
| GFC | p = 0.279 (ns) | p = 0.174 (ns) | p = 0.090 (ns) |
| COVID | p = 0.048 * | p = 0.031 * | p = 9.779e-06 *** |

> **GFC Note:** Parametric Canada→US p-value was 0.0497 — false positive due to non-normality. Bootstrap (p = 0.279) correctly fails to reject. Illustrates the importance of bootstrap Granger over standard F-test with non-normal residuals.

**Key finding (MoM):** Over the full sample the US reliably Granger-causes Canada but Canada does not. During COVID both directions marginally significant. During GFC neither direction significant. Instantaneous causality is the dominant channel.

---

## Impulse Response Functions — MoM

**GFC (Canada shock → US response):**

| Period | Response |
|---|---|
| t=1 | 0.000 (by construction) |
| t=2 | 0.071 (peak) |
| t=13 | 0.003 |

Lower CI positive throughout — statistically significant positive response.

**COVID (Canada shock → US response):**

| Period | Response |
|---|---|
| t=1 | 0.000 (by construction) |
| t=2 | 0.166 (peak) |
| t=4 | -0.041 (oscillates) |

Wide confidence bands crossing zero — statistically uncertain.

---

## YoY VAR and Granger Causality (Bootstrap, 1000 runs)

**VAR residual normality:**

| Window | JB statistic | p-value |
|---|---|---|
| GFC | 6.28 | 0.179 — **passes normality** |
| COVID | 97.94 | < 2.2e-16 |
| Full sample | 4,581.7 | < 2.2e-16 |

**Bootstrap Granger — YoY levels:**

| Window | Canada→US | US→Canada | Instantaneous |
|---|---|---|---|
| Full Sample | p = 0.022 * | p < 2.2e-16 *** | p = 1.491e-07 *** |
| GFC | p = 0.074 (90%) | p = 0.820 (ns) | p = 0.015 * |
| COVID | p = 0.003 ** | p = 0.013 * | p = 8.15e-06 *** |

**Bootstrap Granger — YoY first differenced:**

| Window | Canada→US | US→Canada | Instantaneous |
|---|---|---|---|
| Full Sample | p = 0.018 * | p = 0.002 ** | p = 7.598e-08 *** |
| GFC | p = 0.093 (90%) | p = 0.310 (ns) | p = 0.007 ** |
| COVID | p = 0.004 ** | p = 0.024 * | p = 1.743e-05 *** |

YoY bidirectionality survives first differencing — **not spurious**.

**MoM vs YoY contrast:**
- **Short run (MoM):** US leads Canada unidirectionally over full sample
- **Medium term (YoY):** Bidirectional feedback over full sample and COVID
- **GFC YoY:** Canada weakly leads US — opposite direction to MoM

---

## ARX(1) Model — YoY

> ⚠️ **Important Methodological Note on YoY ARX(1)**
>
> The artificially high R² values in the YoY ARX(1) models are a **mechanical artifact**, not evidence of strong model fit. YoY growth at month *t* shares 11 of 12 months with YoY growth at month *t-1*. This means the lagged dependent variable contains 11/12 of the same information as the current value by construction. The lag coefficient approaches 1.0 and R² inflates toward 1.0 regardless of whether Canada has genuine explanatory power. This is confirmed by the full sample result where the Canada coefficient is statistically insignificant (p = 0.312) despite R² of 0.971. **MoM is the preferred specification.**

**Original direction (US ~ Canada + US lag):**

| Window | Canada coef | p-value | R² |
|---|---|---|---|
| GFC | -0.030 | 0.397 (ns) | 0.914 ⚠️ |
| COVID | 0.571 | 1.79e-07 *** | 0.979 ⚠️ |
| Full Sample | 0.006 | 0.312 (ns) | 0.971 ⚠️ |

**Flipped direction (Canada ~ US + Canada lag):**

| Window | US coef | p-value | R² |
|---|---|---|---|
| GFC | 0.133 | 0.000182 *** | 0.975 ⚠️ |
| COVID | 0.106 | 0.000555 *** | 0.973 ⚠️ |
| Full Sample | 0.022 | 0.000733 *** | 0.985 ⚠️ |

---

## Rolling 24-Month Canada Coefficient (MoM ARX(1), Full Sample)

![Rolling Window Full Sample](figures/RollingWindowFull.png)

| Period | Observation |
|---|---|
| Pre-2000 | Coefficient oscillates around zero — no persistent relationship |
| 2003–2006 | Drifts positive — increasing integration pre-GFC |
| GFC | Spikes to ~1.5 then collapses to ~-1.2 by 2011 |
| COVID | Largest positive spike in 57-year sample (~2.0), collapses post-2022 |

> **Key finding:** Canada-US monetary coupling is episodic and crisis-driven, not structural. The relationship breaks down quickly after each crisis.

---

## Normality Tests (JB)

**MoM series — non-normal across all windows:**

| Window | JB | p-value |
|---|---|---|
| Full sample | 18,059 | < 2.2e-16 |
| GFC | 35.003 | 4.638e-07 |
| COVID | 194.45 | < 2.2e-16 |

- US 99th percentile MoM: 5.31% vs Canada 99th percentile: 2.35%
- Distributions nearly identical up to 95th percentile
- Divergence concentrated in extreme tail observations only

**YoY series:**

| Window | JB | p-value |
|---|---|---|
| GFC | 6.28 | 0.179 — normal ✓ |
| COVID | 97.94 | < 2.2e-16 |
| Full sample | 4,581.7 | < 2.2e-16 |

---

## Distributional Analysis

![Crisis Growth Distributions](output/figures/CrisisGrowthDistributions.png)

- **GFC:** Distributions similar in location and shape for both countries
- **COVID:** US distribution flatter with fat right tail extending to 6%+ MoM; Canada distribution taller and narrower, concentrated around 0.5–1%
- Distributional difference concentrated in extreme right tail (99th+ percentile)
- Not a wholesale distributional shift — bulk of distributions nearly identical

---

## Limitations

1. Window selection is arbitrary — results may be sensitive to different dates
2. Exchange rate channel ignored — CAD/USD movements affect comparability
3. Canada was not unaffected by US spillovers — not a clean control
4. M2 vs M2+ definitional differences remain despite best available matching
5. Both series seasonally adjusted by different agencies using different methods
6. Rolling window estimates use only 24 observations — wide uncertainty bands
7. Small sample in event windows (72–84 obs) — thin for VAR estimation
8. Crisis dummy insignificance may reflect cancellation across heterogeneous events
9. Bootstrap Granger p-values vary slightly across runs despite seeding — treat as approximate

---

## Robustness

- Full sample (Jan 1970 — Feb 2026) results consistent with event windows
- Bootstrap Granger robust to non-normality — corrected false positive in GFC
- ARX(1) residual ACF shows white noise in both event windows — model well specified
- M2 reclassification confirmed not to affect aggregate M2 level
- Crisis ARX(1) confirms Canada coefficient stable across regimes (crisis dummy p = 0.615)
- Both MoM and YoY specifications estimated — directional findings consistent
- Both directions of ARX(1) estimated — asymmetry confirmed
- YoY bidirectionality survives first differencing — confirmed not spurious

---

*Author: N. MacCabe — Independent Research, May 2026*  
*Repo: https://github.com/nmaccabe/m2-monetary-analysis*
