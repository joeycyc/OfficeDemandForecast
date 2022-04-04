setwd("~/Joey/Project/202006 Forecasting_models(Commercial)")
library(fpp2)
library(xlsx)
library(tseries)
library(lmtest)
library(dynlm)
library(vars)
library(dyn)

##### Read data for (1) and (2) -----
# df_officeusage = read.xlsx("Office_Demand_Model.xlsx", sheetName = "OfficeUsage_yrly")
# colnames(df_officeusage) <- c("Date", "Year", "Comp_A_ms", "Comp_B_ms", "Comp_C_ms", "Comp_Total_ms", 
#                               "Stock_A_ms", "Stock_B_ms", "Stock_C_ms", "Stock_Total_ms", 
#                               "Vacancy_A_ms", "Vacancy_A_pStock", "Vacancy_B_ms", "Vacancy_B_pStock", 
#                               "Vacancy_C_ms", "Vacancy_C_pStock", "Vacancy_Total_ms", "Vacancy_Total_pStock", 
#                               "Take-up_A_ms", "Take-up_B_ms", "Take-up_C_ms", "Take-up_Total_ms")
# 
# df_officeusage$Vacancy_Total_pStock <- df_officeusage$Vacancy_Total_ms / df_officeusage$Stock_Total_ms
# 
# ggplot(df_officeusage, aes(x=Date, y=Vacancy_Total_pStock*100)) +
#   geom_line() + 
#   xlab("Year") +
#   ylab("Percentage")


df_interp2 = read.xlsx("Office_Demand_Model.xlsx", sheetName = "Interpolate_qtr(2)")
colnames(df_interp2) <- c("Date", "Year", "Qtr", "Comp_A_ms", "Comp_B_ms", "Comp_C_ms", "Comp_Total_ms", 
                          "Stock_A_ms", "Stock_B_ms", "Stock_C_ms", "Stock_Total_ms", 
                          "Vacancy_A_ms", "Vacancy_A_pStock", "Vacancy_B_ms", "Vacancy_B_pStock", 
                          "Vacancy_C_ms", "Vacancy_C_pStock", "Vacancy_Total_ms", "Vacancy_Total_pStock", 
                          "TakeUp_A_ms", "TakeUp_B_ms", "TakeUp_C_ms", "TakeUp_Total_ms",
                          "Rental_Idx_A", "Rental_Idx_B", "Rental_Idx_C", "Rental_Idx_Overall", 
                          "Price_Idx_A", "Price_Idx_B", "Price_Idx_C", "Price_Idx_Overall",
                          "GDP", "Labour_Force_000", "Unemployed_000", "Employed_000", 
                          "HSI_Close", "No_of_Companies.on.Register", "Unemployment_Rate")

# ggplot(df_interp2, aes(x=Date, y=Vacancy_Total_pStock*100)) +
#   geom_line() + 
#   xlab("Year") +
#   ylab("Percentage")


##### (1) ARIMA model on Vacancy % -----
# Set Vacancy % as time series
ts_vacancy <- ts(df_interp2$Vacancy_Total_pStock[8:144], start=c(1985, 4), frequency=4)
autoplot(ts_vacancy) # Plot Vacancy %
ggAcf(ts_vacancy) # Plot ACF, the series is non-stationary

# Decompose ts into trend, seasonality and error
ts_vacancy_decomposed <- decompose(ts_vacancy, type="additive")
plot(ts_vacancy_decomposed)
ggAcf(ts_vacancy_decomposed$random) # Visually the random part is not stationary enough
adf.test(ts_vacancy_decomposed$random[3:135])  # But the adf test reject that the random part is non-stationary

# Apply differencing into the ts
ts_vacancy_lag1 <- diff(ts_vacancy, lag=1, differences=1)
ggAcf(ts_vacancy_lag1)  # More stationary
plot(ts_vacancy_lag1)

