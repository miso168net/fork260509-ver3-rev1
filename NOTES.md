# NOTES — 下一步與未決

只寫未來式；完成即刪（歷史看 git）；不寫機敏。

## 下一步

- 開工條件：`git -C fork260509-soybean-admin-base ls-remote --tags --refs upstream 'v3.*' | grep -v -E -e '-(alpha|beta|rc)'` 有輸出。
- 開工時：
  - base-web 依 README「跟進上游」rebase 到該 tag。
  - 在外層根跑 `/setup-matt-pocock-skills`：tracker 選本機 markdown（`.scratch/`）、domain 選 single-context；它會在 AGENTS.md 加「## Agent skills」區塊。
  - 安裝 soybean skill：在外層根、不加 `-g`；skills CLI 與各 skill 釘完整版本（先問 user），命令前加 `DISABLE_TELEMETRY=1`；`skills-lock.json` 入版控，`.gitignore` 加 `.agents/skills/`、`.claude/skills/`；實測能否釘到 commit SHA；同批在 README 補「安裝 soybean skill」與新機照 lock 重裝的步驟，並把 AGENTS.md ④1 改指向該節。
- 第一次在外層根開 Claude Code 新 session 時驗證：`/memory` 列出外層 AGENTS.md；Read 一支 base-web 的檔後，不再開檔就答得出 `base-web/AGENTS.md`「已知陷阱」的內容（驗證跨 worktree 的子目錄載入）。
- 第一次在外層根用 Codex、`agy`、VS Code Copilot 時各驗一次：問「base-web 缺 skill 怎麼做」要答回報 user、不安裝；問「開工條件」要答得出 NOTES 首條（Codex 與 Antigravity 不展開 @，答得出去讀 NOTES.md 也算過）；之後 `git diff --stat AGENTS.md` 為空。
- rust-api 出現第一支 Cargo.toml 時：建 `rust-api/AGENTS.md`（首行指回外層 AGENTS.md）與 `rust-api/.gitattributes`，`rust-api/.gitignore` 補 `.env` 類規則。

## 未決（待 user）

- 介面語言：第一輪 `/grill-with-docs` 決定，結果寫成 ADR。
- 第一次改上游既有檔時：要不要加一支檢查「改到上游既有檔的 diff 區塊都帶 `ver3:` 標記」的 pre-commit（約 20 行）。
- 新機就位：第二台機器照 README 實跑一次後，決定要不要改成腳本。
- betterleaks 要不要從 1.7.3 升到最新穩定版 1.10.0（2026-11-04；v2.0.0-rc 系列是預發布）：升版時同批改 `.githooks/scan-lib.sh` 的 `BETTERLEAKS_VER`、`.githooks/pre-commit` 檔頭與 README「新機就位」。
- 從 rev6 搬哪些功能、先後順序：開工時一題一問。
