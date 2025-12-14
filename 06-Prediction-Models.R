# =============================================================================
# 06-Prediction-Models.R
# PLS (Partial Least Squares) Regression for Coffee NIR Spectroscopy Data
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
# 3. PLS Model for Fat Prediction
# -----------------------------------------------------------------------------

cat("\n=== PLS Model for Fat Prediction ===\n")

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

# Create data frame for PLS (pls package requires this format)
pls_data <- data.frame(
  Fat = Y_fat_clean,
  spectra = I(X_clean)
)

# Fit PLS model with cross-validation
# Using 10-fold cross-validation to determine optimal number of components
set.seed(123)
pls_fat_model <- plsr(
  Fat ~ spectra,
  data = pls_data,
  ncomp = 20,
  validation = "CV",
  segments = 10
)

# Model summary
cat("\nPLS Model Summary:\n")
summary(pls_fat_model)

# Find optimal number of components using RMSEP
rmsep_values <- RMSEP(pls_fat_model)
cat("\nRMSEP values:\n")
print(rmsep_values)

# Plot RMSEP to visualize optimal components
plot(rmsep_values, main = "RMSEP vs Number of Components (Fat)")

# Determine optimal components (minimum RMSEP for CV)
cv_rmsep <- rmsep_values$val[2, 1, ]  # CV values
optimal_ncomp <- which.min(cv_rmsep[-1])  # Exclude intercept-only model
cat("\nOptimal number of components:", optimal_ncomp, "\n")
cat("CV RMSEP at optimal:", cv_rmsep[optimal_ncomp + 1], "\n")

# -----------------------------------------------------------------------------
# 4. Model Evaluation
# -----------------------------------------------------------------------------

# Get predictions using optimal number of components
predictions <- predict(pls_fat_model, ncomp = optimal_ncomp)
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
     main = paste("PLS Prediction (", optimal_ncomp, " components)", sep = ""),
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
# 5. Variable Importance (Loading Weights)
# -----------------------------------------------------------------------------

# Plot loading weights for first few components
par(mfrow = c(2, 2))
for (i in 1:min(4, optimal_ncomp)) {
  plot(pls_fat_model, plottype = "loadings", comps = i,
       main = paste("Component", i, "Loadings"))
}
par(mfrow = c(1, 1))

# -----------------------------------------------------------------------------
# 6. Function to Build PLS Model for Any Response Variable
# -----------------------------------------------------------------------------

build_pls_model <- function(data, response_var, spectral_cols, ncomp_max = 20, cv_segments = 10) {

  cat("\n=== PLS Model for", response_var, "===\n")

  # Extract X and Y
  X <- as.matrix(data[, spectral_cols])
  Y <- data[[response_var]]

  # Handle complete cases properly
  complete_idx <- complete.cases(cbind(Y, X))
  cat("Complete cases:", sum(complete_idx), "out of", length(complete_idx), "\n")

  if (sum(complete_idx) < 10) {
    warning("Insufficient complete cases for modeling")
    return(NULL)
  }

  X_clean <- X[complete_idx, ]
  Y_clean <- Y[complete_idx]

  # Create data frame for PLS
  pls_data <- data.frame(
    response = Y_clean,
    spectra = I(X_clean)
  )

  # Fit PLS model
  set.seed(123)
  model <- plsr(
    response ~ spectra,
    data = pls_data,
    ncomp = min(ncomp_max, nrow(X_clean) - 1),
    validation = "CV",
    segments = cv_segments
  )

  # Find optimal components
  rmsep_vals <- RMSEP(model)
  cv_rmsep <- rmsep_vals$val[2, 1, ]
  optimal_ncomp <- which.min(cv_rmsep[-1])

  # Calculate metrics
  predictions <- as.vector(predict(model, ncomp = optimal_ncomp))
  residuals <- Y_clean - predictions
  RMSE <- sqrt(mean(residuals^2))
  R2 <- 1 - sum(residuals^2) / sum((Y_clean - mean(Y_clean))^2)

  cat("Optimal components:", optimal_ncomp, "\n")
  cat("Training RMSE:", round(RMSE, 4), "\n")
  cat("Training R2:", round(R2, 4), "\n")
  cat("CV RMSE:", round(cv_rmsep[optimal_ncomp + 1], 4), "\n")

  return(list(
    model = model,
    optimal_ncomp = optimal_ncomp,
    RMSE = RMSE,
    R2 = R2,
    CV_RMSE = cv_rmsep[optimal_ncomp + 1],
    Y_observed = Y_clean,
    Y_predicted = predictions
  ))
}

# -----------------------------------------------------------------------------
# 7. Build Models for All Response Variables
# -----------------------------------------------------------------------------

cat("\n" , paste(rep("=", 60), collapse = ""), "\n")
cat("Building PLS Models for All Response Variables\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Store all models
all_models <- list()

for (var in response_vars) {
  result <- build_pls_model(coffee_data, var, spectral_cols)
  if (!is.null(result)) {
    all_models[[var]] <- result
  }
}

# -----------------------------------------------------------------------------
# 8. Summary of All Models
# -----------------------------------------------------------------------------

cat("\n" , paste(rep("=", 60), collapse = ""), "\n")
cat("Summary of All PLS Models\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

summary_df <- data.frame(
  Variable = character(),
  OptimalComp = integer(),
  TrainRMSE = numeric(),
  TrainR2 = numeric(),
  CV_RMSE = numeric(),
  stringsAsFactors = FALSE
)

for (var in names(all_models)) {
  m <- all_models[[var]]
  summary_df <- rbind(summary_df, data.frame(
    Variable = var,
    OptimalComp = m$optimal_ncomp,
    TrainRMSE = round(m$RMSE, 4),
    TrainR2 = round(m$R2, 4),
    CV_RMSE = round(m$CV_RMSE, 4)
  ))
}

print(summary_df)

# -----------------------------------------------------------------------------
# 9. Visualization of All Models
# -----------------------------------------------------------------------------

# Plot observed vs predicted for all variables
par(mfrow = c(2, 3))
for (var in names(all_models)) {
  m <- all_models[[var]]
  plot(m$Y_observed, m$Y_predicted,
       xlab = paste("Observed", var),
       ylab = paste("Predicted", var),
       main = paste(var, "(R2 =", round(m$R2, 3), ")"),
       pch = 16, col = "blue")
  abline(0, 1, col = "red", lwd = 2)
}
par(mfrow = c(1, 1))

cat("\n=== Analysis Complete ===\n")