# Use ACF and PACF to find the order for AR
acf(ts_vacancy_lag1, lag.max=60)
pacf(ts_vacancy_lag1, lag.max=60)

# AR(4)
fit1 <- arima(ts_vacancy_lag1, order=c(4,0,0))
coeftest(fit1)
confint(fit1)


##### (2) ARIMA model on Overall Take-up (Quarterly) -----
# Set Take-up as time series
ts_takeup <- ts(df_interp2$TakeUp_Total_ms[5:144], start=c(1985, 1), frequency=4)
autoplot(ts_takeup) # Plot Take-up %
ggAcf(ts_takeup) # Plot ACF, the series is stationary after order 4

# Mean-centred
mean_takeup <- mean(ts_takeup) # Mean of takeup value
sd_takeup <- sd(ts_takeup) # SD of takeup value
# Transform ts_takeup to Z-score: (ts_takeup-mean(ts_takeup))/sd(ts_takeup)
ts_takeup_scaled <- ts(scale(ts_takeup), start=c(1985, 1), frequency=4)



##### (3) ARIMA model on Overall Take-up (Yearly) -----
df_officeusage = read.xlsx("Office_Demand_Model.xlsx", sheetName = "OfficeUsage_yrly")
colnames(df_officeusage) <- c("Date", "Year", "Comp_A_ms", "Comp_B_ms", "Comp_C_ms", "Comp_Total_ms", 
                              "Stock_A_ms", "Stock_B_ms", "Stock_C_ms", "Stock_Total_ms", 
                              "Vacancy_A_ms", "Vacancy_A_pStock", "Vacancy_B_ms", "Vacancy_B_pStock", 
                              "Vacancy_C_ms", "Vacancy_C_pStock", "Vacancy_Total_ms", "Vacancy_Total_pStock", 
                              "TakeUp_A_ms", "TakeUp_B_ms", "TakeUp_C_ms", "TakeUp_Total_ms")
ts_takeup_yr <- ts(df_officeusage$TakeUp_Total_ms, start=1985, frequency=1)
autoplot(ts_takeup_yr) # Plot Take-up %
ggAcf(ts_takeup_yr) # Plot ACF, the series is stationary

pacf(ts_takeup_yr, lag.max=30)


##### (4) VAR model on Overall Take-up (Yearly) -----
# Use YoY change
# No scaling on variables

# Read data
df_yrly = read.xlsx("Office_Demand_Model.xlsx", sheetName = "Yrly")
colnames(df_yrly) <- c("Date", "Year", "Comp_Total_msq", "Stock_Total_msq", 
                       "Vacancy_Total_msq", "Vacancy_Total_pStock", "Vacancy_Total_pStock_ppChg",
                       "TakeUp_Total_msq",
                       "RentalIdx", "RentalIdx_pChg", "RentalIdx_LogChg", 
                       "PriceIdx", "PriceIdx_pChg", "PriceIdx_LogChg",
                       "GDP_HKDM", "GDP_pChg",
                       "LabourForce_000", "Unemployed_000", "Employed_000",
                       "UnemploymentRate", "Employed_000Chg", "HSI_Close",
                       "HSI_pChg", "HSI_LogChg", "N_NewIPO",
                       "N_Company", "N_Company_Chg", "N_Company_pChg", "N_Company_LogChg")
df_yrly_trim <- df_yrly[c(4:36),c(1:29)]

# Correlation matrix
cormat <- round(cor(df_yrly[c(4:36),c(3:24,26:28)]),3)
col <- colorRampPalette(c("red", "white", "green"))(20)
heatmap(cormat, col=col)
# GDP_pChg, Employed_000Chg, HSI_pChg and N_Company_pChg are positively correlated with TakeUp_Total_msq

