# PLS Algorithm Fix Summary

## Vấn đề ban đầu
Lỗi: `Error in complete.cases(pred) : not all arguments have the same length`

## Các lần thử nghiệm và fix

### ❌ Fix #1: Convert matrix to data frame
- **Commit:** 530565d
- **Vấn đề:** predict.mvr() cần data frame thay vì matrix
- **Kết quả:** Vẫn lỗi

### ❌ Fix #2: Extract 3D array correctly
- **Commit:** 4b2ec30
- **Vấn đề:** predict.mvr() trả về 3D array [samples, 1, ncomp]
- **Giải pháp thử:** `as.vector(pred_result[, 1, ncomp])`
- **Kết quả:** Vẫn lỗi

### ❌ Fix #3: Named vector issue
- **Commit:** f0d7a63
- **Vấn đề:** optimal_ncomp là named vector
- **Giải pháp thử:** `as.integer(optimal_ncomp[var])`
- **Kết quả:** Vẫn lỗi

## ✅ Giải pháp cuối cùng: Viết lại hoàn toàn

### Commit: 7a439b7

**Thay đổi chính:**
1. **Dùng `fitted()` thay vì `predict()`**
   - `fitted()` trả về giá trị đã fit trực tiếp từ model
   - Không cần xử lý 3D array phức tạp
   - Đơn giản và an toàn hơn

2. **Dùng `unname()` thay vì `as.integer()`**
   - Loại bỏ name attribute từ vector
   - Giữ nguyên kiểu numeric

### Code mới

```r
# TRƯỚC (Lỗi)
pred_result <- predict(model, ncomp = ncomp, newdata = train_data)
Y_pred <- as.vector(pred_result[, 1, ncomp])

# SAU (Đúng)
Y_fitted <- fitted(model)[, , ncomp]
```

### Tại sao fitted() tốt hơn?

1. **Đơn giản:** Không cần convert matrix/data frame
2. **Trực tiếp:** Lấy giá trị fitted sẵn có
3. **Chuẩn:** Đây là cách chuẩn trong PLS analysis
4. **An toàn:** Không có vấn đề với array dimensions

## Các file đã sửa

### 06-Prediction-Models.Rmd

**Section 1: pls-performance (lines 83-131)**
- Dùng `fitted()` để tính R² trên training data
- Dùng `unname(optimal_ncomp[var])` để lấy ncomp

**Section 2: pls-predictions (lines 133-178)**
- Dùng `fitted()` cho biểu đồ Predicted vs Actual
- Loại bỏ hoàn toàn predict() và array extraction

**Section 3: pls-residuals (lines 180-222)**
- Dùng `fitted()` để tính residuals
- Đơn giản hóa code

## Test lại

Để test lại trong RStudio:

```r
# Render file
rmarkdown::render("06-Prediction-Models.Rmd")

# Hoặc render toàn bộ book
bookdown::render_book("index.Rmd", "bookdown::pdf_book")
```

## Kết luận

- ✅ Code đơn giản hơn nhiều
- ✅ Không còn vấn đề với array extraction
- ✅ Sử dụng approach chuẩn của PLS
- ✅ Dễ maintain và debug

**Khuyến nghị:** Luôn dùng `fitted()` cho training data, chỉ dùng `predict()` khi cần dự đoán trên new data.
