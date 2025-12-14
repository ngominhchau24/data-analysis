# Hướng dẫn Build PDF Report

## Các bước thực hiện:

### Kiểm tra các packages cần thiết

```r
# Install các packages nếu chưa có
packages <- c(
  "bookdown", "tidyverse", "knitr", "kableExtra",
  "naniar", "visdat", "DataExplorer",
  "factoextra", "FactoMineR", "cluster", "dendextend",
  "gridExtra", "RColorBrewer", "mclust"
)

install.packages(setdiff(packages, rownames(installed.packages())))
```

### Build PDF từ R Console
Thay path /home/user/data-analysis bằng path của bạn (folder chứa file csv)
```r
# Trong R console, chạy:
setwd("/home/user/data-analysis")
bookdown::render_book("index.Rmd", "bookdown::pdf_book")
```

### Build từ Terminal/Command Line

```bash
cd /home/user/data-analysis
Rscript test_render.R
```

## Output

File PDF sẽ được tạo tại: `_report/Coffee_NIR_BTL_Report.pdf`

## Troubleshooting

### Nếu gặp lỗi "package not found":
```r
install.packages("tên_package")
```

### Nếu gặp lỗi về LaTeX:
Đảm bảo đã cài đặt TinyTeX:
```r
tinytex::install_tinytex()
```

### Nếu gặp lỗi encoding (tiếng Việt):
File đã được cấu hình sử dụng `xelatex` để hỗ trợ Unicode.

### Nếu gặp lỗi memory:
Thử render từng chapter riêng lẻ:
```r
rmarkdown::render("01-BTL.Rmd")
rmarkdown::render("02-PCA-Clustering.Rmd")
rmarkdown::render("03-Outliers.Rmd")
```

## Kiểm tra nhanh

```r
# Test xem file có lỗi syntax không
bookdown::clean_book()  # Xóa cache cũ
bookdown::render_book("index.Rmd", "bookdown::pdf_book", clean = TRUE)
```