# Multiple linear regression model, regardless of the temporal property of data
lr1 <- lm(TakeUp_Total_msq ~ GDP_pChg + Employed_000Chg + HSI_pChg + N_Company_pChg, data=df_yrly_trim)
summary(lr1) # Invalid model
lr2 <- lm(TakeUp_Total_msq ~ GDP_pChg, data=df_yrly_trim)
summary(lr2) # Valid model but not robust
lr3 <- lm(TakeUp_Total_msq ~ GDP_pChg + Employed_000Chg + HSI_pChg, data=df_yrly_trim)
summary(lr3) # Slightly poor than lr2
lr4 <- lm(TakeUp_Total_msq ~ GDP_pChg + HSI_pChg, data=df_yrly_trim)
summary(lr4) # Better than lr2, Adj R sq = 0.1928
lr5 <- lm(TakeUp_Total_msq ~ ., data=df_yrly_trim[c(1:33),c(4,8,9,12,16,20,21,22,27)])
summary(lr5) # Invalid model, too many explanatory variables

# Set Timestamp Objects
tsTakeUp <- ts(df_yrly$TakeUp_Total_msq[4:36], start=1987, frequency=1)
tsGDPpChg <- ts(df_yrly$GDP_pChg[4:36], start=1987, frequency=1)
tsEmployedChg <- ts(df_yrly$Employed_000Chg[4:36], start=1987, frequency=1)
tsHSIpChg <- ts(df_yrly$HSI_pChg[4:36], start=1987, frequency=1)
tsCoypChg <- ts(df_yrly$N_Company_pChg[4:36], start=1987, frequency=1)

# Implement Vector Autoregression using Dynamic Linear Regression package
VAR1 <- dynlm(tsTakeUp ~ L(tsTakeUp, 1:2) + L(tsGDPpChg, 0:2))
summary(VAR1)
VAR2 <- dynlm(tsTakeUp ~ L(tsTakeUp, 1:2) + L(tsGDPpChg, 0:2) + L(tsEmployedChg, 0:2) + L(tsHSIpChg, 0:2) + L(tsCoypChg, 0:2))
summary(VAR2)
VAR3 <- dynlm(tsTakeUp ~ L(tsTakeUp, 1:2) + L(tsGDPpChg, 0:2) + L(tsEmployedChg, -1:2) + L(tsHSIpChg, 0:2) + L(tsCoypChg, 0:2))
summary(VAR3)
VAR4 <- dynlm(tsTakeUp ~ L(tsGDPpChg, 0:2) + L(tsEmployedChg, -1:0) + L(tsHSIpChg, 0:2) + L(tsCoypChg, -1:1))
summary(VAR4)

# Given with yearly data only, the models were not satisfying
# Next we try using VAR model on quarterly data


##### (5) VAR model on Overall Take-up (Quarterly) -----
# Read data
df_qtrly = read.xlsx("Office_Demand_Model.xlsx", sheetName = "Qtrly")
colnames(df_qtrly) <- c("Date", "Year", "Qtr", "Comp_Total_msq", 
                       "Stock_Total_msq", "Vacancy_Total_msq", "Vacancy_Total_pStock", "Vacancy_Total_pStock_ppChg",
                       "TakeUp_Total_msq", "RentalIdx", "RentalIdx_pChg", "RentalIdx_LogChg", 
                       "PriceIdx", "PriceIdx_pChg", "PriceIdx_LogChg", "GDP_HKDM", 
                       "GDP_pChg", "LabourForce_000", "Unemployed_000", "Employed_000",
                       "UnemploymentRate", "Employed_000Chg", "HSI_Close", "HSI_pChg", 
                       "HSI_LogChg", "N_Company", "N_Company_Chg", "N_Company_pChg", "N_Company_LogChg")
df_qtrly_trim <- df_qtrly[c(10:144),c(1:29)]
rownames(df_qtrly_trim) <- 1:nrow(df_qtrly_trim)

# Correlation matrix
cormat2 <- round(cor(df_qtrly_trim[c(1:135),c(4:29)]),3)
col <- colorRampPalette(c("red", "white", "green"))(20)
heatmap(cormat2, col=col)

