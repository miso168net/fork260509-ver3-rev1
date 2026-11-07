# AGENTS.md — ver3-rev1 共用規則

本檔是 ver3-rev1 唯一的專案規則正本；Claude Code、Codex、Antigravity CLI、VS Code Copilot 都從這裡讀。

## ① 現況與啟動

- ver3-rev1＝以 soybean-admin v3 為基礎的 admin 專案。外層（本 repo，public）放規則、文件與兩個子庫的 gitlink：`base-web/`＝前端（public fork 的 worktree），`rust-api/`＝後端（private repo 的 worktree，取代 v3 自帶後端）；repo 與分支見 `README.md`「Repo 地圖」。
- 開工前必讀： @NOTES.md
- 工作目錄不是外層根時，先告知 user：外層 `.claude/settings.json`（先問清單、外掛切換、claudeMdExcludes）與 NOTES.md 的匯入這次都沒生效。
- 外層根下的 `fork260509-soybean-admin-base/`、`fork260509-soybean-3-rust-api/` 是兩個子庫的源倉（gitignored）：保留原狀、只讀；工作一律在子庫 worktree 裡做。
- 子庫 git 報損壞（找不到 gitdir 等）時停手回報 user，等 user 處理。

## ② 全工具硬規則

1. push、merge（含 `gh pr merge`）、強推、建 issue 或 PR：先問 user，同意後單獨下一條命令。
2. 每顆 commit 都經過 git hook 的機密掃描（betterleaks）：照常 commit、讓 hook 跑完，被擋就修內容；`--no-verify` 一律不用。測試用的假機密在執行期串接，不寫成完整字面。
3. 新增工具、依賴或 skill：先列出可用的穩定版本請 user 選，再釘完整版本號。
4. 查版本用套件管理器自帶的命令（例如 `pnpm view`、`cargo search`）；對外請求（URL、header、body、User-Agent）不帶 user 的 email。
5. 工作只在既有的三個工作樹（外層根、`base-web/`、`rust-api/`）裡做：不建 git worktree，也不用各工具內建的 worktree 隔離與 `/implement-spec` 的平行模式（別處的 worktree 找不到 hook，commit 會漏掃）。
6. 專案規則只寫在本檔與 `rust-api/AGENTS.md`（`base-web/AGENTS.md` 是上游檔，照 ④6）。任何目錄多出 CLAUDE.md、`.claude/CLAUDE.md`、CLAUDE.local.md 或 AGENTS.override.md，就有工具改讀它、不讀該處的 AGENTS.md；user 要建時先說明這個後果並確認。
7. 各工具的 `/init`、`/import` 類指令不在本 repo 跑（會改寫本檔或另建入口檔）。
8. 每個 repo 同時只有一個寫入者 session（改檔、或下會寫 `.git` 的 git 命令）；寫子庫的 session 要回外層更新 gitlink（③），所以也是外層的寫入者。其他 session 唯讀：user 以唯讀模式開（見 `README.md`「AI 工具前提」）或說明只讀的 session，git 查詢一律寫成 `git --no-optional-locks …`（例 `git --no-optional-locks -C base-web status`），以免順手改寫 `.git/index`、撞上寫入者的 `index.lock`。要寫入前發現不是自己造成的改動（`git status` 列出沒動過的檔、讀過的檔內容變了、`index.lock` 已存在），先停手問 user 有沒有別的 session 在寫。

## ③ 子庫 git 紀律

