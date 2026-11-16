#!/usr/bin/env bash
# [관리자 PC] payload/ 안의 파일들의 SHA256 목록(SHA256SUMS)을 만든다.
#   ./admin_make_sums.sh            (키트 폴더에서 실행. Git Bash / WSL / Linux / macOS)
# 장비의 스크립트는 이 목록으로 "복사 중 손상·변경"을 검사한다.
# payload 의 파일을 바꾸거나 추가할 때마다 다시 실행해야 한다.
set -euo pipefail
KIT_DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cd "$KIT_DIR/payload"
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum 이 필요합니다 (Git Bash/WSL 사용)"; exit 1; }
find . -type f ! -name SHA256SUMS ! -name README.txt | sed 's#^\./##' | LC_ALL=C sort | while read -r f; do sha256sum -- "$f"; done > SHA256SUMS
[ -s SHA256SUMS ] || { echo "payload/ 에 파일이 없습니다"; rm -f SHA256SUMS; exit 1; }
echo "SHA256SUMS 생성 완료:"; cat SHA256SUMS
