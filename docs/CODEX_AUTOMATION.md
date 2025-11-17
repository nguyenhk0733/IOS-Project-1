# Quản lý Codex bot

Tài liệu này mô tả hai cách xử lý với bot Codex khi làm việc với pull request.

## 1. Tắt auto-review của Codex

Nếu vẫn muốn giữ bot trong tổ chức nhưng không muốn nó tự động review mọi PR, chỉnh sửa file cấu hình `.github/codex.yml` như sau:

```yaml
auto_review: false
manual_trigger_phrase: "@codex-bot review"
```

- Thuộc tính `auto_review: false` đảm bảo bot không còn tạo review tự động.
- `manual_trigger_phrase` giúp bạn hoặc thành viên khác có thể gọi bot khi thực sự cần.
- Sau khi commit thay đổi, bot sẽ đọc cấu hình mới cho các PR tiếp theo (thường trong vòng vài phút).

## 2. Xoá comment của bot sau khi merge

Để tránh log PR bị loãng, workflow `.github/workflows/codex-comment-cleanup.yml` sẽ chạy khi PR được merge và tự động xoá toàn bộ comment được tạo bởi bot.

```yaml
name: Remove Codex bot comments after merge
on:
  pull_request:
    types: [closed]
permissions:
  pull-requests: write
  issues: write
jobs:
  cleanup:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - name: Delete Codex bot comments
        uses: actions/github-script@v7
        with:
          script: |
            const { owner, repo } = context.repo;
            const number = context.payload.pull_request.number;
            const botLogin = process.env.CODEX_BOT_LOGIN || 'codex-bot';
            const comments = await github.paginate(
              github.rest.issues.listComments,
              { owner, repo, issue_number: number, per_page: 100 }
            );
            for (const comment of comments) {
              if (comment.user && comment.user.login === botLogin) {
                await github.rest.issues.deleteComment({ owner, repo, comment_id: comment.id });
              }
            }
        env:
          CODEX_BOT_LOGIN: ${{ vars.CODEX_BOT_LOGIN }}
```

### Biến cấu hình cần thêm

- Tạo repository variable `CODEX_BOT_LOGIN` (Settings → Secrets and variables → Actions → Variables) với giá trị chính xác của tài khoản bot, ví dụ `codex-review-bot`.
- Workflow cần quyền `pull-requests: write` và `issues: write` như trong ví dụ để có thể xoá comment.

Với hai bước trên bạn có thể chọn hoặc tắt auto-review, hoặc tiếp tục để bot hoạt động nhưng đảm bảo comment sẽ biến mất sau khi PR được merge.