# Set Timestamp Objects
tsQtr <- ts(df_qtrly_trim, start=c(1986,2), frequency=4)
setTS <- function(colname) {
  ts(df_qtrly_trim[colname], start=c(1986,2), frequency=4)
}
tsComp <- setTS('Comp_Total_msq')
tsStock <- setTS('Stock_Total_msq')
tsVac <- setTS('Vacancy_Total_msq')
tsVacp <- setTS('Vacancy_Total_pStock')
tsVacppChg <- setTS('Vacancy_Total_pStock_ppChg')
tsTakeUp <- setTS('TakeUp_Total_msq')
tsRentalIdx <- setTS('RentalIdx')
tsRentalIdxpChg <- setTS('RentalIdx_pChg')
tsRentalIdxLogChg <- setTS('RentalIdx_LogChg')
tsPriceIdx <- setTS('PriceIdx')
tsPriceIdxpChg <- setTS('PriceIdx_pChg')
tsPriceIdxLogChg <- setTS('PriceIdx_LogChg')
tsGDP <- setTS('GDP_HKDM')
tsGDPpChg <- setTS('GDP_pChg')
tsLabourForce <- setTS('LabourForce_000')
tsUnemployed <- setTS('Unemployed_000')
tsEmployed <- setTS('Employed_000')
tsUnemploymentRate <- setTS('UnemploymentRate')
tsEmployedChg <- setTS('Employed_000Chg')
tsHSIClose <- setTS('HSI_Close')
tsHSIpChg <- setTS('HSI_pChg')
tsHSILogChg <- setTS('HSI_LogChg')
tsCoy <- setTS('N_Company')
tsCoyChg <- setTS('N_Company_Chg')
tsCoypChg <- setTS('N_Company_pChg')
tsCoyLogChg <- setTS('N_Company_LogChg')

tsGDPrandom <- decompose(tsGDP)$random
tsGDPrandom[1:2] <- tsGDPrandom [5:6]
tsGDPrandom[134:135] <- tsGDPrandom[130:131]

# Implement Vector Autoregression using Dynamic Linear Regression package
VARq1 <- dynlm(tsTakeUp ~ L(tsGDPpChg, 0:4))
summary(VARq1)
VARq2 <- dynlm(tsTakeUp ~ L(tsGDPrandom, 0:2))
summary(VARq2)
VARq3 <- dynlm(tsTakeUp ~ L(tsGDPpChg, 0:4))
summary(VARq3)

# Seems there are problem with interpolation of Take-up
# New direction: Predict the composition of Take-up?


##### (6) Models on Vacancy Change (Yearly) -----
### Read data
# df_yrly = read.xlsx("Office_Demand_Model.xlsx", sheetName = "Yrly_2")
df_yrly = read.xlsx("Office_Demand_Model.xlsx", sheetName = "Yrly_3")
colnames(df_yrly) <- c("Date", "Year", "Comp_Total_msq", "Stock_Total_msq", 
                       "Vacancy_Total_msq", "Vacancy_Total_pStock", "Vacancy_Total_pStock_ppChg",
                       "TakeUp_Total_msq",
                       "RentalIdx", "RentalIdx_pChg", "RentalIdx_LogChg", 
                       "PriceIdx", "PriceIdx_pChg", "PriceIdx_LogChg",
                       "GDP_HKDM", "GDP_pChg",
                       "LabourForce_000", "Unemployed_000", "Employed_000",
                       "UnemploymentRate", "Employed_000Chg", "HSI_Close",
                       "HSI_pChg", "HSI_LogChg", "N_NewIPO",
                       "N_Company", "N_Company_Chg", "N_Company_pChg", "N_Company_LogChg", 
                       "Vacancy_Total_Chg", "Demolition_Total_msq", "Demolition_Total_pStock")
df_yrly_trim <- df_yrly[c(3:36),c(1:24,26:32)]
rownames(df_yrly_trim) <- 1:nrow(df_yrly_trim)

