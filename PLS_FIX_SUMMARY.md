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

### Commit chính: 7a439b7, cdb0e02, 985771d

**Thay đổi chính:**
1. **Dùng `fitted()` thay vì `predict()`**
   - `fitted()` trả về giá trị đã fit trực tiếp từ model
   - Không cần xử lý 3D array phức tạp
   - Đơn giản và an toàn hơn

2. **Dùng `unname()` thay vì `as.integer()`**
   - Loại bỏ name attribute từ vector
   - Giữ nguyên kiểu numeric

3. **Loại bỏ `R2()` function - Tính R² manually**
   - `R2()` gọi `complete.cases()` internally gây lỗi
   - Tính R²_CV từ RMSECV: `R²_CV = 1 - (RMSECV² / Var(Y))`
   - Áp dụng cho cả PLS và PCR

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

## Timeline các commits

1. **58be338** - Fix PLS and PCR model prediction algorithms
2. **530565d** - Fix all PLS model prediction calls to use data frames
3. **4b2ec30** - Fix PLS predict() 3D array extraction issue
4. **f0d7a63** - Fix named vector indexing issue in PLS predictions
5. **7a439b7** - ⭐ Complete rewrite of PLS prediction sections - use fitted() approach
6. **e4885df** - Add documentation and test for fitted() approach
7. **f9998f8** - Fix R2() function call - remove unused estimate parameter
8. **cdb0e02** - ⭐ Remove R2() function - calculate R²_CV manually from RMSECV
9. **985771d** - ⭐ Apply same R²_CV fix to PCR performance calculation

## Kết luận

- ✅ Code đơn giản hơn nhiều
- ✅ Không còn vấn đề với array extraction
- ✅ Sử dụng approach chuẩn của PLS
- ✅ Loại bỏ hoàn toàn R2() function issues
- ✅ Tính toán manual, transparent và reliable
- ✅ Áp dụng nhất quán cho cả PLS và PCR
- ✅ Dễ maintain và debug

**Khuyến nghị:**
1. Luôn dùng `fitted()` cho training data, chỉ dùng `predict()` khi cần dự đoán trên new data
2. Tính R² manually từ RMSECV thay vì dùng R2() function
3. Dùng `unname()` để loại bỏ names từ vectors trước khi indexing
