-- STREAMING_CHUNK:Khởi tạo dữ liệu...
-- =========================================================================
-- BÀI LAB TỐI ƯU HÓA POSTGRESQL: TỪ LÝ THUYẾT ĐẾN THỰC CHIẾN
-- Kịch bản: Khởi tạo 5 triệu dòng dữ liệu giả lập.
-- =========================================================================

-- 1. Xóa và tạo bảng
DROP TABLE IF EXISTS sales_orders;
CREATE TABLE sales_orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount NUMERIC(10, 2),
    shipping_address TEXT
);

-- 2. Bơm 5 TRIỆU dòng dữ liệu (Khoảng 10-15s)
BEGIN;
INSERT INTO sales_orders (customer_id, order_date, status, total_amount, shipping_address)
SELECT
    (random() * 99999 + 1)::INT, 
    NOW() - '3 years'::interval * random(),
    (CASE WHEN random() < 0.7 THEN 'PAID' ELSE 'PENDING' END),
    (random() * 990 + 10)::NUMERIC(10,2),
    'Shipping address for customer ' || (random() * 99999 + 1)::INT::TEXT
FROM generate_series(1, 5000000); 
COMMIT;

-- 3. BƯỚC QUAN TRỌNG: Cập nhật Visibility Map (MVCC) và Thống kê
VACUUM ANALYZE sales_orders;


-- STREAMING_CHUNK:Demo Index Unique Scan...
-- =========================================================================
-- CẢNH 2: INDEX UNIQUE SCAN - "VỊ VUA TỐC ĐỘ"
-- =========================================================================
-- order_id là Primary Key -> Tự động có Unique Index.
-- Kết quả: Tốc độ < 0.1ms, cực kỳ tối ưu vì chỉ tìm 1 dòng là dừng (Không phải quét lá).
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM sales_orders WHERE order_id = 2500000;


-- STREAMING_CHUNK:Demo Index Range Scan với order_date...
-- =========================================================================
-- CẢNH 3: INDEX RANGE SCAN & "SỰ BẤT LỰC" KHI RANGE QUÁ RỘNG (ORDER_DATE)
-- =========================================================================
CREATE INDEX idx_orders_date ON sales_orders(order_date);

-- TEST 3.1: Dải quét HẸP (Lấy dữ liệu 1 ngày qua)
-- -> Postgres DÙNG INDEX (Index Scan / Bitmap Scan) vì lượng dữ liệu trả về ít.
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM sales_orders 
WHERE order_date >= NOW() - interval '1 day';

-- TEST 3.2: Dải quét RỘNG (Lấy dữ liệu 2 năm qua)
-- -> Postgres TỪ CHỐI INDEX, chuyển sang quét toàn bảng (Seq Scan).
-- Giải thích: Quét 70% bảng mà dùng Index sẽ sinh ra hàng triệu lần truy xuất ngẫu nhiên 
-- về bảng gốc (Random Access). Đọc tuần tự toàn bảng (Seq Scan) sẽ nhanh hơn!
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM sales_orders 
WHERE order_date >= NOW() - interval '2 years';


-- STREAMING_CHUNK:Demo nút thắt Table Access...
-- =========================================================================
-- CẢNH 4: NÚT THẮT "TABLE ACCESS" KHI ĐỌC VỀ BẢNG GỐC
-- =========================================================================
CREATE INDEX idx_basic_customer ON sales_orders(customer_id);

-- Bài toán: Lấy dữ liệu của 500 khách hàng (~25,000 đơn hàng)
-- Kết quả: Index Scan nhưng `BUFFERS (shared hit)` vọt lên hàng chục ngàn Block.
-- Lý do: Index tìm thấy ID rất nhanh, nhưng CSDL phải cầm địa chỉ đó chạy về bảng gốc 
-- (Heap Fetches / Table Access) 25,000 lần để lấy các cột còn lại.
EXPLAIN (ANALYZE, BUFFERS) 
SELECT customer_id, status, total_amount 
FROM sales_orders WHERE customer_id BETWEEN 1000 AND 1500;


-- STREAMING_CHUNK:Demo so sánh Multi-column và Covering Index...
-- =========================================================================
-- CẢNH 5: SO SÁNH MULTI-COLUMN vs COVERING INDEX (INCLUDE)
-- =========================================================================
DROP INDEX idx_basic_customer;

-- CÁCH 1: MULTI-COLUMN INDEX 
-- Đặc điểm: Sắp xếp cả 3 cột. Cây to, ghi chậm, nhưng phục vụ ORDER BY cực tốt.
CREATE INDEX idx_multi_column ON sales_orders(customer_id, status, total_amount);

-- Chạy ORDER BY -> Sẽ không có Node "Sort" vì cây đã được sắp xếp sẵn.
EXPLAIN (ANALYZE, BUFFERS) 
SELECT customer_id, status, total_amount FROM sales_orders 
WHERE customer_id BETWEEN 1000 AND 1500 ORDER BY total_amount;


-- CÁCH 2: COVERING INDEX (Từ khóa INCLUDE)
-- Đặc điểm: Chỉ sort customer_id, 2 cột kia được "đính kèm" ở Node lá. Cây nhẹ, ghi nhanh.
DROP INDEX idx_multi_column;
CREATE INDEX idx_covering ON sales_orders(customer_id) INCLUDE (status, total_amount);

-- Chạy ORDER BY -> CSDL phải tự Sort trong bộ nhớ (Sort Method: quicksort).
EXPLAIN (ANALYZE, BUFFERS) 
SELECT customer_id, status, total_amount FROM sales_orders 
WHERE customer_id BETWEEN 1000 AND 1500 ORDER BY total_amount;


-- STREAMING_CHUNK:Demo Sát thủ SELECT *...
-- =========================================================================
-- CẢNH 6: TỘI ÁC CỦA "SELECT *" (BẮT BUỘC DÙNG COVERING INDEX CỦA CẢNH 5)
-- =========================================================================

-- A. CÁCH VIẾT CHUẨN (Chỉ select đúng cột có trong INCLUDE)
-- -> Kết quả: INDEX ONLY SCAN. Lượng Buffers (RAM) tiêu thụ siêu nhỏ (< 100 Blocks). 
-- Tốc độ thần thánh vì không hề chạm vào ổ cứng.
EXPLAIN (ANALYZE, BUFFERS) 
SELECT customer_id, status, total_amount 
FROM sales_orders 
WHERE customer_id BETWEEN 1000 AND 1500;


-- B. CÁCH VIẾT TỒI TỆ (SELECT *)
-- -> Kết quả: Dấu * phá nát Covering Index. Rớt đài xuống Index Scan + Heap Fetches.
-- Buffers (RAM) vọt lên hàng chục ngàn Blocks chỉ để về ổ cứng lấy 1 vài cột thừa.
-- Hậu quả: Sập RAM Database, nghẽn băng thông mạng, sập RAM Application Server!
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * 
FROM sales_orders 
WHERE customer_id BETWEEN 1000 AND 1500;