# M2 Monetary Aggregate Growth Rate Analysis — Findings Summary

**US M2SL compared with Canada M2+ (gross, seasonally adjusted)**  
**Monthly data: January 1970 to February 2026**  
*The bootstrap Granger tests use `set.seed()` so that the results can be reproduced.*

---

## Main Finding

US and Canadian money growth often move together during major crises, but the relationship is not consistently strong over time. The rolling 24-month estimates show that the connection becomes much stronger during periods such as the global financial crisis and COVID-19, then weakens soon afterward.

This means Canada is not a reliable stand-in for what would have happened in the United States. The two countries have separate monetary systems, even though they sometimes respond to the same large economic shocks.

---

## Data

| | United States | Canada |
|---|---|---|
| Series | FRED M2SL | Bank of Canada E1, V41552798 |
| Units | Billions of USD, seasonally adjusted | Millions of CAD, seasonally adjusted |
| Raw coverage | January 1959 to March 2026 | January 1968 to February 2026 |
| Overlapping sample used | January 1970 to February 2026 | January 1970 to February 2026 |

Two growth measures are used:

```text
MoM = (m2 / lag(m2, 1)  - 1) * 100
YoY = (m2 / lag(m2, 12) - 1) * 100
```

- **Month-over-month (MoM)** measures the percentage change from the previous month.
- **Year-over-year (YoY)** measures the percentage change from the same month one year earlier.

> **May 2020 M2 reclassification:** The Federal Reserve moved savings deposits from non-M1 to M1, but both categories remained inside M2. The total M2 level was therefore unaffected. The unusually large positive observations during COVID-19 are not caused by this classification change.

---

## Event Windows

The analysis gives special attention to two crisis periods:

| Event | Window | Observations per country |
|---|---|---|
| Global financial crisis (GFC) | January 2006 to December 2011 | 72 |
| COVID-19 period | January 2019 to December 2025 | 84 |

---

## How to Read the Results

- A **coefficient** shows the estimated size and direction of a relationship.
- A **p-value** measures how strongly the data reject a zero relationship. Smaller values provide stronger evidence.
- `***`, `**`, and `*` mark progressively weaker conventional levels of statistical significance.
- `(ns)` means the estimate is not statistically significant at the usual 5% level.
- **R²** is the share of variation explained by a model. A high R² is not always proof that a model is useful, especially when variables overlap mechanically over time.
- **Granger causality** means that past values of one series help predict another series. It does **not** prove true economic causation.

---

## Research Framing

The project is best described as a **comparison of US and Canadian monetary growth**, rather than a formal counterfactual study.

The ARX, VAR, and Granger results show that Canada is not a credible control group for the United States. The countries sometimes move together, especially during crises, but their monetary systems are not interchangeable.

The central contribution is the analysis of how this relationship changes over time. The **rolling 24-month Canada coefficient** is the clearest result because it shows when the countries become more closely connected and when that connection breaks down.

---

## Simple OLS Model — Month-over-Month Growth

The baseline model asks whether Canadian M2+ growth in a given month is associated with US M2 growth in the same month:

$$US_t = \alpha + \beta_1 Canada_t + \epsilon_t$$

| Window | Canada coefficient | p-value | R² |
|---|---|---|---|
| GFC | 0.478 | 0.000484 *** | 0.161 |
| COVID | 1.597 | < 2e-16 *** | 0.631 |

The relationship is positive in both periods, but it is much stronger during COVID-19. The COVID model also explains a much larger share of monthly US M2 growth.

---

## ARX(1) Model — Predicting US Month-over-Month Growth

An ARX model adds the previous month's US growth rate to the baseline model. This separates the relationship with Canada from the tendency of US money growth to continue from one month to the next.

$$US_t = \alpha + \beta_1 Canada_t + \beta_2 US_{t-1} + \epsilon_t$$

| Window | Canada coefficient | p-value | US lag coefficient | p-value | R² |
|---|---|---|---|---|---|
| GFC | 0.380 | 0.0106 * | 0.192 | 0.1175 (ns) | 0.192 |
| COVID | 1.077 | 5.85e-09 *** | 0.383 | 1.17e-05 *** | 0.712 |
| Full sample | 0.185 | 6.95e-10 *** | 0.587 | < 2e-16 *** | 0.462 |