- 子庫的 git 一律用 `git -C base-web …`、`git -C rust-api …`，不 cd 進子庫下 git 命令。
- 兩段式 commit：先在子庫 commit，以 `git -C <子庫> log -1` 確認落地，再回外層 `git add <子庫>` 並 commit（更新 gitlink）。
- `git submodule update`、`git submodule add` 一律不用：會 reset worktree、抹掉未推的 commit。
- gitlink（`git rev-parse HEAD:<子庫>`）與子庫 HEAD 不一致時先判方向。gitlink 那顆不在本機（`git -C <子庫> cat-file -e <gitlink>^{commit}` 失敗）就先 `git -C <子庫> fetch origin <長名>`。`git -C <子庫> merge-base --is-ancestor HEAD <gitlink>` 成立＝gitlink 在前，跑 `git -C <子庫> merge --ff-only <gitlink>`（這時回外層 `git add` 會把 gitlink 倒回）。反向成立＝子庫在前：`git -C <子庫> log --oneline <gitlink>..HEAD` 多出的 commit 全屬目前外層分支的票才 `git add <子庫>`，夾有別的功能就停手問 user。兩者都不成立也停手問 user；唯一例外是 base-web 跟進上游 rebase 後的那次更新（照 README「跟進上游」）。
- 目錄與口語用短名（base-web、rust-api）；branch 與 push 用長名（`ver3-rev1-base-web`、`ver3-rev1-rust-api`、外層 `main`）。
- 分支：只有外層每個功能開一條分支，完成後 `merge --no-ff` 合回 `main`（照 ②1 先問）；base-web 與 rust-api 直接 commit 在各自的長名工作分支。兩條外層分支先後動到同一子庫時，合回時 git 會把 gitlink 快轉到較新的那顆；兩顆互不為祖先才會衝突，那時停手問 user。功能中途放棄時，已進子庫工作分支的 commit 用 revert 收回。
- commit 訊息：`<type>(<scope>): <zh-TW 說明>`，type 用 Conventional Commits 的英文字；訊息含反引號時用 `git commit -F -` 加 quoted heredoc。
- 各 repo 的 `x_fork.branch-origin.md` 是分支來源與基線的紀錄：保留，基線改變時同步更新。

## ④ base-web：上游規約與覆寫

`base-web/AGENTS.md` 是上游 soybean-admin 的碼內慣例。動 base-web 的檔之前，context 裡還沒有它就先讀它並照用；下列各條取代它的對應節：

1. 「缺 skill 先装」：缺 skill 時回報 user，不自行 `npx skills add`；soybean skill 由 user 在開工時裝在外層專案層（見 NOTES「開工時」）。
2. 「提交规约」：commit 訊息照 ③，不用 `pnpm commit`；要向上游 `soybeanjs/soybean-admin` 提 PR 時（照 ②1 先問），PR 與其中的 commit 改照上游規約全英文。上游 `.vite-hooks` 在這裡不會執行：commit 前自己跑 `pnpm lint`，收尾照上游「交付门槛」。
3. 「硬约定」的文件同步與「顺手修文档」：上游文件（`docs/v3-task.md`、`docs/v3*.md`、CHANGELOG 等）維持原樣；與上游文件衝突時回報 user。
4. `pnpm-deps-upgrade`：只跑到檢查門檻，結果交 user，不 commit、不 push；上游既有的依賴宣告不自行改。
5. 「已知陷阱」的 git worktree 並行開發：不適用，照 ②5。
6. 上游既有檔預設不改，要改先問 user。改動處加一行 `// ver3: 原因（票路徑）`（模板內用 `<!-- ver3: … -->`），不抄原行；原內容用 `git -C base-web diff <基線> HEAD -- <檔>` 查（`<檔>` 寫相對 `base-web/` 的路徑，例 `src/main.ts`；基線記在 `base-web/x_fork.branch-origin.md`）。
7. 實值寫在 base-web 的 `.env`（gitignored）；`.env.prod`、`.env.example` 是公開的上游檔，只放公開預設值。
8. 「必读 skills」末段點名的其他 skill（`pr`、`code-review`、`diagnosing-bugs`、`tdd`、`writing-for-agents` 等）只在 user 觸發時用（照 ⑥）；`pnpm release`（`soy release`）不跑。

## ⑤ rust-api

`rust-api/` 是我方 private 後端（目前是空殼）；碼內慣例寫在 `rust-api/AGENTS.md`，存在時先讀。契約對齊 v3：端點、`{ code, message, data }` 回應格式與業務碼照 base-web 的 `src/routes/api/**`、`src/schema/**`、`src/constants/error-code.ts`。契約的唯一源頭在 base-web，rust-api 不輸出 OpenAPI 文件或端點（要加先問 user）；用上游整合測試（`test/integration/`）改打 rust-api 驗證一致。

## ⑥ 開發流程（mattpocock-skills）

