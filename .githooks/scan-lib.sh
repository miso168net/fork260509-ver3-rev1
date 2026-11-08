# .githooks/scan-lib.sh — 三 repo 共用機密掃描函式（自 rev6 .githooks/lib/scan-range.sh 與 pre-commit 掃描段改寫）；由各 hook source（檔名刻意不用 lib/ 目錄：外層 .gitignore 的 Python 範本 lib/ 規則會擋掉）。
# 呼叫端先設 SCAN_CONFIG＝外層 .gitleaks.toml 路徑。
#
# 涵蓋面：
#   pre-commit＝暫存區 diff；git commit 各形（-a、-- <path>、子目錄執行、--amend、linked worktree）都會觸發。
#   pre-push＝本次推送範圍內每顆 commit 的 patch（merge commit 以 --diff-merges=remerge 呈現衝突解法與 evil 部分）、
#     每顆 commit 的訊息、推送的 annotated tag 物件（含 tag 訊息）。cherry-pick、revert、rebase、自動 merge 不跑
#     pre-commit，由 pre-push 補攔。
# 已知邊界（不攔）：
#   二進位檔與設了 -diff 屬性的檔（diff 沒有文字內容）；指向 blob／tree 的 tag 的內容；
#   repo 根目錄的 .gitleaksignore／.betterleaksignore 與行內 gitleaks:allow／betterleaks:allow 註解（掃描器原生的放行管道）；
#   `--no-verify`：繞過 pre-commit＝機密進本機歷史、由 pre-push 再攔；`git push --no-verify` 則兩層都繞過；
#   hook 檔不在場時 git 靜默不跑：外層工作樹切到不含 .githooks／.githooks-submodule 的 commit，或兩源倉的
#     core.hooksPath 指不到本目錄（見 .githooks-submodule/pre-commit 檔頭）。
#   以 URL 推送、或目標 remote 沒有任何追蹤 ref 時，退階掃整條分支（base-web 會連上游歷史一起掃、可能誤擋）。
#   pre-push 命中時，--verbose 會原文印出該 commit 的訊息（--redact 只遮命中值）。
#
# ★--config 顯式帶、不靠自動探索：探索不到 config 時 betterleaks 靜默降級為內建規則並回 0；另以 config check 斷言
#   規則數，擋 [extend] useDefault 打錯或被刪（規則掉到個位數、照樣回 0）。
# ★--redact 不可省（不帶會把命中值明文印進終端）；一律原生二進位的 git 子命令（容器形式不帶 GIT_INDEX_FILE，
#   `git commit -a` 會掃到 0 bytes 而靜默漏報）。
# ★betterleaks 呼叫 git 時不帶 --no-color：使用者設 color.ui／color.diff=always 會讓 diff 帶色碼、解析成 0 bytes 而
#   靜默放行；log.showRoot=false 會讓 root commit 不出 diff。故掃描前以 GIT_CONFIG_* 環境變數覆寫三項
#   （需 git ≥ 2.31；--diff-merges=remerge 需 git ≥ 2.36，舊版 git log 失敗即落入「掃描器異常」而擋下）。
# ★exit code 分流：掃描器 2＝機密命中；其餘非零＝掃描器本身異常（含 127 缺執行檔）。

BETTERLEAKS_VER="1.10.0"
# 執行檔用帶版本號的檔名：同機其他專案可能共用 betterleaks 本名、釘別的版本，以檔名區隔、互不影響。
BETTERLEAKS_BIN="betterleaks-${BETTERLEAKS_VER}"
SCAN_MIN_RULES=100

# 掃描器在場、恰為釘定版本、設定檔載入的規則數正常，並設好 git 顯示覆寫；任一不符回 1（hook 擋下）。
scan_require() {
  if ! command -v "$BETTERLEAKS_BIN" >/dev/null 2>&1; then
    echo "[scan] ✗ 找不到 ${BETTERLEAKS_BIN}——安裝 ${BETTERLEAKS_VER}：https://github.com/betterleaks/betterleaks/releases/tag/v${BETTERLEAKS_VER}（以同頁 checksums.txt 驗證後解壓，執行檔改名為 ${BETTERLEAKS_BIN} 放進 ~/.local/bin）" >&2
    return 1
  fi
  sc_ver=$("$BETTERLEAKS_BIN" version 2>/dev/null || true)
  if [ "$sc_ver" != "$BETTERLEAKS_VER" ]; then
    echo "[scan] ✗ ${BETTERLEAKS_BIN} 的版本（${sc_ver:-讀不到}）≠ 釘定 ${BETTERLEAKS_VER}——改裝 ${BETTERLEAKS_VER} 後重試" >&2
    return 1
  fi
  sc_rules=$("$BETTERLEAKS_BIN" config check --config "$SCAN_CONFIG" 2>/dev/null | sed -n 's/^OK: \([0-9][0-9]*\) rules.*/\1/p')
  if [ -z "$sc_rules" ] || [ "$sc_rules" -lt "$SCAN_MIN_RULES" ]; then
    echo "[scan] ✗ 外層 .gitleaks.toml 規則載入異常（config check 回報 ${sc_rules:-無法讀取} 條，至少應有 ${SCAN_MIN_RULES} 條）——檔案缺席、TOML 有誤，或 [extend] useDefault = true 被改掉；修正後重試" >&2
    return 1
  fi
  export GIT_CONFIG_COUNT=3 \
    GIT_CONFIG_KEY_0=color.ui GIT_CONFIG_VALUE_0=never \
    GIT_CONFIG_KEY_1=color.diff GIT_CONFIG_VALUE_1=never \
    GIT_CONFIG_KEY_2=log.showRoot GIT_CONFIG_VALUE_2=true
}