**GFC:** The Canada coefficient is statistically significant, although only modestly so. The lagged US coefficient is not significant, which suggests little evidence that US monthly growth was persistent during this window.

**COVID:** Canadian and US growth move closely together, and US growth also shows strong persistence. A 1 percentage-point increase in Canadian monthly M2+ growth is associated with about a 1.08 percentage-point increase in US M2 growth, holding the previous month's US growth constant.

**Full sample:** Canada provides statistically significant information, but its coefficient is much smaller than during COVID-19. US money growth is explained more strongly by its own previous value.

---

## ARX(1) Model — Predicting Canadian Month-over-Month Growth

The direction is reversed here. The model asks whether current US M2 growth is associated with Canadian M2+ growth after accounting for Canada's previous monthly growth rate.

$$Canada_t = \alpha + \beta_1 US_t + \beta_2 Canada_{t-1} + \epsilon_t$$

| Window | US coefficient | p-value | Canada lag coefficient | p-value | R² |
|---|---|---|---|---|---|
| GFC | 0.154 | 0.0384 * | 0.655 | 1.71e-10 *** | 0.542 |
| COVID | 0.323 | 1.28e-10 *** | 0.217 | 0.0157 * | 0.659 |
| Full sample | 0.246 | 2.12e-13 *** | 0.490 | < 2e-16 *** | 0.378 |

> **Asymmetry during COVID:** The Canada coefficient in the US model is 1.077, while the US coefficient in the Canada model is 0.323. Both countries appear to respond to the same large shock, but the US response is larger. This is consistent with the larger US fiscal and monetary expansion during COVID-19. It should not be interpreted as proof that Canada caused a larger US response.

---

## ARX(1) Model With a Crisis Indicator

This full-sample model adds a crisis indicator that equals one during the selected crisis periods and zero otherwise:

$$US_t = \alpha + \beta_1 Canada_t + \beta_2 US_{t-1} + \beta_3 Crisis_t + \epsilon_t$$

The crisis periods are:

- Oil shock: October 1973 to March 1975
- Volcker period: January 1980 to December 1982
- Gulf War: July 1990 to March 1991
- Dot-com period: March 2001 to December 2002
- Global financial crisis: January 2007 to December 2011
- COVID-19: January 2020 to December 2023

| Term | Estimate | p-value |
|---|---|---|
| Canada | 0.183 | 1.09e-09 *** |
| US lag | 0.587 | < 2e-16 *** |
| Crisis indicator | 0.016 | 0.615 (ns) |
| R² | 0.462 | |

The crisis indicator is not statistically significant, and the Canada coefficient is almost unchanged from the basic full-sample ARX model.

This does not mean that the Canada-US relationship is constant at every point in time. It means that a single indicator applied to several very different crises does not produce a common average shift. The rolling-window results below show substantial short-term changes that a single crisis indicator cannot capture.

---

## VAR and Granger Causality — Month-over-Month Growth

A **vector autoregression (VAR)** models US and Canadian growth together, allowing the past values of both series to help predict each country.

The Granger tests ask whether past values from one country improve predictions for the other country. Because the residuals are highly non-normal, the reported p-values come from 1,000 bootstrap runs rather than relying only on the usual parametric F-test.

### Residual normality tests

The Jarque-Bera (JB) test rejects normality in every window:

| Window | JB statistic | p-value |
|---|---|---|
| Full sample | 18,059 | < 2.2e-16 |
| GFC | 35.003 | 4.638e-07 |
| COVID | 194.45 | < 2.2e-16 |

### Bootstrap Granger results

| Window | Canada → US | US → Canada | Instantaneous relationship |
|---|---|---|---|
| Full sample | p = 0.143 (ns) | p = 0.007 ** | p = 7.15e-10 *** |
| GFC | p = 0.279 (ns) | p = 0.174 (ns) | p = 0.090 (ns) |
| COVID | p = 0.048 * | p = 0.031 * | p = 9.779e-06 *** |

> **Why the bootstrap matters:** For the GFC, the ordinary parametric Canada-to-US test gives a p-value of 0.0497, which would normally be treated as significant. The bootstrap p-value is 0.279, so the result is no longer significant after accounting for the non-normal residuals. The standard test therefore appears to produce a false positive in this case.

**Main month-over-month result:**

