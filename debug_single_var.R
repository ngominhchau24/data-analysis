# Detailed debug script for PLS - test with single variables
# Check for NA, data size, and dimension issues

library(tidyverse)
library(pls)

# Load data
coffee_data <- read.csv("coffee_nirs.csv", sep = ";", row.names = 1, stringsAsFactors = FALSE)

# Convert European format
convert_to_numeric <- function(x) {
  if(is.character(x)) {
    x <- gsub("\\.", "", x)
    x <- gsub(",", ".", x)
    return(as.numeric(x))
  }
  return(x)
}

for(col in names(coffee_data)) {
  if(col != "Localisation") {
    coffee_data[[col]] <- convert_to_numeric(coffee_data[[col]])
  }
}

# Define variables
chemical_vars <- c("CGA", "Cafeine", "Fat", "Trigonelline", "DM")
nir_vars <- grep("^S[0-9]+$", names(coffee_data), value = TRUE)

cat("=== DATA OVERVIEW ===\n")
cat("Total samples:", nrow(coffee_data), "\n")
cat("Chemical variables:", length(chemical_vars), "\n")
cat("NIR variables:", length(nir_vars), "\n\n")

# Check NA in each chemical variable
cat("=== NA COUNT IN CHEMICAL VARIABLES ===\n")
for(var in chemical_vars) {
  na_count <- sum(is.na(coffee_data[[var]]))
  cat(sprintf("%-15s: %3d NA values (%.1f%%)\n",
              var, na_count, 100 * na_count / nrow(coffee_data)))
}
cat("\n")

# Check NA in NIR variables
nir_na_count <- sum(is.na(coffee_data[, nir_vars]))
cat("NIR variables total NA:", nir_na_count, "\n\n")

# Prepare matrices
X <- as.matrix(coffee_data[, nir_vars])
Y <- as.matrix(coffee_data[, chemical_vars])

cat("=== MATRIX DIMENSIONS ===\n")
cat("X (NIR) dimensions:", dim(X), "\n")
cat("Y (Chemical) dimensions:", dim(Y), "\n\n")

# Test with EACH chemical variable individually
cat("=== TESTING EACH VARIABLE INDIVIDUALLY ===\n\n")

for(var in chemical_vars) {
  cat("========================================\n")
  cat("Testing variable:", var, "\n")
  cat("========================================\n")

  # Create data frame
  pls_data <- data.frame(Y = coffee_data[[var]], X)
  cat("1. Original data frame dimensions:", dim(pls_data), "\n")
  cat("   NA in Y column:", sum(is.na(pls_data$Y)), "\n")

  # Find complete cases
  complete_idx <- complete.cases(pls_data)
  n_complete <- sum(complete_idx)
  n_incomplete <- sum(!complete_idx)
  cat("2. Complete cases:", n_complete, "\n")
  cat("   Incomplete cases:", n_incomplete, "\n")

  # Clean data
  pls_data_clean <- pls_data[complete_idx, ]
  cat("3. Clean data dimensions:", dim(pls_data_clean), "\n")
  cat("   Rows removed:", nrow(pls_data) - nrow(pls_data_clean), "\n")

  # Train model
  cat("4. Training PLS model...\n")
  set.seed(123)

  tryCatch({
    pls_model <- plsr(Y ~ ., data = pls_data_clean, validation = "CV",
                      segments = 10, ncomp = 5)
    cat("   Model trained successfully!\n")

    # Find optimal ncomp
    rmsep_vals <- RMSEP(pls_model, estimate = "CV")$val[1,,]
    optimal_ncomp <- which.min(rmsep_vals[-1])
    cat("   Optimal ncomp:", optimal_ncomp, "\n")

    # Test prediction
    cat("5. Testing prediction...\n")
    cat("   Using ncomp:", optimal_ncomp, "\n")

    # Get prediction result
    pred_result <- predict(pls_model, ncomp = optimal_ncomp, newdata = pls_data_clean)
    cat("   pred_result class:", class(pred_result), "\n")
    cat("   pred_result dimensions:", dim(pred_result), "\n")
    cat("   pred_result dim names:", names(dimnames(pred_result)), "\n")

    # Try to extract predictions
    cat("6. Extracting predictions...\n")

    # Method 1: Direct indexing
    cat("   Method 1: pred_result[, 1, optimal_ncomp]\n")
    Y_pred_1 <- pred_result[, 1, optimal_ncomp]
    cat("   Length:", length(Y_pred_1), "\n")
    cat("   Class:", class(Y_pred_1), "\n")

    # Get Y_train
    Y_train <- pls_data_clean$Y
    cat("   Y_train length:", length(Y_train), "\n")

    # Check if lengths match
    if(length(Y_pred_1) == length(Y_train)) {
      cat("   ✓ Lengths MATCH!\n")

      # Try to calculate R²
      ss_res <- sum((Y_train - Y_pred_1)^2)
      ss_tot <- sum((Y_train - mean(Y_train))^2)
      r2 <- 1 - (ss_res / ss_tot)
      cat("   R² calculated:", r2, "\n")
    } else {
      cat("   ✗ LENGTH MISMATCH!\n")
      cat("   Y_train:", length(Y_train), "\n")
      cat("   Y_pred_1:", length(Y_pred_1), "\n")
    }

    # Method 2: as.vector with indexing
    cat("   Method 2: as.vector(pred_result[, 1, optimal_ncomp])\n")
    Y_pred_2 <- as.vector(pred_result[, 1, optimal_ncomp])
    cat("   Length:", length(Y_pred_2), "\n")
    cat("   Match with Y_train:", length(Y_pred_2) == length(Y_train), "\n")

    # Method 3: Direct as.vector (WRONG)
    cat("   Method 3: as.vector(pred_result) - WRONG WAY\n")
    Y_pred_3 <- as.vector(pred_result)
    cat("   Length:", length(Y_pred_3), "\n")
    cat("   Match with Y_train:", length(Y_pred_3) == length(Y_train), "\n")

    cat("\n   SUCCESS for", var, "\n")

  }, error = function(e) {
    cat("   ERROR:", conditionMessage(e), "\n")
  })

  cat("\n")
}

cat("\n=== DEBUG COMPLETE ===\n")
