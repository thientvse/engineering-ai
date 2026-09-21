*[English version](README.md)*

# Engineering AI — Shared Code Review Framework

Bộ config/prompt/rule dùng chung để chạy **AI code review** (read-only, advisory) cho các repo khác. Repo này **không chứa code để review** — nó là framework được các repo khác trỏ tới khi chạy review.

## 1. Yêu cầu trước khi dùng

- Windows + PowerShell.
- [Kiro CLI](https://kiro.dev) đã cài và đăng nhập (`kiro-cli`), vì script hiện chạy review qua agent `code-reviewer` của Kiro.
- Repo muốn review phải là **Git repo có remote `origin`** (script fetch và diff trên `origin/<branch>`, không dùng branch local).
- Đã push cả 2 branch (branch cần review và branch base) lên remote.

## 2. Cài đặt

1. Clone repo này về máy, ví dụ `D:\skill\engineering-ai`.
2. Set biến môi trường `ENGINEERING_AI_HOME` trỏ tới đường dẫn đó.

   Tạm thời cho session hiện tại:
   ```powershell
   $env:ENGINEERING_AI_HOME = "D:\skill\engineering-ai"
   ```

   Set cố định (khuyến nghị, để không phải set lại mỗi lần mở terminal mới):
   ```powershell
   [System.Environment]::SetEnvironmentVariable("ENGINEERING_AI_HOME", "D:\skill\engineering-ai", "User")
   ```
   Sau đó mở terminal mới để biến có hiệu lực.

## 3. Cách chạy review cho 1 repo bất kỳ

```powershell
cd <đường-dẫn-tới-repo-cần-review>
D:\skill\engineering-ai\scripts\review.ps1 <review-branch> <base-branch>
```

Ví dụ:
```powershell
cd C:\projects\my-service
D:\skill\engineering-ai\scripts\review.ps1 feature/add-payment develop
```

- `review-branch`: nhánh chứa thay đổi cần review (thường là branch của PR).
- `base-branch`: nhánh nền để so sánh diff. Chỉ chấp nhận `develop`, `master`, hoặc `main`.

Script sẽ:
1. Kiểm tra `ENGINEERING_AI_HOME` hợp lệ và đủ file cần thiết.
2. Kiểm tra thư mục hiện tại là Git repo có remote `origin`.
3. `git fetch origin --prune`, kiểm tra 2 branch tồn tại trên remote.
4. In ra danh sách file thay đổi (`git diff --stat origin/<base>...origin/<review>`).
5. Dựng prompt review, gọi `kiro-cli` (agent `code-reviewer`, chế độ read-only — **không sửa/commit/push/merge/approve**).
6. Ghi kết quả ra file `review-report.md` ở gốc repo đang review, đồng thời in ra terminal.

## 4. Review dựa trên gì

Khi chạy, AI sẽ đọc theo thứ tự:

1. [config/defaults.yml](config/defaults.yml) — ngôn ngữ output (mặc định `vi`), severity levels, hành vi read-only.
2. [prompts/code-review.md](prompts/code-review.md) — quy trình review chuẩn: xác định scope, detect stack, evidence requirement, false-positive control, severity, test gaps, impact analysis, format output.
3. [rules/common-review.md](rules/common-review.md) — rule chung, áp dụng mọi stack.
4. Rule riêng theo stack detect được từ file thay đổi:
   - [rules/java-spring-review.md](rules/java-spring-review.md) — nếu có `pom.xml`, `build.gradle`, `src/main/java`, dependency Spring Boot...
   - [rules/nextjs-react-review.md](rules/nextjs-react-review.md) — nếu có `next.config.*`, `app/`, `pages/`, dependency Next.js/React...
   - Repo full-stack (cả backend lẫn frontend thay đổi) sẽ load cả hai.

Kết quả trả về theo format cố định: Summary → Risk Level → Findings (CRITICAL/MAJOR/MINOR/SUGGESTION, kèm evidence + confidence) → Test Gaps → Impact Analysis → Positive Observations → Final Review Result (`READY FOR HUMAN REVIEW` / `CHANGES RECOMMENDED` / `CHANGES REQUIRED`).

**Lưu ý:** kết quả chỉ mang tính tham khảo (advisory). Người review vẫn là người quyết định merge cuối cùng.

## 5. Tuỳ chỉnh riêng cho từng repo (tuỳ chọn)

Nếu repo cần review có yêu cầu riêng (ví dụ đổi ngôn ngữ output, bật/tắt mục nào đó), tạo file `.engineering-ai.yml` ở root repo đó — cấu hình trong file này sẽ override `config/defaults.yml`.

## 6. Giới hạn hiện tại

- Chỉ hỗ trợ chạy qua **Kiro CLI**. Các thư mục `adapters/claude` và `adapters/codex` đang để trống, chưa có adapter tương ứng cho Claude Code hay Codex CLI.
- `base-branch` chỉ nhận `develop` / `master` / `main`. Nếu team dùng quy ước branch khác (ví dụ `release/*`), cần sửa `scripts/review.ps1` trước khi dùng.
- Chỉ hoạt động trên **PowerShell**, chưa có bản tương đương cho bash/macOS/Linux.
- `workflows/github` hiện đang trống — chưa có tích hợp CI/GitHub Action tự động chạy review khi mở PR.

## 7. Xử lý lỗi thường gặp

| Thông báo lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| `ENGINEERING_AI_HOME is not configured.` | Chưa set biến môi trường | Set lại theo mục 2 |
| `Current directory is not inside a Git repository.` | Đang không đứng trong 1 git repo | `cd` vào đúng thư mục repo |
| `Git remote 'origin' was not found.` | Repo chưa add remote | `git remote add origin <url>` |
| `Base branch does not exist: origin/<x>` / `Review branch does not exist: origin/<x>` | Branch chưa được push lên remote | `git push origin <branch>` rồi chạy lại |
| `No changes found between origin/<base> and origin/<review>` | Hai branch không có khác biệt | Kiểm tra lại đúng branch cần so sánh |
| `Failed to run Kiro CLI` | Chưa cài hoặc chưa đăng nhập `kiro-cli` | Cài đặt và đăng nhập Kiro CLI trước |
