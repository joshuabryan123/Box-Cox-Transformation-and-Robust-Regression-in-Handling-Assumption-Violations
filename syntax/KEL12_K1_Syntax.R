---
  title: "**SYNTAX KELOMPOK 3 ANREG**"
author: "ALL IN AMPE TETES TERAKHIR"
date: "2025-06-02"
output:
  html_document:
  always_allow_html: true
toc: true
toc_float: true
self_contained: true
pdt_document:
  toc: true
number_sections: true
latex_engine: xelatex
extra_dependencies: ["float", "xcolor", "graphicx"]
css: style2.css
editor_options:
  markdown:
  wrap: 72
---
  
  # **LIBRARY**
  
  ```{r}
library(readxl)
library(ggplot2)
library(GGally)
library(dplyr)
library(car)
library(lmtest)
library(stargazer)
library(olsrr)
library(e1071)
library(MASS)
library(tidyverse)
library(mgcv)
library(fixest)
library(robustbase)
library(ggExtra)
library(patchwork)
library(ggpubr)
library(plotly)
```


# **PENYIAPAN DATA**
```{r}
pendapatan <- read_xlsx("C:/Document/SEMESTER 4/ANREG/PROJEK/REFERENSI MINYAK SAWIT OLAHAN/dtbaru.xlsx")
pendapatan
```


```{r}
dt <- pendapatan
dt$X6 <- as.numeric(gsub("[^0-9.-]", "", dt$X6))
str(dt)
```

```{r}
colSums(is.na(dt))
```

```{r}
View(dt)
```

# **EKSPLORASI ngetes**
## Boxplot

```{r}
plot_ly(x = ~dt$Y,
        type = "box",
        orientation = "h",
        boxpoints = "outliers", # tampilkan outlier
        marker = list(color = "black"),
        fillcolor = "gray",
        line = list(color = "black")) %>%
  layout(
    xaxis = list(title = "Devisa Hasil Ekspor (Ratus ribu US$)"),
    yaxis = list(title = ""),
    showlegend = FALSE
  )

```

```{r}
Q1 <- quantile(dt$Y, 0.25)
Q3 <- quantile(dt$Y, 0.75)
IQR <- Q3 - Q1

batas_bawah <- Q1 - 1.5 * IQR
batas_atas <- Q3 + 1.5 * IQR

outliers <- dt$Y[dt$Y < batas_bawah | dt$Y > batas_atas]
outliers_index <- which(dt$Y < batas_bawah | dt$Y > batas_atas)

cat("Index data outlier:\n")
print(outliers_index)

cat("\nNilai data outlier:\n")
print(outliers)

```


# **PEMODELAN AWAL**
```{r}
ngetes <- lm(formula = Y~., data = dt)
summary(ngetes)
```
# **MULTIKOLINEARITAS**
```{r}
vif(ngetes)
```

# **AMATAN TAK BIASA**

```{r}
ri_stud <- rstudent(ngetes)
ri_stan <- rstandard(ngetes)
hii_fungsi <- hatvalues(ngetes)

#manual
X <- model.matrix(ngetes)
X_inv_xt <- X %*% ginv(t(X) %*% X) %*% t(X)
hii_manual <- diag(X_inv_xt)
anova_model <- anova(ngetes)
s <- sqrt(anova_model["Residuals", "Mean Sq"])
ei <- ngetes$residuals
ri_manual <- ei/(s*sqrt(1-hii_manual))

nilai <- data.frame(ri_stud, ri_stan, ri_manual, hii_fungsi, hii_manual)
nilai
```


## Pencilan

```{r}
for (i in 1:dim(nilai)[1]){
  absri <- abs(nilai[,2])
  pencilan <- which(absri > 2)
}
pencilan
```

## Leverage

```{r}
n <- dim(dt)[1]
p <- length(ngetes$coefficients)

for (i in 1:dim(nilai)[1]){
  cutoff <- 2*p/n
  titik_leverage <- which(hii_fungsi > cutoff)
}

titik_leverage
```

```{r}
ols_plot_resid_lev(ngetes)
```

## Amatan Berpengaruh

```{r}
DFFITSi <- dffits(ngetes)

amatan_berpengaruh <- vector("list", dim(nilai)[1])
for (i in 1:dim(nilai)[1]) {
  cutoff <- 2 * sqrt((p / n))
  amatan_berpengaruh[[i]] <- which(abs(DFFITSi) > cutoff)
}
berpengaruh <- unlist(amatan_berpengaruh)
amatan_berpengaruh <- sort(unique(berpengaruh))
amatan_berpengaruh
```

