# Thiết lập remote GitHub và quản trị nhóm

## Thông tin cần chốt trước khi tạo remote

- Owner: tài khoản GitHub sở hữu email `vhoanglong54@gmail.com` (cần xác thực bằng đăng nhập/token của chính tài khoản đó).
- Tên repo: `NhomXX_QuanLyPhongGym` — thay `XX` bằng số nhóm chính thức, theo đúng quy tắc rubric.
- Visibility: **Private** trong giai đoạn làm bài; mời đúng 3 tài khoản GitHub còn lại quyền **Write**. Leader là Owner/Admin. Đổi Public chỉ khi giảng viên yêu cầu.

Email không phải là thông tin xác thực GitHub; không lưu personal access token (PAT) vào repo, issue hay chat. Nếu dùng GitHub CLI, leader đăng nhập tương tác trên máy của mình rồi chạy:

```powershell
gh auth login --web --git-protocol https
gh repo create NhomXX_QuanLyPhongGym --private --source . --remote origin --push
git push --set-upstream origin develop
git push origin feature/tv1-leader-core-security feature/tv2-membership-billing feature/tv3-classes-checkin feature/tv4-web-reporting
```

Sau đó kiểm tra URL remote bằng `git remote -v` và xác nhận năm nhánh `main`, `develop`, bốn `feature/tv*` đã xuất hiện trên GitHub.

## Cấu hình branch protection (Settings → Branches)

| Nhánh | Push trực tiếp | PR review | Status check | Ai được merge |
|---|---|---|---|---|
| `main` | cấm | bắt buộc 1 review | `build-and-smoke` bắt buộc khi CI có | TV1; chỉ sau demo/release checklist |
| `develop` | cấm | bắt buộc 1 review | `build-and-smoke` | TV1 sau khi owner module duyệt |
| `feature/tv*` | owner nhánh push | khuyến nghị 1 review | chạy test module | owner nhánh |

Bật thêm: dismiss stale approvals khi có push mới, yêu cầu branch up-to-date trước merge, chặn force push/xóa branch `main`/`develop`, và squash merge để lịch sử release gọn. Không bật rule cấm commit history của feature branch nếu nhóm chưa quen rebase.

## GitHub Project / Issues

Tạo Project dạng board với các cột `Backlog`, `Ready`, `In progress`, `In review`, `Blocked`, `Done`. Tạo issues GYM-01…GYM-12 đúng bảng trong `TEAM_TASKS.md`, gán một assignee, milestone, label `tv1`…`tv4` và `db`/`web`/`docs`/`test`. Mọi PR ghi `Closes #<issue>` và mô tả test; `Done` chỉ khi PR đã merge `develop` và có evidence rubric.

## Kiểm tra trước release/nộp bài

1. `main` có tag dạng `v1.0-final` và có thể clone/run từ README.
2. Download/clone mới, dựng SQL Server sạch, seed, build app và chạy demo trực tiếp.
3. Tạo GitHub Release đính kèm source zip, script/backup theo chính sách giảng viên; không đưa secret hoặc database thật có dữ liệu nhạy cảm lên repo.