- Across the full sample, past US growth helps predict Canadian growth, but past Canadian growth does not reliably predict US growth.
- During COVID-19, both directions are marginally significant.
- During the GFC, neither direction is significant.
- The strongest and most consistent relationship is contemporaneous: the two countries often react within the same month rather than through a clear lagged transmission process.

---

## Impulse Response Functions — Month-over-Month Growth

An **impulse response function (IRF)** estimates how one series responds over time after an unexpected change, or “shock,” in the other series.

### GFC: Canadian shock followed by the US response

| Period | Response |
|---|---|
| t = 1 | 0.000, by construction |
| t = 2 | 0.071, peak response |
| t = 13 | 0.003 |

The lower confidence bound remains above zero throughout the response period. This indicates a statistically significant positive US response to a Canadian shock in the GFC model.

### COVID: Canadian shock followed by the US response

| Period | Response |
|---|---|
| t = 1 | 0.000, by construction |
| t = 2 | 0.166, peak response |
| t = 4 | -0.041, showing an oscillating response |

The confidence bands are wide and cross zero. The estimated response is therefore statistically uncertain even though the point estimate is larger than in the GFC model.

---

## VAR and Granger Causality — Year-over-Year Growth

The same VAR and bootstrap Granger approach is also applied to year-over-year growth.

### Residual normality tests

| Window | JB statistic | p-value |
|---|---|---|
| GFC | 6.28 | 0.179 — passes normality |
| COVID | 97.94 | < 2.2e-16 |
| Full sample | 4,581.7 | < 2.2e-16 |

Only the GFC year-over-year model passes the normality test.

### Bootstrap Granger results using year-over-year levels

| Window | Canada → US | US → Canada | Instantaneous relationship |
|---|---|---|---|
| Full sample | p = 0.022 * | p < 2.2e-16 *** | p = 1.491e-07 *** |
| GFC | p = 0.074, significant at the 10% level (90% confidence) | p = 0.820 (ns) | p = 0.015 * |
| COVID | p = 0.003 ** | p = 0.013 * | p = 8.15e-06 *** |

### Bootstrap Granger results using first-differenced year-over-year growth

First differencing measures the change in the year-over-year growth rate from one month to the next. This check helps determine whether the original year-over-year result is caused only by persistence in the series.

| Window | Canada → US | US → Canada | Instantaneous relationship |
|---|---|---|---|
| Full sample | p = 0.018 * | p = 0.002 ** | p = 7.598e-08 *** |
| GFC | p = 0.093, significant at the 10% level (90% confidence) | p = 0.310 (ns) | p = 0.007 ** |
| COVID | p = 0.004 ** | p = 0.024 * | p = 1.743e-05 *** |

The two-way predictive relationship in year-over-year growth remains after first differencing. This suggests that it is not only a spurious result caused by highly persistent year-over-year series.

### Month-over-month compared with year-over-year results

- **Short run, measured by MoM:** The US leads Canada in the full sample, while Canada does not reliably lead the US.
- **Medium term, measured by YoY:** The relationship is two-way in the full sample and during COVID-19.
- **GFC YoY result:** Canada weakly leads the US, which is the opposite direction from the full-sample MoM result.

---

## ARX(1) Model — Year-over-Year Growth

> **Important warning about the year-over-year ARX results**
>
> The very high R² values in these models are mainly a mechanical feature of year-over-year growth, not proof of exceptional model performance. Growth at month *t* compares the current month with the same month one year earlier. Growth at month *t - 1* uses 11 of the same 12 underlying months. The current and lagged growth rates therefore share most of their information by construction.
>
> This overlap pushes the lag coefficient toward 1.0 and can push R² close to 1.0 even when the Canadian variable adds little useful information. In the full-sample US model, for example, the Canada coefficient is not statistically significant (`p = 0.312`) even though R² is 0.971. For this reason, **month-over-month growth is the preferred ARX specification**.

### Predicting US year-over-year growth

| Window | Canada coefficient | p-value | R² |
|---|---|---|---|
| GFC | -0.030 | 0.397 (ns) | 0.914 ⚠️ |
| COVID | 0.571 | 1.79e-07 *** | 0.979 ⚠️ |
| Full sample | 0.006 | 0.312 (ns) | 0.971 ⚠️ |

### Predicting Canadian year-over-year growth

