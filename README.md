# IOS Project 1

Thiết lập ban đầu cho dự án iOS bao gồm các bước sau:

1. **Yêu cầu hệ thống**
   - macOS với Xcode 15 trở lên.
   - CocoaPods và Swift Package Manager (SPM) nếu cần quản lý thư viện.

2. **Bắt đầu dự án**
   - Mở Xcode và tạo project iOS App mới với SwiftUI hoặc UIKit theo nhu cầu.
   - Đặt tên dự án và cấu hình nhóm (Team), bundle identifier.

3. **Cấu hình kiểm soát phiên bản**
   - Sao chép nội dung `.gitignore` trong repo để tránh commit các file build, cấu hình cục bộ.
   - Chạy `git init`, `git add .`, `git commit -m "Initial commit"` cho lần đầu.

4. **Quản lý phụ thuộc**
   - Với CocoaPods: tạo `Podfile`, chạy `pod install` và sử dụng `.xcworkspace`.
   - Với SPM: thêm package trực tiếp trong Xcode hoặc thông qua `Package.swift`.

5. **Cấu trúc thư mục gợi ý**
   - `Sources/` chứa code chính (Scenes, ViewModels, Services).
   - `Resources/` chứa assets, localized strings.
   - `Configs/` chứa file cấu hình environment.

6. **Chạy thử và kiểm tra**
   - Chọn simulator hoặc thiết bị thật trong Xcode.
   - Chạy `Cmd + R` để build và chạy ứng dụng.
   - Thiết lập kế hoạch viết Unit Test với XCTest (`Cmd + U`).

7. **Tự động hoá**
   - Sử dụng Fastlane để tạo lane build/test/deploy.
   - Thiết lập CI (GitHub Actions, Bitrise, v.v.) khi dự án sẵn sàng.

Các bước trên sẽ giúp bạn có nền tảng vững chắc trước khi bắt đầu phát triển tính năng cụ thể.