- 流程 skill（`/grill-with-docs`、`/to-spec`、`/to-tickets`、`/implement` 等）只在 Claude Code 由 user 觸發；其他工具照 `docs/agents/*.md` 的慣例與 `.scratch/` 的票工作。
- 跑 `/grill-with-docs` 時點名叫用 `domain-modeling`（模型常略過它），收尾核對 `GLOSSARY.md` 與 `docs/adr/` 有沒有變動。
- 開票時把要動的子庫當下的 HEAD 記在票上，當審查的 fixed point；外層改動的 fixed point 用功能分支的起點。
- 審查一律以全名 `mattpocock-skills:code-review` 叫用（裸 `/code-review` 是 Claude Code 內建的另一支）。子庫的 diff 與 commit 清單寫成 `git -C <子庫> diff <fixed point>...HEAD`、`git -C <子庫> log --oneline -F --grep='<票路徑>' <fixed point>..HEAD` 交給審查子代理；外層與子庫都有改動時各審一次。審查子代理用 general-purpose（Explore、Plan 不載入本檔）；規範來源列入本檔與 `base-web/AGENTS.md`，兩者衝突時以本檔 ④ 為準。
- `/implement` 收尾順序：子庫 commit（訊息帶票路徑）→ 審查 → 修正另起一顆 commit → 外層更新 gitlink，同一顆把票的 `Status:` 改成 resolved。
- 處置審查 finding 前先查 `docs/adr/`：已決的不改並引 ADR 號。
- 票的 Out of Scope 每項寫「不做：理由」或「延後→<票路徑>」。

## ⑦ 權威與拍板級

- 優先序：`docs/adr/`（accepted）＞本檔（含 ④）＞skill 指示與 `base-web/AGENTS.md`（兩者衝突時回報 user）。ADR 的決定要改，須 user 同意並另立新 ADR 取代。
- 拍板級事項先問 user（子代理同樣適用）：資料結構與 migration、前後端契約、user 可見行為與介面語言、偏離上游的 fork 差異。

## ⑧ rev6 參照

- rev6（repo `miso168net/fork260509-rev6` 與其兩子庫）是前一代、仍在並行開發；ver3 只讀參照：不寫入 rev6 的任何檔，也不改 rev6 stack 的 schema、seed、設定。
- 引用 rev6 的編號或路徑一律加 `rev6:` 前綴並附 SHA（例：`rev6:ADR-00041@3769f40`）；rev6 的帳本不搬進來。
- 移植 rev6 碼時先讀對應碼、重寫註解；移植進來的檔在所屬 repo 跑 `git -C <子庫> grep --untracked -n -E 'rev5:|rev6|ADR-0[0-9]{4}|(^|[^A-Za-z])(RL|LL|BL|GT)-[0-9]|docsync|docs/ops|\.specify|刀' -- <移植檔>`，逐筆清掉失效引用。ver3 與 rev6 衝突時以 ver3 為準。

## ⑨ 文件寫法

1. 每個事實只寫一處，其他地方寫指針；能從 repo 直接查到的（package.json scripts、目錄結構、`--help`）不抄。
2. 現況文件只寫現在式；待辦放 `.scratch/` 的票或 NOTES.md；歷史靠 git。
3. 引用寫檔名加節名，不寫行號、本機絕對路徑或 `tmp/` 下的具名檔；路徑包反引號。
4. 改名稱、數字或集合時，外層、`git -C base-web`、`git -C rust-api` 各跑一次 `git grep --untracked -n -i -F '<詞>'`（外層的 grep 掃不到子庫；`--untracked` 才掃得到還沒 add 的新檔）。
5. 外層與 rust-api 的文件、註解用 zh-TW；上游與第三方檔維持原文。UI 文案在介面語言定案前，照現有語言包（`zh-CN`、`en`）各寫一份。
6. 安全缺陷、帳密、內部端點只在對話裡回報 user，由 user 決定記在哪；不寫進公開面（票、NOTES、README、commit、ADR、GLOSSARY、base-web 的註解）。ADR 只寫決策與失敗時的方向。
7. 專案事實與決策寫進 NOTES.md 或 `docs/adr/`，不能只留在任一工具的私有記憶（例如 Claude 的 auto memory）。
8. 新增治理檔、hook 或檢查之前，先寫出它要防的事故，以及何時可以拿掉。

## 已知陷阱（徵狀 → 第一個動作）

- `/mnt/*`（drvfs）上寫檔後立即讀取偶發 ENOENT → 先用 `ls` 或 `git status` 核實況再重試。
- drvfs 上 `chmod +x` 不進 git → 用 `git update-index --chmod=+x <檔>`。
- 在 base-web 跑過任何 pnpm 指令後（`prepare` 會跑 `vp config`）→ 照 README「防線核對」核 hook，不符就停手回報 user。
- Claude 不照本檔做 → 核外層根與上層沒有 CLAUDE.md、`.claude/CLAUDE.md`、CLAUDE.local.md；Claude 的 `/memory` 只看清單、按 Esc（選到不存在的檔會直接建出它）。
- 含 `push`、`merge` 字樣的命令（連 commit 訊息裡的字也算）會觸發 Claude 的先問清單 → 屬預期，照常送出、等 user 核准。