| Window | US coefficient | p-value | R² |
|---|---|---|---|
| GFC | 0.133 | 0.000182 *** | 0.975 ⚠️ |
| COVID | 0.106 | 0.000555 *** | 0.973 ⚠️ |
| Full sample | 0.022 | 0.000733 *** | 0.985 ⚠️ |

---

## Rolling 24-Month Canada Coefficient

This analysis repeatedly estimates the month-over-month US ARX model using only the most recent 24 months of data. It shows how the estimated Canadian coefficient changes over time instead of forcing one average relationship onto the entire sample.

![Rolling Window Full Sample](figures/RollingWindowFull.png)

| Period | What the estimate shows |
|---|---|
| Before 2000 | The coefficient moves around zero, with no lasting relationship |
| 2003 to 2006 | The coefficient gradually becomes positive before the GFC |
| GFC | It rises to about 1.5, then falls to about -1.2 by 2011 |
| COVID | It reaches the largest positive value in the 57-year sample, about 2.0, then falls sharply after 2022 |

> **Central finding:** The connection between Canadian and US money growth is temporary and strongly affected by crisis periods. It is not a stable, permanent relationship. After each major crisis, the estimated connection weakens quickly.

---

## Distribution and Normality Tests

### Month-over-month growth

The JB test rejects a normal distribution in every window:

| Window | JB statistic | p-value |
|---|---|---|
| Full sample | 18,059 | < 2.2e-16 |
| GFC | 35.003 | 4.638e-07 |
| COVID | 194.45 | < 2.2e-16 |

Additional distribution results:

- The 99th percentile of US monthly growth is 5.31%, compared with 2.35% for Canada.
- The distributions are nearly identical up to the 95th percentile.
- Most of the difference comes from a small number of extreme observations in the right tail.

### Year-over-year growth

| Window | JB statistic | p-value |
|---|---|---|
| GFC | 6.28 | 0.179 — normal ✓ |
| COVID | 97.94 | < 2.2e-16 |
| Full sample | 4,581.7 | < 2.2e-16 |

---

## Crisis Growth Distributions

![Crisis Growth Distributions](figures/CrisisGrowthDistributions.png)

- **GFC:** The US and Canadian distributions have similar centres and shapes.
- **COVID:** The US distribution is flatter and has a large right tail extending beyond 6% monthly growth. The Canadian distribution is taller and narrower, with most observations concentrated around 0.5% to 1.0%.
- The difference is concentrated mainly above the 99th percentile.
- The overall distributions did not shift apart completely. Most observations remain fairly similar, with the largest difference coming from a small number of extreme US values.

---

## Limitations

1. The crisis windows are chosen by the researcher, so different start and end dates could change the results.
2. The analysis does not model the CAD/USD exchange rate, even though exchange-rate movements may affect comparisons between the countries.
3. Canada was exposed to US spillovers and is therefore not a clean, unaffected control group.
4. US M2 and Canadian M2+ are the closest available measures, but they are not defined in exactly the same way.
5. The Federal Reserve and the Bank of Canada seasonally adjust their series separately and may use different methods.
6. Each rolling estimate uses only 24 observations, which creates wide uncertainty bands.
7. The event windows contain only 72 to 84 observations per country, which is a small sample for VAR estimation.
8. The insignificant crisis indicator may combine several crises with different effects that cancel one another out on average.
9. Bootstrap Granger p-values can change slightly across runs even with a fixed seed, so they should be treated as approximate.

---

## Robustness Checks

- The full-sample results from January 1970 to February 2026 are broadly consistent with the event-window results.
- Bootstrap Granger tests account for non-normality and correct the apparent GFC false positive from the standard parametric test.
- The residual autocorrelation functions for the ARX(1) models show approximately white-noise residuals in both event windows, supporting the model specification.
- The May 2020 Federal Reserve reclassification does not change the total M2 level.
- The crisis ARX model leaves the Canada coefficient almost unchanged and gives a crisis-indicator p-value of 0.615.
- Both month-over-month and year-over-year models are estimated, and their directional results are broadly consistent once their different time horizons are recognized.
- Both directions of the ARX model are estimated, confirming that the relationship is asymmetric.
- The two-way year-over-year Granger result remains after first differencing, which suggests that it is not purely spurious.

---

*Author: N. MacCabe — Independent Research, May 2026*  
*Repository: https://github.com/nmaccabe/m2-monetary-analysis*