```{r}
pengaruh <- c(1,6,24,60,86,105,110,116)

semua_kombinasi <- unlist(
  lapply(1:length(pengaruh), function(k) combn(pengaruh, k, simplify = FALSE)),
  recursive = FALSE
)

hasil_model <- map_df(semua_kombinasi, function(amts) {
  dt_subset <- dt %>% slice(-amts)
  model <- lm(Y ~ ., data = dt_subset)
  
  preds <- predict(model, newdata = dt_subset)
  rmse <- sqrt(mean((dt_subset$Y - preds)^2))
  
  tibble(
    dibuang = paste(sort(amts), collapse = ", "),
    AIC = AIC(model),
    Adj_R2 = summary(model)$adj.r.squared,
    RMSE = rmse
  )
})

terbaik_AIC <- hasil_model %>% arrange(AIC) %>% slice(1)
terbaik_R2 <- hasil_model %>% arrange(desc(Adj_R2)) %>% slice(1)

print("Model terbaik berdasarkan AIC:")
print(terbaik_AIC)

print("Model terbaik berdasarkan Adjusted R²:")
print(terbaik_R2)

```

# **UJI ASUMSI AWAL**
## $E(e_i) = 0$
```{r}
t.test(ngetes$residuals,mu = 0,conf.level = 0.95)
```

## Normalitas
<br>
  $H_0$ : Residual berdistribusi normal <br> $H_1$ : Residual tidak berdistribusi normal<br>
  ```{r}
plot(ngetes,2)
shapiro.test(ngetes$residuals)

data_stand <- scale(dt$Y)
ks.test(data_stand, "pnorm")
```

## Homogenitas
<br>
  $H_0$ : Ragam sisaan konstan (homoskedastisitas) <br> $H_1$ : Ragam sisaan tidak konstan (Heteroskedastisitas)<br>
  ```{r}
plot(ngetes,1)
bptest(ngetes)
```

## Plot sisaan terhadap Urutan
<br>
  $H_0$ : Sisaan saling bebas (Tidak ada autokorelasi) <br> $H_1$ : Sisaan tidak saing bebas (Autokorelasi)<br>
  ```{r}
plot(x = 1:dim(dt)[1],
     y = ngetes$residuals,
     type = 'b', 
     ylab = "Residuals",
     xlab = "Observation")

dwtest(ngetes)
```



# **PENANGANAN : TRANSFORMASI BOXCOX**
```{r}
bc_model <- boxcox(Y~., data = dt,
                   lambda = seq(-2, 2, by = 0.1))
(optimal_lambda <- bc_model$x[which.max(bc_model$y)])
```


```{r}
dt$Y_tr <- (((dt$Y)^optimal_lambda)-1)/optimal_lambda
```

```{r}
kedua <- lm(Y_tr~X1+X2+X3+X4+X5+X6+X7+X8, data = dt)
summary(kedua)
```

# **SELEKSI PEUBAH**

```{r}
bs <- ols_step_best_subset(kedua)
bs
```

```{r}
Keempat <- lm(Y_tr~ X1+X2+X3+X4+X8, data = dt)
summary(Keempat)
```



# **UJI ASUMSI SETELAH PENANGANAN DAN SUBSET PEUBAH**
## $E(e_i) = 0$
```{r}
t.test(Keempat$residuals,mu = 0,conf.level = 0.95)
```

## Normalitas
<br>
  $H_0$ : Residual berdistribusi normal <br> $H_1$ : Residual tidak berdistribusi normal<br>
  ```{r}
plot(Keempat,2)
shapiro.test(Keempat$residuals)
```

## Homogenitas
<br>
  $H_0$ : Ragam sisaan konstan (homoskedastisitas) <br> $H_1$ : Ragam sisaan tidak konstan (Heteroskedastisitas)<br>
  ```{r}
plot(Keempat,1)
bptest(Keempat)
```

## Plot sisaan terhadap Urutan
<br>
  $H_0$ : Sisaan saling bebas (Tidak ada autokorelasi) <br> $H_1$ : Sisaan tidak saing bebas (Autokorelasi)<br>
  ```{r}
plot(x = 1:dim(dt)[1],
     y = Keempat$residuals,
     type = 'b', 
     ylab = "Residuals",
     xlab = "Observation")

dwtest(kedua)
```

# **PENANGANAN LANJUTAN : ROBUST REGRESSION**

```{r}
Ketiga <- lmrob(Y_tr~X1+X2+X3+X4+X8, data = dt, method = "S")
summary(Ketiga)
```



# **UJI ASUMSI PENANGANAN LANJUTAN**
## $E(e_i) = 0$
```{r}
t.test(Ketiga$residuals,mu = 0,conf.level = 0.95)
```

## Normalitas
<br>
  $H_0$ : Residual berdistribusi normal <br> $H_1$ : Residual tidak berdistribusi normal<br>
  ```{r}
plot(Ketiga,2)
shapiro.test(Ketiga$residuals)
```

## Homogenitas
<br>
  $H_0$ : Ragam sisaan konstan (homoskedastisitas) <br> $H_1$ : Ragam sisaan tidak konstan (Heteroskedastisitas)<br>
  ```{r}
plot(Ketiga,1)
bptest(Ketiga)
```


