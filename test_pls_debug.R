# Test script to debug PLS prediction error
# Error: "Error in complete.cases(pred) : not all arguments have the same length"

# Load libraries
library(tidyverse)
library(pls)

# Load and process data (same as index.Rmd)
coffee_data <- read.csv("coffee_nirs.csv", sep = ";", row.names = 1, stringsAsFactors = FALSE)

# Convert European number format
convert_to_numeric <- function(x) {
  if(is.character(x)) {
    x <- gsub("\\.", "", x)      # Remove dots (thousands separator)
    x <- gsub(",", ".", x)       # Replace comma with dot (decimal)
    return(as.numeric(x))
  }
  return(x)
}

# Apply conversion to all columns except Localisation
for(col in names(coffee_data)) {
  if(col != "Localisation") {
    coffee_data[[col]] <- convert_to_numeric(coffee_data[[col]])
  }
}

# Define variable groups
chemical_vars <- c("CGA", "Cafeine", "Fat", "Trigonelline", "DM")
nir_vars <- grep("^S[0-9]+$", names(coffee_data), value = TRUE)

cat("Data loaded successfully!\n")
cat("Samples:", nrow(coffee_data), "\n")
cat("Chemical variables:", length(chemical_vars), "\n")
cat("NIR wavelengths:", length(nir_vars), "\n\n")

# Prepare data for PLS
X <- as.matrix(coffee_data[, nir_vars])
Y <- as.matrix(coffee_data[, chemical_vars])

cat("X dimensions:", dim(X), "\n")
cat("Y dimensions:", dim(Y), "\n\n")

# Test with first chemical variable
var <- chemical_vars[1]  # CGA
cat("Testing with variable:", var, "\n\n")

# Create data frame
pls_data <- data.frame(Y = coffee_data[[var]], X)
cat("pls_data dimensions:", dim(pls_data), "\n")
cat("NA count in Y:", sum(is.na(pls_data$Y)), "\n\n")

# Find complete cases
complete_idx <- complete.cases(pls_data)
cat("Complete cases:", sum(complete_idx), "out of", nrow(pls_data), "\n\n")

# Clean data
pls_data_clean <- pls_data[complete_idx, ]
cat("Clean data dimensions:", dim(pls_data_clean), "\n\n")

# Train PLS model
set.seed(123)
cat("Training PLS model...\n")
pls_model <- plsr(Y ~ ., data = pls_data_clean, validation = "CV",
                  segments = 10, ncomp = 5)

cat("Model trained successfully!\n\n")

# Test prediction with different data types
cat("=== Testing predictions ===\n\n")

# Test 1: Predict with full data frame (CORRECT)
cat("Test 1: Predict with data frame (train_data)\n")
try({
  pred1 <- predict(pls_model, ncomp = 3, newdata = pls_data_clean)
  cat("Success! Prediction dimensions:", dim(pred1), "\n")
  cat("Prediction structure:\n")
  str(pred1)
  cat("\n")
})

# Test 2: Predict with matrix (INCORRECT - this is the bug)
cat("Test 2: Predict with matrix (X_clean)\n")
X_clean <- X[complete_idx, ]
cat("X_clean dimensions:", dim(X_clean), "\n")
cat("X_clean class:", class(X_clean), "\n")
try({
  pred2 <- predict(pls_model, ncomp = 3, newdata = X_clean)
  cat("Prediction returned!\n")
  cat("Prediction dimensions:", dim(pred2), "\n")
  cat("Prediction structure:\n")
  str(pred2)
  cat("\n")
}, silent = FALSE)

# Test 3: Convert matrix to data frame
cat("Test 3: Predict with matrix converted to data frame\n")
try({
  newdata_df <- as.data.frame(X_clean)
  cat("newdata_df dimensions:", dim(newdata_df), "\n")
  cat("newdata_df class:", class(newdata_df), "\n")
  pred3 <- predict(pls_model, ncomp = 3, newdata = newdata_df)
  cat("Success! Prediction dimensions:", dim(pred3), "\n")
  cat("Prediction structure:\n")
  str(pred3)
  cat("\n")
})

cat("\n=== DIAGNOSIS COMPLETE ===\n")
cat("The issue is that predict.mvr() requires a data.frame, not a matrix.\n")
cat("When given a matrix, it may return unexpected structure causing complete.cases() to fail.\n")