# Correlation matrix
cormat3 <- round(cor(df_yrly_trim[,3:31]),3)
col <- colorRampPalette(c("red", "white", "green"))(20)
heatmap(cormat3, col=col)

# Set time series data
tsYrly <- ts(df_yrly_trim, start=1986, frequency=1)
for (i in 1:length(colnames(df_yrly_trim))) {
  assign(paste("ts_", colnames(df_yrly_trim)[i], sep = ""), tsYrly[,i])
}

### ARIMA model on Vacancy Change (absolute)
## Stationary Test
autoplot(ts_Vacancy_Total_Chg) # Plot Take-up %
acf(ts_Vacancy_Total_Chg, lag.max=30) # Plot ACF, the series is closed to stationary
adf.test(ts_Vacancy_Total_Chg)
pacf(ts_Vacancy_Total_Chg, lag.max=30) # No significant partial autocorrelation with past lag

## Model fitting
# AR(4) on Vacancy YoY Change (m^2)
arimafit01 <- arima(ts_Vacancy_Total_Chg, order=c(4,0,0))
summary(arimafit01) # Not a good fit
coeftest(arimafit01)
confint(arimafit01)
# Comment: The model seems fit, but coef of all prarameter are all unit coef, i.e. AR and MA cancelled out each other

### Mean estimate on Vacancy YoY Change (m^2)
# arimafit02 <- arima(ts_Vacancy_Total_Chg, order=c(1,0,1))
arimafit02 <- arima(ts_Vacancy_Total_Chg, order=c(2,0,2))
summary(arimafit02)
coeftest(arimafit02)
confint(arimafit02)
# Comment: Vacancy Change is similar to white noise, best estimate the next value using the mean
mean(ts_Vacancy_Total_Chg)
sd(ts_Vacancy_Total_Chg)

### ARIMA model on Vacancy (% of Stock)
## Stationary Test
autoplot(ts_Vacancy_Total_pStock) # Plot Take-up %
acf(ts_Vacancy_Total_pStock, lag.max=30) # Plot ACF, there is autocorrelation up to lag 2
adf.test(ts_Vacancy_Total_pStock)
pacf(ts_Vacancy_Total_pStock, lag.max=30) # No significant partial autocorrelation with past lag

## Model fitting
# AR(2) model on Vacancy (% of Stock)
arimafit03 <- arima(ts_Vacancy_Total_pStock, order=c(2,0,0))
summary(arimafit03)
coeftest(arimafit03)
confint(arimafit03)

# AR(1) model on Vacancy (% of Stock)
arimafit04 <- arima(ts_Vacancy_Total_pStock, order=c(1,0,0))
summary(arimafit04)
coeftest(arimafit04)
confint(arimafit04)
acf(arimafit04$residuals) # Residual is random, AR(1) is a good model fit
checkresiduals(arimafit04)
(forecast_arimafit04 <- forecast(ts_Vacancy_Total_pStock, model=arimafit04))
autoplot(forecast_arimafit04)
# Comment: AR(1) is fine
# Back-testing
mean_est <- vector()
for (i in 1:(length(ts_Vacancy_Total_pStock)-1)) {
  mean_est <- c(mean_est, forecast(ts_Vacancy_Total_pStock[1:i], model=arimafit04)$mean[1])
}
mean_est # Since 1987

# MA(2) model on Vacancy (% of Stock)
arimafit05 <- arima(ts_Vacancy_Total_pStock, order=c(0,0,2)) # MA(2)
summary(arimafit05)
coeftest(arimafit05)
confint(arimafit05)
checkresiduals(arimafit05)
(forecast_arimafit05 <- forecast(ts_Vacancy_Total_pStock, model=arimafit05))
autoplot(forecast_arimafit05)
# Comment: MA(2) is also fine
# Back-testing
mean_est <- vector()
for (i in 2:(length(ts_Vacancy_Total_pStock)-1)) {
  mean_est <- c(mean_est, forecast(ts_Vacancy_Total_pStock[1:i], model=arimafit05)$mean[1])
}
mean_est # Since 1988

