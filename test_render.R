#!/usr/bin/env Rscript

# Test render bookdown
tryCatch({
  bookdown::render_book("index.Rmd", "bookdown::pdf_book")
  cat("\n✓ Render thành công!\n")
  cat("File output: _report/Coffee_NIR_BTL_Report.pdf\n")
}, error = function(e) {
  cat("\n✗ Lỗi khi render:\n")
  cat(conditionMessage(e), "\n")
})
