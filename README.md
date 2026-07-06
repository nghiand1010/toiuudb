# 🚀 Nghia Engineering - Tối Ưu Database Core (toiuudb)

> Tài liệu, Slide bài giảng trực quan và mã nguồn thực hành cho chuỗi video chuyên sâu về Kiến trúc hệ thống và Tối ưu hiệu năng Database thực chiến. Khóa học lấy cảm hứng từ triết lý cốt lõi của cuốn sách **"Use The Index, Luke"** (Markus Winand).

## 📺 Kênh Truyền Thông & Tài Nguyên

* 🔴 **YouTube Playlist:** [Xem chuỗi video bài giảng Nghia Engineering](https://www.youtube.com/watch?v=qUWjzUkG4sc&list=PLNrbajNhGfQg)
* 📊 **Slide Trình Chiếu Trực Tiếp:** [Xem Slide tại đây](https://nghiand1010.github.io/toiuudb/sql_performance_luke.html) *(Vui lòng kích hoạt GitHub Pages trong mục Settings của Repo để link này hoạt động)*
* 💼 **LinkedIn:** [Kết nối với mình trên LinkedIn](https://www.linkedin.com/in/nghiand/)

---

## 📚 Bài 1: Khối và Trang (Blocks & Pages) - Bản Chất Vật Lý Của Disk I/O

Bài học nền móng giúp bạn đập tan tư duy coi Database là một "chiếc hộp đen" ma thuật và hiểu sâu về cách hệ thống giao tiếp với phần cứng.

### 1. Khoảng cách tốc độ phần cứng (Latency)

Quy đổi khoảng cách địa lý từ **Hà Nội vào Sài Gòn (1.700 km)**:

* 🚀 **RAM (Latency 100 ns):** Tương đương **Tên lửa siêu thanh** -> Bay mất đúng **1 giờ**.
* 🚶 **SSD NVMe (Latency 10 - 100 micro-seconds):** Tương đương **Người đi bộ** liên tục không nghỉ -> Mất từ **40 ngày đến 1 năm** mới tới nơi (chậm hơn RAM từ 100 đến 1.000 lần!).
* 🐌 **HDD cũ (Latency 10 ms):** Tương đương **Con ốc sên** bò lạch bạch -> Mất khoảng **11 năm**!

Chênh lệch vật lý cốt lõi giữa SSD và RAM: SSD Latency / RAM Latency xấp xỉ 1000 lần.

### 2. Quy tắc "Thùng Hàng" (Page Data)

Database không bao giờ đọc/ghi từng dòng dữ liệu lẻ loi. Nó bắt buộc phải gom dữ liệu lại thành một chiếc thùng lớn (gọi là **Page** hoặc **Block**) để khênh một lần từ ổ đĩa lên RAM (Buffer Pool).

* **MySQL (InnoDB):** Kích thước mặc định là 16 KB.
* **PostgreSQL / SQL Server / Oracle:** Kích thước mặc định là 8 KB.

> **Tư duy Architect:** Tối ưu Database thực chất là tối ưu cấu trúc bảng và thuật toán sao sau cho số lượng "thùng hàng" (Page) cần vận chuyển từ ổ đĩa lên RAM là **ÍT NHẤT**.

---

## 🛠️ Hướng Dẫn Chạy Slide Trên Máy Local

Slide được thiết kế hoàn toàn bằng HTML/CSS tĩnh, chạy mượt mà trên mọi trình duyệt mà không cần cài đặt thêm thư viện nặng nề:

1. Clone repo về máy:
   `git clone https://github.com/nghiand1010/toiuudb.git`
   
2. Mở file `sql_performance_luke.html` trực tiếp bằng trình duyệt của bạn (Chrome, Edge, Safari...) để xem slide.

---

Nếu tài liệu này giúp ích cho bạn trong công việc, hãy tặng mình **1 ⭐ Star** để ủng hộ kênh **Nghia Engineering** phát triển thêm nhiều nội dung chất lượng nhé!

**#NghiaEngineering #DatabaseCore #SystemArchitecture #BackendDevelopment #SQLPerformance**
