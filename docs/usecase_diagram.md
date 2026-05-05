# Use Case Diagram - Health Tracker App

## Actors
- **User**: Người dùng chính sử dụng ứng dụng
- **External APIs**: Spoonacular, FDC, Open Food Facts (hệ thống bên ngoài)

## Use Cases

### 1. Authentication
- [ UC01 ] Đăng nhập bằng Email
- [ UC02 ] Đăng nhập bằng Google
- [ UC03 ] Đăng nhập bằng Facebook
- [ UC04 ] Đăng ký tài khoản mới
- [ UC05 ] Quên mật khẩu
- [ UC06 ] Đăng xuất

### 2. Onboarding
- [ UC07 ] Xem onboarding screens
- [ UC08 ] Nhập thông tin cá nhân (chiều cao, cân nặng, tuổi, giới tính)

### 3. Diary Management
- [ UC09 ] Theo dõi calories/dinh dưỡng
- [ UC10 ] Thêm bữa ăn ( Breakfast, Lunch, Dinner, Snack )
- [ UC11 ] Quét barcode để thêm thực phẩm
- [ UC12 ] Tìm kiếm thực phẩm qua API
- [ UC13 ] Theo dõi lượng nước uống
- [ UC14 ] Thêm lượng nước
- [ UC15 ] Theo dõi cân nặng
- [ UC16 ] Thêm cân nặng mới
- [ UC17 ] Theo dõi giấc ngủ
- [ UC18 ] Ghi nhận thời gian ngủ
- [ UC19 ] Đo nhịp tim
- [ UC20 ] Xem thống kê sức khỏe

### 4. Recipe Management
- [ UC21 ] Xem danh sách công thức nấu ăn
- [ UC22 ] Tìm kiếm công thức
- [ UC23 ] Xem chi tiết công thức
- [ UC24 ] Lọc công thức theo mục tiêu

### 5. Workout & Plans
- [ UC25 ] Xem kế hoạch tập luyện
- [ UC26 ] Xem chi tiết bài tập
- [ UC27 ] Xem chi tiết exercise

### 6. Community Feed
- [ UC28 ] Xem bài viết trong feed
- [ UC29 ] Tạo bài viết mới
- [ UC30 ] Like bài viết
- [ UC31 ] Comment bài viết
- [ UC32 ] Xem danh sách comments

### 7. Social Features
- [ UC33 ] Nhắn tin riêng tư
- [ UC34 ] Xem danh sách cuộc trò chuyện

### 8. Challenges
- [ UC35 ] Xem thử thách hàng ngày
- [ UC36 ] Xem thử thách hàng tuần
- [ UC37 ] Xem thử thách hàng tháng

### 9. Meditation
- [ UC38 ] Thiền định

### 10. Profile
- [ UC39 ] Xem profile cá nhân
- [ UC40 ] Chỉnh sửa profile

### 11. Settings
- [ UC41 ] Cài đặt ứng dụng
- [ UC42 ] Thông báo

### 12. Notifications
- [ UC43 ] Xem thông báo

## Relationships
- User -> Authentication -> Onboarding
- User -> Diary Management (trung tâm)
- User -> Recipe Management
- User -> Workout & Plans
- User -> Community Feed
- User -> Social Features
- User -> Challenges
- User -> Meditation
- User -> Profile
- User -> Settings
- User -> Notifications
- Diary Management -> External APIs (food search)
- Recipe Management -> External APIs (spoonacular)