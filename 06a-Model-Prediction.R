# =============================================================================
# 06a-Model-Prediction.R
# PCR (Principal Component Regression) for Coffee NIR Spectroscopy Data
# =============================================================================

# Load required libraries
library(pls)

# -----------------------------------------------------------------------------
# 1. Load and Prepare Data
# -----------------------------------------------------------------------------

# Read the coffee NIR data
coffee_data <- read.csv("coffee_nirs.csv", sep = ";", header = TRUE)

# Display data dimensions
cat("Data dimensions:", nrow(coffee_data), "samples x", ncol(coffee_data), "variables\n")

# Identify response variables and spectral columns
response_vars <- c("CGA", "Cafeine", "Fat", "Trigonelline", "DM")
spectral_cols <- grep("^S[0-9]+$", names(coffee_data), value = TRUE)

cat("Number of spectral variables:", length(spectral_cols), "\n")
cat("Response variables:", paste(response_vars, collapse = ", "), "\n")

# -----------------------------------------------------------------------------
# 2. Data Preprocessing
# -----------------------------------------------------------------------------

# Extract spectral matrix (X) and convert to matrix
X <- as.matrix(coffee_data[, spectral_cols])

# Check for missing values in X
cat("\nMissing values in spectral data:", sum(is.na(X)), "\n")

# -----------------------------------------------------------------------------
# 3. PCR Model for Fat Prediction
# -----------------------------------------------------------------------------

cat("\n=== PCR Model for Fat Prediction ===\n")

# Extract response variable
Y_fat <- coffee_data$Fat

# Check for missing values
cat("Missing values in Fat:", sum(is.na(Y_fat)), "\n")

# Create clean dataset by identifying complete cases
# IMPORTANT: Check complete cases on both X and Y together to ensure matching rows
complete_idx <- complete.cases(cbind(Y_fat, X))
cat("Complete cases:", sum(complete_idx), "out of", length(complete_idx), "\n")

# Subset to complete cases
X_clean <- X[complete_idx, ]
Y_fat_clean <- Y_fat[complete_idx]

# Verify dimensions match
cat("X dimensions after cleaning:", nrow(X_clean), "x", ncol(X_clean), "\n")
cat("Y length after cleaning:", length(Y_fat_clean), "\n")

# Create data frame for PCR (pls package requires this format)
pcr_data <- data.frame(
  Fat = Y_fat_clean,
  spectra = I(X_clean)
)

# Fit PCR model with cross-validation
# Using 10-fold cross-validation to determine optimal number of components
set.seed(123)
pcr_fat_model <- pcr(
  Fat ~ spectra,
  data = pcr_data,
  ncomp = 20,
  validation = "CV",
  segments = 10
)

# Model summary
cat("\nPCR Model Summary:\n")
summary(pcr_fat_model)

# Find optimal number of components using RMSEP
rmsep_values <- RMSEP(pcr_fat_model)
cat("\nRMSEP values:\n")
print(rmsep_values)

# Plot RMSEP to visualize optimal components
plot(rmsep_values, main = "RMSEP vs Number of Components (Fat - PCR)")

# Determine optimal components (minimum RMSEP for CV)
cv_rmsep <- rmsep_values$val[2, 1, ]  # CV values
optimal_ncomp <- which.min(cv_rmsep[-1])  # Exclude intercept-only model
cat("\nOptimal number of components:", optimal_ncomp, "\n")
cat("CV RMSEP at optimal:", cv_rmsep[optimal_ncomp + 1], "\n")

# -----------------------------------------------------------------------------
# 4. Model Evaluation
# -----------------------------------------------------------------------------

# Get predictions using optimal number of components
predictions <- predict(pcr_fat_model, ncomp = optimal_ncomp)
predictions <- as.vector(predictions)

# Calculate performance metrics
residuals <- Y_fat_clean - predictions
RMSE <- sqrt(mean(residuals^2))
R2 <- 1 - sum(residuals^2) / sum((Y_fat_clean - mean(Y_fat_clean))^2)
MAE <- mean(abs(residuals))

cat("\n=== Model Performance (Training Set) ===\n")
cat("RMSE:", round(RMSE, 4), "\n")
cat("R-squared:", round(R2, 4), "\n")
cat("MAE:", round(MAE, 4), "\n")

# Cross-validation performance
cat("\n=== Cross-Validation Performance ===\n")
cat("CV RMSE:", round(cv_rmsep[optimal_ncomp + 1], 4), "\n")

# Plot observed vs predicted
plot(Y_fat_clean, predictions,
     xlab = "Observed Fat",
     ylab = "Predicted Fat",
     main = paste("PCR Prediction (", optimal_ncomp, " components)", sep = ""),
     pch = 16, col = "blue")
abline(0, 1, col = "red", lwd = 2)

# Add regression line
abline(lm(predictions ~ Y_fat_clean), col = "darkgreen", lty = 2)
legend("topleft",
       legend = c("1:1 Line", "Regression"),
       col = c("red", "darkgreen"),
       lty = c(1, 2),
       lwd = c(2, 1))

# -----------------------------------------------------------------------------
# 5. Loading Plots
# -----------------------------------------------------------------------------

# Plot loadings for first few components
par(mfrow = c(2, 2))
for (i in 1:min(4, optimal_ncomp)) {
  plot(pcr_fat_model, plottype = "loadings", comps = i,
       main = paste("PC", i, "Loadings"))
}
par(mfrow = c(1, 1))

# -----------------------------------------------------------------------------
# 6. Score Plots
# -----------------------------------------------------------------------------

# Plot scores for first two components
plot(pcr_fat_model, plottype = "scores", comps = 1:2,
     main = "PCR Score Plot (PC1 vs PC2)")

cat("\n=== PCR Analysis Complete ===\n")
