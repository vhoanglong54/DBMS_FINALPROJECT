# Branch rules — tv1 (Leader / Core / Security)

## Phạm vi được sở hữu

- Contract chung: ERD, data dictionary, schema nền, identity, nhân sự, security và authentication.
- Solution/app foundation, CI, test convention, integration và tài liệu điều phối.
- Review mọi thay đổi ảnh hưởng table/column/FK, role, connection/authentication hoặc cấu trúc thư mục chung.

## Quy tắc bắt buộc

1. Bắt đầu task bằng Issue GYM tương ứng; một thời điểm chỉ giữ tối đa một task `In progress`.
2. Trước khi code: `git fetch origin --prune` và `git rebase origin/develop` khi working tree sạch.
3. Không commit secret, password SQL Login, `.bak`, `bin/obj`, file máy cá nhân.
4. Thay đổi schema phải kèm migration/script chạy sạch, data dictionary, seed và test.
5. Không tự merge PR của TV1; cần ít nhất một thành viên review và CI xanh.
6. Không sửa nghiệp vụ membership/billing hoặc class/check-in của TV2/TV3 nếu chưa có issue và owner đồng thuận.
7. Sau mỗi task hoàn thành, thêm một entry vào `HANDOFF_LOG.md` trước commit/PR.

## Definition of Done

- Build 0 warning/0 error; unit/smoke test liên quan pass.
- Không phá clean-install; hướng dẫn chạy được cập nhật.
- PR ghi `Closes #...`, liệt kê file/contract ảnh hưởng và bằng chứng rubric.
- Handoff log có commit/PR, test, thay đổi contract, việc còn lại và người nhận bàn giao.