## Plot sisaan terhadap Urutan
<br>
  $H_0$ : Sisaan saling bebas (Tidak ada autokorelasi) <br> $H_1$ : Sisaan tidak saing bebas (Autokorelasi)<br>
  ```{r}
plot(x = 1:dim(dt)[1],
     y = Ketiga$residuals,
     type = 'b', 
     ylab = "Residuals",
     xlab = "Observation")

dwtest(Ketiga)
```

#**Transformasi Balik**
```{r}
dt$Y_tr_pred <- predict(Ketiga, newdata = dt)
dt$Y_inv_pred <- (0.06060606 * dt$Y_tr_pred + 1)^(1/0.06060606)


model_inv <- lm(Y_inv_pred ~ X1 + X2 + X3 + X4 + X8, data = dt)
summary(model_inv)

View(dt)
```
## Ilustrasi Bobot dengan Residual
```{r}
residuals_Ketiga <- residuals(Ketiga)
weights_Ketiga <- weights(Ketiga)
hasil <- data.frame(
  Observation = 1:nrow(dt),
  Residual = abs(residuals(Ketiga)),
  Weight = Ketiga$rweights
)

View(hasil)
```

```{r}
library(ggplot2)

# Buat data.frame hasil seperti sebelumnya
resid <- abs(residuals(Ketiga))
bobot <- Ketiga$rweights

hasil <- data.frame(
  Residual = resid,
  Weight = bobot
)

# Plot menggunakan ggplot2
ggplot(hasil, aes(x = Residual, y = Weight)) +
  geom_point(alpha = 0.7, color = "steelblue") +
  geom_hline(yintercept = 0.1, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(
    title = "Scatter Plot Residual vs Weight",
    x = "Residual",
    y = "Weight"
  )

```

#**HITUNG MANUAL**
```{r}
# Hasil perhitungan manual tidak dapat dibandingkan langsung dengan metode lmrob method: "S"  karena metode inisialisasi yang berbeda. Selain itu, lmrob() menggunakan metode khusus dan threshold yang sudah diteliti untuk efisiensi tinggi.
```

```{r}

y <- dt$Y_tr
X_original <- dt %>% dplyr::select(X1, X2, X3, X4, X8)
X <- as.matrix(X_original)
X_with_intercept <- cbind(1, X)
colnames(X_with_intercept)[1] <- "Intercept"
X <- X_with_intercept

rho_biweight <- function(u, c = 4.685) {
  u_abs <- abs(u)
  result <- ifelse(u_abs <= c, (c^2 / 6) * (1 - (1 - (u / c)^2)^3), (c^2) / 6)
  return(result)
}

w_biweight <- function(u, c = 4.685) {
  u_abs <- abs(u)
  w <- ifelse(u_abs <= c, (1 - (u / c)^2)^2, 0)
  return(w)
}

scale_est <- function(resid, c = 4.685, K = 0.1995, tol = 1e-10, max_iter = 200) {
  # Inisialisasi skala dengan MAD
  s <- mad(resid) / 0.6745
  for (i in 1:max_iter) {
    u <- resid / s
    # Pastikan K sesuai dengan yang Anda inginkan (misalnya, E(rho(u)) untuk normal)
    s_new <- s * sqrt(mean(rho_biweight(u, c)) / K)
    if (abs(s_new - s) < tol) break
    s <- s_new
  }
  return(s)
}

regresi_s_manual <- function(y, X, c = 4.685, K = 0.1995, max_iter = 200, tol = 1e-10) {
  
  beta <- coef(lm(y ~ X - 1)) 
  if (length(beta) != ncol(X)) {
    stop("Dimensi beta awal tidak sesuai dengan jumlah kolom X. Periksa inisialisasi beta.")
  }
  
  for (iter in 1:max_iter) {
    resid <- y - X %*% beta
    s <- scale_est(resid, c = c, K = K)
    u <- as.vector(resid / s)
    w <- w_biweight(u, c = c)
    W <- diag(w)
    XWX <- t(X) %*% W %*% X
    XWy <- t(X) %*% W %*% y
    beta_new <- tryCatch({
      qr.solve(XWX, XWy)
    }, error = function(e) {
      warning("QR solve gagal, kembali ke beta sebelumnya. Error: ", e$message)
      beta
    })
    
    if (max(abs(beta_new - beta)) < tol) break
    beta <- beta_new
  }
  return(list(beta = beta, scale = s, residuals = y - X %*% beta, weights = w))
}

y <- dt$Y_tr
X_original <- dt %>% dplyr::select(X1,X2,X3,X4,X8)
X <- as.matrix(X_original)
X <- cbind(1, X)
colnames(X)[1]


hasil_s <- regresi_s_manual(y, X)
print(hasil_s$beta)
```