# 跑一次 betterleaks（子命令與其引數原樣傳入），回傳其 exit code。
scan_run() {
  "$BETTERLEAKS_BIN" "$@" --config "$SCAN_CONFIG" --redact --verbose --exit-code 2
}

# 判讀 exit code：$1＝rc、$2＝hook 名、$3＝掃描對象說明；命中或異常時印訊息並回 1。
scan_judge() {
  [ "$1" -eq 0 ] && return 0
  if [ "$1" -eq 2 ]; then
    echo "[$2] ✗ 機密命中（$3；上方輸出含 rule id 與位置、值已遮蔽）——移除後重試；誤報→修外層 .gitleaks.toml allowlist，絕不 --no-verify" >&2
  else
    echo "[$2] ✗ 掃描器本身異常（exit $1；$3）、非機密命中——檢查 betterleaks 安裝與外層 .gitleaks.toml" >&2
  fi
  return 1
}

# pre-commit 面：掃暫存區。
scan_staged() {
  scan_require || return 1
  scan_run git --pre-commit --staged </dev/null
  scan_judge $? pre-commit 暫存區
}

# 新 ref 的掃描範圍：目標 remote 有追蹤 ref → 排除它已有的 commit；否則（以 URL 推送、或該 remote 從未 fetch）掃整條。
sp_new_ref_range() {
  if [ -n "$(git for-each-ref --count=1 "refs/remotes/$sp_remote")" ]; then
    printf '%s --not --remotes=%s' "$1" "$sp_remote"
  else
    printf '%s' "$1"
  fi
}

# pre-push 面：$1＝remote 名（git 傳給 pre-push 的第一個引數）；stdin 每行「<local ref> <local oid> <remote ref> <remote oid>」。
#   一般更新（兩 oid 皆非全零、遠端 oid 在本機）→ <remote oid>..<local oid>
#   新 ref 首推（remote oid 全零），或強推而遠端 oid 不在本機 → sp_new_ref_range
#   刪除 ref（local oid 全零）→ 跳過（無內容可掃）
scan_push_ranges() {
  scan_require || return 1
  sp_remote=${1:-origin}
  sp_status=0
  while read -r sp_local_ref sp_local_oid sp_remote_ref sp_remote_oid; do
    [ -z "$sp_local_ref" ] && continue
    case "$sp_local_oid" in
      *[!0]*) ;;
      *) continue ;;
    esac
    case "$sp_remote_oid" in
      *[!0]*)
        if git cat-file -e "$sp_remote_oid^{commit}" 2>/dev/null; then
          sp_range="$sp_remote_oid..$sp_local_oid"
        else
          sp_range=$(sp_new_ref_range "$sp_local_oid")
        fi ;;
      *) sp_range=$(sp_new_ref_range "$sp_local_oid") ;;
    esac
    scan_run git --log-opts="$sp_range --diff-merges=remerge" </dev/null
    scan_judge $? pre-push "${sp_local_ref} → ${sp_remote_ref}、patch、範圍 ${sp_range}" || sp_status=1
    # shellcheck disable=SC2086  # sp_range 刻意分詞（含 --not --remotes=<remote>）
    git log --format='commit %H%n%B' $sp_range | scan_run stdin
    scan_judge $? pre-push "${sp_local_ref} → ${sp_remote_ref}、commit 訊息、範圍 ${sp_range}" || sp_status=1
    if [ "$(git cat-file -t "$sp_local_oid" 2>/dev/null)" = tag ]; then
      git cat-file tag "$sp_local_oid" | scan_run stdin
      scan_judge $? pre-push "${sp_local_ref}、tag 物件 ${sp_local_oid}" || sp_status=1
    fi
  done
  return "$sp_status"
}