### Multiple Linear Regression model
## On Vacancy Change (absolute)
lr01 <- lm(ts_Vacancy_Total_Chg ~ ts_GDP_pChg + ts_Employed_000Chg + ts_RentalIdx_LogChg + ts_PriceIdx_LogChg + ts_N_Company_Chg)
summary(lr01) # Invalid model
lr02 <- lm(ts_Vacancy_Total_Chg ~ ts_GDP_pChg)
summary(lr02) # A fair model
lr03 <- lm(ts_Vacancy_Total_Chg ~ ts_Employed_000Chg)
summary(lr03) # A fair model

## On Vacancy (% of Stock)
lr04 <- lm(ts_Vacancy_Total_pStock ~ ts_GDP_pChg)
summary(lr04)
lr05 <- lm(ts_Vacancy_Total_pStock ~ ts_RentalIdx_pChg)
summary(lr05) # A good model
lr06 <- lm(ts_Vacancy_Total_pStock ~ ts_PriceIdx_LogChg)
summary(lr06)
lr07 <- lm(ts_Vacancy_Total_pStock ~ ts_N_Company_Chg)
summary(lr07)
lr08 <- lm(ts_Vacancy_Total_pStock ~ ts_RentalIdx_pChg + ts_N_Company_Chg)
summary(lr08) # A better model
lr09 <- lm(ts_Vacancy_Total_pStock ~ ts_RentalIdx_pChg + ts_N_Company_Chg + ts_UnemploymentRate)
summary(lr09) # Better than lr08
# Back-testing and make predition using lr08
lr08$fitted.values
newdata <- data.frame(ts_GDP_pChg=c(ts_GDP_pChg, -0.05, 0), 
                      ts_RentalIdx_pChg=c(ts_RentalIdx_pChg, -0.05317521, -0.00848485), 
                      ts_N_Company_Chg=c(ts_N_Company_Chg, 11934, 11934), 
                      ts_UnemploymentRate=c(ts_UnemploymentRate, 0.05, 0.04))
predict(lr08, newdata, interval="predict")

# Back-testing and make predition using lr09
lr09$fitted.values
predict(lr09, newdata, interval="predict")


### VAR Models
## On Vacancy Change (absolute)
# ts_Vacancy_Total_Chg ~ ts_GDP_pChg : No lag
VAR01 <- dynlm(ts_Vacancy_Total_Chg ~ L(ts_GDP_pChg, 0))
VAR02 <- dynlm(ts_Vacancy_Total_Chg ~ L(ts_Employed_000Chg, 0:2))
VAR03 <- dynlm(ts_Vacancy_Total_Chg ~ L(ts_GDP_pChg, 0) + L(ts_RentalIdx_pChg, 2))

## On Vacancy (% of Stock)
VAR04 <- dynlm(ts_Vacancy_Total_pStock ~ L(ts_RentalIdx_pChg, 0:1) + L(ts_N_Company_Chg, 0))
summary(VAR04) # Good model that outperform lr08
VAR05 <- dynlm(ts_Vacancy_Total_pStock ~ L(ts_RentalIdx_pChg, 0:1) + L(ts_N_Company_Chg, 1))
summary(VAR05) # Even better than VAR04
VAR06 <- dynlm(ts_Vacancy_Total_pStock ~ L(ts_RentalIdx_pChg, 0:2) + L(ts_N_Company_Chg, 1))
summary(VAR06) # Higher R-squared but have non-significant parameter values
# Back-testing on VAR05
VAR05$fitted.values # From 1987 to 2019
# Make prediction using VAR05 (Problematic, don't use)
VAR05p <- dyn$lm(ts_Vacancy_Total_pStock ~ ts_RentalIdx_pChg + lag(ts_RentalIdx_pChg,-1) + lag(ts_N_Company_Chg,-1))
summary(VAR05p)
# newdata <- data.frame(ts_RentalIdx_pChg=c(-0.05317521, -0.00848485), ts_N_Company_Chg=c(11934, 11934))
# predict(VAR05p, newdata, interval="predict")
# backtestdata <- data.frame(ts_RentalIdx_pChg=ts_RentalIdx_pChg, ts_N_Company_Chg=ts_N_Company_Chg)
# predict(VAR05p, backtestdata) # Since 1986

