# fork260509-ver3-rev1

以 soybean-admin v3 為基礎的 admin 專案傘狀 workspace。給 AI agent 的規則在 `AGENTS.md`，下一步與未決在 `NOTES.md`。

## Repo 地圖

| 目錄 | repo | 分支 | 可見性 |
|---|---|---|---|
| 外層（本 repo） | miso168net/fork260509-ver3-rev1 | `main` | public |
| `base-web/` | miso168net/fork260509-soybean-admin-base（soybeanjs/soybean-admin 的 fork） | `ver3-rev1-base-web` | public |
| `rust-api/` | miso168net/fork260509-soybean-3-rust-api | `ver3-rev1-rust-api` | private |

兩個子庫都是源倉的 git worktree：源倉 clone 在外層根下的 `fork260509-soybean-admin-base/`、`fork260509-soybean-3-rust-api/`（gitignored），外層只記 gitlink。

## 新機就位

只在 WSL、Linux 或 macOS 的 shell 內操作（子庫 `.git` 檔記的是絕對路徑，Windows 原生工具開會壞）；需要 git ≥ 2.36（`git --version`）。

```sh
git clone https://github.com/miso168net/fork260509-ver3-rev1.git && cd fork260509-ver3-rev1
git clone https://github.com/miso168net/fork260509-soybean-admin-base.git fork260509-soybean-admin-base
git clone https://github.com/miso168net/fork260509-soybean-3-rust-api.git fork260509-soybean-3-rust-api
git -C fork260509-soybean-admin-base remote add upstream https://github.com/soybeanjs/soybean-admin.git && git -C fork260509-soybean-admin-base remote set-url --push upstream no_push
git -C fork260509-soybean-admin-base switch v3 && git -C fork260509-soybean-admin-base worktree add ../base-web ver3-rev1-base-web
git -C fork260509-soybean-3-rust-api worktree add ../rust-api ver3-rev1-rust-api
git config core.hooksPath .githooks && git config push.recurseSubmodules check
git config submodule.base-web.update none && git config submodule.rust-api.update none
for r in fork260509-soybean-admin-base fork260509-soybean-3-rust-api; do git -C "$r" config core.hooksPath ../.githooks-submodule; done
for r in . fork260509-soybean-admin-base fork260509-soybean-3-rust-api; do git -C "$r" config user.name '<名字>'; git -C "$r" config user.email '<信箱>'; git -C "$r" config user.useConfigOnly true; done
git -C fork260509-soybean-admin-base config rerere.enabled true && git -C fork260509-soybean-admin-base config merge.conflictStyle zdiff3
```

- 機密掃描器 betterleaks 1.7.3：從 https://github.com/betterleaks/betterleaks/releases/tag/v1.7.3 下載，以同頁 checksums.txt 驗證後放進 PATH（hook 每次都會核版本）。
- Claude Code：從舊機手動複製 `~/.claude/CLAUDE.md`，並把 `mattpocock-skills` 外掛裝成與舊機相同的版本（目前 1.3.1）。

## 防線核對（新機、跑過 base-web 的 pnpm 之後、hook 有疑慮時）

```sh
for r in . fork260509-soybean-admin-base fork260509-soybean-3-rust-api base-web rust-api; do printf '%s: ' "$r"; git -C "$r" rev-parse --git-path hooks/pre-push; done
git ls-files -s .githooks .githooks-submodule
git status --porcelain -- .githooks .githooks-submodule
betterleaks version
```

期望：外層印 `.githooks/pre-push`，其餘四個印 `../.githooks-submodule/pre-push`（pre-commit 同路徑）；`ls-files -s` 列出的 pre-commit、pre-push 都是 `100755`；status 無輸出；版本 `1.7.3`。任一不符就停手：人工修好並重跑本節後才 commit（agent 回報 user）。

## AI 工具前提

| 工具 | 前提 |
|---|---|
| Claude Code | 終端 `claude`，版本 ≥ 2.1.285，從外層根啟動；新 session 的 `/memory` 列得出外層 `AGENTS.md`（只看、按 Esc） |
| Codex | 從外層根啟動；問到是否信任此資料夾時選信任（標成不信任就不讀 `AGENTS.md`） |
| Antigravity CLI | 從外層根啟動 `agy`；問到是否信任此資料夾時選信任 |
| VS Code Copilot | 以單一資料夾開外層根，用預設的 Copilot 引擎 |

- 各工具的核准設定維持預設：Codex 不開 `network_access`、不用完全存取模式；Antigravity 不加 `allow command(git)`；VS Code 不開 `chat.tools.global.autoApprove`。
- 雲端 agent（GitHub Copilot coding agent、Codex cloud、base-web fork 的 `/oc` workflow）預設不用，要用先經 user 決定：它們的 commit 不經本機機密掃描。
- GitHub 端：外層與 base-web fork 已開 secret scanning 與 push protection；rust-api 是 private，只靠本機 hook。

## 跟進上游（base-web）

上游 v3 有新 commit 或穩定 tag 時（rebase 會改寫 base-web 每顆 commit 的 SHA，外層記的 gitlink 跟著要換）：

1. 先把外層所有動到 base-web 的功能分支合回 `main`：開著的外層分支的 gitlink 指向舊 SHA，rebase 後再合回會衝突。
2. `git -C fork260509-soybean-admin-base fetch upstream`，再看入口檔變動：`git -C base-web diff --stat <舊基線> <新基線> -- ':(glob)**/AGENTS.md' ':(glob)**/AGENTS.override.md' ':(glob)**/CLAUDE.md' ':(glob)**/CLAUDE.local.md' ':(glob)**/GEMINI.md' .github/copilot-instructions.md .github/instructions .rules .cursorrules .claude .agents .codex .cursor .gemini`。出現新入口檔就停手問 user；`AGENTS.md` 有變就逐條重核外層 `AGENTS.md` ④。
3. 先把舊 tip 推成封存分支（push 先問 user）：`git -C base-web push origin ver3-rev1-base-web:refs/heads/archive/ver3-rev1-base-web-<日期>`。封存分支永久保留：外層歷史裡的舊 gitlink 只能靠它取回，刪掉後舊的外層 commit 就 checkout 不出對應的 base-web。
4. `git -C base-web rebase --onto <新基線> <舊基線> ver3-rev1-base-web`；衝突時 rerere 會套用解過的解法。
5. `git -C base-web range-diff <舊基線>..origin/archive/ver3-rev1-base-web-<日期> <新基線>..HEAD` 逐顆核對我方 commit 沒走樣。
6. 另起一顆 commit，把 `base-web/x_fork.branch-origin.md` 的基線改成新基線的 40 碼完整 SHA（同時刪掉「可以安全忽略或刪除」那句）；`git -C base-web push --force-with-lease=ver3-rev1-base-web:<舊 tip 40 碼> origin ver3-rev1-base-web`（先問 user）；外層 `git add base-web` 並 commit。這次 gitlink 的新舊 SHA 互不為祖先，屬預期（AGENTS.md ③ 的例外）；commit 訊息寫明舊 tip 與封存分支名。
