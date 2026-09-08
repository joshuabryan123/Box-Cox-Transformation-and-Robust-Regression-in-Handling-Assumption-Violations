# Box-Cox Transformation and Robust Regression in Handling Assumption Violations 🌴📊

An R-based statistical analysis project focusing on handling non-normality and influential observations (outliers/leverage) in Multiple Linear Regression (MLR) models. The case study models **Foreign Exchange Proceeds (Devisa Hasil Ekspor - DHE)** from Indonesia’s processed palm oil exports in 2023.

---

## 📌 Background

Multiple Linear Regression requires strict adherence to Gauss-Markov and normality assumptions. However, international trade data frequently violates these assumptions due to extreme economic disparities between trading partners. In modeling Indonesia's processed palm oil export proceeds across 129 partner countries, initial OLS regression suffered severe **non-normality of residuals** and the presence of **influential observations (outliers & leverage points)**.

This project demonstrates a robust statistical workflow combining **Box-Cox Transformation**, **Best Subset Selection**, and **S-Estimation Robust Regression** to produce a stable, highly reliable predictive model.

---

## 📁 Dataset & Variables

* **Sample Size:** Secondary data from 129 trade partner countries in 2023 (sourced from UN Comtrade, ITC Trademap, World Bank, CEPII).
* **Response Variable ($Y$):** Processed Palm Oil Export Proceeds (DHE) in hundreds of thousands USD.

| Variable | Description | Unit | Source |
| :--- | :--- | :--- | :--- |
| **$Y$** | Export Proceeds (DHE) | $100,000 USD | UN Comtrade |
| **$X_1$** | Import Tariff | Percentage (%) | ITC Trademap |
| **$X_2$** | Export Price | USD/ton | ITC Trademap |
| **$X_3$** | Real GDP per Capita | USD | World Bank |
| **$X_4$** | Destination Country Population | Thousand people | World Bank |
| **$X_5$** | Real Exchange Rate | LCU/USD | World Bank |
| **$X_6$** | Geographic Distance | Km | CEPII |
| **$X_7$** | Trade Agreement Status | Dummy (1 = Has agreement, 0 = Otherwise) | ITC Trademap |
| **$X_8$** | Non-Tariff Measures (NTM) | Unit count | ITC Trademap |

---

## 🛠 Analysis Methodology

1. **Exploratory Data Analysis & Diagnostic Checking:** Detection of multicollinearity (VIF) and influential points using $h_{ii}$, $r_i$, and DFFITS.
2. **Initial OLS Modeling & Classical Assumption Tests:** Evaluating Normality (Shapiro-Wilk), Homoscedasticity (Breusch-Pagan), and Autocorrelation (Durbin-Watson).
3. **Box-Cox Transformation:** Applied to response variable $Y$ ($\lambda = 0.06$) to resolve non-normal residual distribution.
4. **Best Subset Selection:** Evaluated $2^8 = 256$ model combinations using AIC, Mallow’s $C_p$, and Adjusted $R^2$ to select optimal predictors.
5. **Robust Regression (S-Estimator):** Utilized Tukey's Bisquare weighting ($c = 1.548$, $50\%$ breakdown point) to mitigate residual outlier effects.
6. **Back-Transformation & Model Interpretation:** Converting the final parameter estimates back to original units for policy insights.

---

## 📈 Key Results

| Metric / Stage | Initial OLS Model | Post Box-Cox & Selection | **Final Robust S-Estimation** |
| :--- | :--- | :--- | :--- |
| **Normality ($p$-value)** | $0.000$ ❌ | $0.025$ ❌ | **$0.709$** ✅ |
| **Homoscedasticity ($p$-value)** | $0.061$ ✅ | $0.064$ ✅ | **$0.064$** ✅ |
| **Autocorrelation ($p$-value)** | $0.549$ ✅ | $0.757$ ✅ | **$0.811$** ✅ |
| **Adjusted $R^2$** | $49.95\%$ | $41.38\%$ | **$80.83\%$** 🚀 |
| **AIC / RSE** | — | AIC: $656.879$[cite: 1] | **RSE: $3.086$** |

* **Final Model Predictors:** Best subset selected $X_1, X_2, X_3, X_4, X_8$.
* **Significant Predictors ($\alpha = 5\%$):** 
  * **Export Price ($X_2$):** Negative significant effect ($p = 0.002$).
  * **Population ($X_4$):** Positive significant effect ($p = 0.003$).
  * **Non-Tariff Measures ($X_8$):** Positive significant effect ($p = 0.000$).

---

## 💡 Conclusions & Recommendations

* **Methodological Insight:** Box-Cox transformation alone was insufficient to satisfy residual normality[cite: 1]. Pairing Box-Cox with **S-estimator Robust Regression** effectively neutralized influential outliers, boosting explanatory power (Adjusted $R^2$) from $49.95\%$ to **$80.83\%$** while satisfying all classical linear regression assumptions[cite: 1].
* **Policy Recommendation:** Government export strategies should maintain competitive and stable palm oil prices in international markets[cite: 1]. High-population countries represent key volume drivers, and compliance with non-tariff regulations enhances market acceptance[cite: 1].
* **Future Work:** Consider incorporating **Geographically Weighted Regression (GWR)** to account for spatial heterogeneity across trade partner regions[cite: 1].