VAR06 <- dynlm(ts_Vacancy_Total_pStock ~ L(ts_GDP_pChg, 0) + L(ts_RentalIdx_pChg, 0:1) + L(ts_N_Company_Chg, 1))
summary(VAR06) # Even better than VAR05
VAR07 <- dynlm(ts_Vacancy_Total_pStock ~ L(ts_GDP_pChg, 0:1) + L(ts_RentalIdx_pChg, 0:1) + L(ts_N_Company_Chg, 1))
summary(VAR07) # GDP Growth lag 1 is not significant
VAR08 <- dynlm(ts_Vacancy_Total_pStock ~ L(ts_GDP_pChg, 0) + L(ts_RentalIdx_pChg, 0:1) + L(ts_N_Company_Chg, 1) + L(ts_UnemploymentRate, 0))
summary(VAR08)
# Back-testing using VAR08
VAR08$fitted.values
# VAR08p <- dyn$lm(ts_Vacancy_Total_pStock ~ ts_GDP_pChg + ts_RentalIdx_pChg + lag(ts_RentalIdx_pChg,-1) + lag(ts_N_Company_Chg,-1) + ts_UnemploymentRate)
# summary(VAR08p)
# newdata2 <- data.frame(ts_GDP_pChg=c(ts_GDP_pChg, -0.05, 0), 
#                        ts_RentalIdx_pChg=c(ts_RentalIdx_pChg, -0.05317521, -0.00848485), 
#                        ts_N_Company_Chg=c(ts_N_Company_Chg, 11934, 11934), 
#                        ts_UnemploymentRate=c(ts_UnemploymentRate, 0.05, 0.04))
# predict(VAR08p, newdata2, interval="predict")

# Estimate the 95% Confidence Intervals for VAR05
# 2019 and estimated 2020-2021 data
testdata <- data.frame(ts_GDP_pChg=c(-0.012494, -0.05, 0), 
                       ts_RentalIdx_pChg=c(0.036478, -0.05317521, -0.00848485), 
                       ts_N_Company_Chg=c(-20765, 11934, 11934), 
                       ts_UnemploymentRate=c(0.029322, 0.05, 0.04))
# Using Monte Carlo method
set.seed(20611)
nRan <- 1000 # No. of random number
nCoef <- length(VAR05$coefficients) # No. of coefficients
dfPara <- data.frame(Intercept = rnorm(nRan, VAR05$coefficients[1], coef(summary(VAR05))[1, "Std. Error"]))
for (i in 2:nCoef) {
  tmpdf <- data.frame(rnorm(nRan, VAR05$coefficients[i], coef(summary(VAR05))[i, "Std. Error"]))
  colnames(tmpdf) <- names(VAR05$coefficients)[i]
  dfPara <- cbind(dfPara, tmpdf)
}
est20 <- c() # The estimate of Vacancy % in 2020
for (i in 1:nRan) {
  est <- dfPara[i,1] + dfPara[i,2]*testdata$ts_RentalIdx_pChg[2] + dfPara[i,3]*testdata$ts_RentalIdx_pChg[1] + dfPara[i,4]*testdata$ts_N_Company_Chg[1]
  est20 <- c(est20, est)
}
est21 <- c() # The estimate of Vacancy % in 2021
for (i in 1:nRan) {
  est <- dfPara[i,1] + dfPara[i,2]*testdata$ts_RentalIdx_pChg[3] + dfPara[i,3]*testdata$ts_RentalIdx_pChg[2] + dfPara[i,4]*testdata$ts_N_Company_Chg[2]
  est21 <- c(est21, est)
}
# The 95% Confidence Intervals and median
quantile(est20, c(.05, .50, .95))
quantile(est21, c(.05, .50, .95))

# Estimate the 95% Confidence Intervals for VAR08
set.seed(20611)
nRan <- 1000 # No. of random number
nCoef <- length(VAR08$coefficients) # No. of coefficients
dfPara <- data.frame(Intercept = rnorm(nRan, VAR08$coefficients[1], coef(summary(VAR08))[1, "Std. Error"]))
for (i in 2:nCoef) {
  tmpdf <- data.frame(rnorm(nRan, VAR08$coefficients[i], coef(summary(VAR08))[i, "Std. Error"]))
  colnames(tmpdf) <- names(VAR08$coefficients)[i]
  dfPara <- cbind(dfPara, tmpdf)
}
est20 <- c() # The estimate of Vacancy % in 2020
for (i in 1:nRan) {
  est <- dfPara[i,1] + 
    dfPara[i,2]*testdata$ts_GDP_pChg[2] +
    dfPara[i,3]*testdata$ts_RentalIdx_pChg[2] + 
    dfPara[i,4]*testdata$ts_RentalIdx_pChg[1] + 
    dfPara[i,5]*testdata$ts_N_Company_Chg[1] +
    dfPara[i,6]*testdata$ts_UnemploymentRate[2]
  est20 <- c(est20, est)
}
est21 <- c() # The estimate of Vacancy % in 2021
for (i in 1:nRan) {
  est <- dfPara[i,1] + 
    dfPara[i,2]*testdata$ts_GDP_pChg[3] +
    dfPara[i,3]*testdata$ts_RentalIdx_pChg[3] + 
    dfPara[i,4]*testdata$ts_RentalIdx_pChg[2] + 
    dfPara[i,5]*testdata$ts_N_Company_Chg[2] +
    dfPara[i,6]*testdata$ts_UnemploymentRate[3]
  est21 <- c(est21, est)
}
# The 95% Confidence Intervals and median
quantile(est20, c(.05, .50, .95))
quantile(est21, c(.05, .50, .95))


##### Evaluate the effect of predictors ------
# Standardised data
dfYrlyStd <- df_yrly_trim[,1:2]
dfYrlyStd <- cbind(tsYrlyStd, scale(df_yrly_trim[,3:dim(df_yrly_trim)[2]]))
tsYrlyStd <- ts(dfYrlyStd, start=1986, frequency=1)
for (i in 1:length(colnames(dfYrlyStd))) {
  assign(paste("ts_", colnames(dfYrlyStd)[i], "_std", sep = ""), tsYrlyStd[,i])
}
# Train selected models using standardised data
arimafit04s <- arima(ts_Vacancy_Total_pStock_std, order=c(1,0,0))
summary(arimafit04s)
arimafit05s <- arima(ts_Vacancy_Total_pStock_std, order=c(0,0,2))
summary(arimafit05s)
lr08s <- lm(ts_Vacancy_Total_pStock_std ~ ts_RentalIdx_pChg_std + ts_N_Company_Chg_std)
summary(lr08s)
lr09s <- lm(ts_Vacancy_Total_pStock_std ~ ts_RentalIdx_pChg_std + ts_N_Company_Chg_std + ts_UnemploymentRate_std)
summary(lr09s)
VAR05s <- dynlm(ts_Vacancy_Total_pStock_std ~ L(ts_RentalIdx_pChg_std, 0:1) + L(ts_N_Company_Chg_std, 1))
summary(VAR05s)
VAR08s <- dynlm(ts_Vacancy_Total_pStock_std ~ L(ts_GDP_pChg_std, 0) + 
                  L(ts_RentalIdx_pChg_std, 0:1) + L(ts_N_Company_Chg_std, 1) + L(ts_UnemploymentRate_std, 0))
summary(VAR08s)





