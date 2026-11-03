#!/usr/bin/env bash
# 이전 작업 부산물 점검 — 읽기 전용: 목록만 만들고 아무것도 삭제/이동하지 않는다.
# 사용: sudo ./70-cleanup-list.sh
# 분류:  삭제후보 = 지워도 서비스·롤백에 영향 없음 (승인 후 별도 단계에서 처리)
#        보존     = 컷오버/롤백/증빙에 필요 — 컷오버 후 안정화 기간이 지나면 재검토
#        확인     = 내용·소유를 확인해야 판단 가능 (타 서비스 것일 수 있음)
# 대상 아님(절대 건드리지 않음): /var/lib/h100/{db,media}, /etc/h100, /var/log/h100,
#        h100-db/h100-module-c/h100-web 및 이를 쓰는 이미지, 타 서비스 컨테이너·볼륨(예: mariadb-legacy)
set -uo pipefail
shopt -s nullglob
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
OUT="$WORK/cleanup-candidates.txt"; : > "$OUT"
DEL_BYTES=0; KEEP_BYTES=0; REV_BYTES=0

row() {  # row 분류 경로 [설명]
  local tag="$1" p="$2" note="${3:-}" b h d
  [ -e "$p" ] || return 0
  b=$(du -sb "$p" 2>/dev/null | cut -f1); h=$(du -sh "$p" 2>/dev/null | cut -f1); d=$(stat -c '%y' "$p" 2>/dev/null | cut -c1-10)
  printf '%-6s %7s  %s  %s%s\n' "$tag" "${h:-?}" "${d:-?}" "$p" "${note:+  ← $note}" | tee -a "$OUT"
  case "$tag" in 삭제후보) DEL_BYTES=$((DEL_BYTES+${b:-0}));; 보존) KEEP_BYTES=$((KEEP_BYTES+${b:-0}));; *) REV_BYTES=$((REV_BYTES+${b:-0}));; esac
}
hr() { local n; n=$(numfmt --to=iec --suffix=B "$1" 2>/dev/null || echo "$1"); printf '%s' "$n"; }
sec() { say ""; say "== $* =="; printf '\n== %s ==\n' "$*" >> "$OUT"; }
newest_first() { ls -1dt "$@" 2>/dev/null; }   # 수정시각 내림차순

say "== 70-cleanup-list $(date '+%F %T') (읽기 전용) =="

sec "A. 소스·설정 사본"
for p in /opt/h100/src/*.old-*; do row 보존 "$p" "이전 소스 사본 — 컷오버 안정화 후 삭제"; done
for p in /root/h100.conf.bak-* /etc/nginx/conf.d/h100.conf.* ; do row 보존 "$p" "nginx h100 설정 변경 전 백업"; done
for p in /etc/nginx/conf.d/*.bak* /etc/nginx/conf.d/*~ /etc/nginx/sites-enabled/*.bak* /etc/nginx/*.bak*; do
  case "$p" in */h100.conf.*) continue;; esac
  row 확인 "$p" "타 서비스 nginx 백업일 수 있음"
done
for p in /etc/h100/*.bak* /etc/h100/*~ /etc/h100/*.orig; do row 확인 "$p" "내용 비밀 포함 가능 — 열지 않고 소유만 확인"; done
for p in /opt/h100/migration/*.bak* /opt/h100/migration/*.orig /opt/h100/migration/migration.conf.*; do
  case "$p" in *.example) continue;; esac
  row 확인 "$p"
done

sec "B. 키트·패키지·전송물"
kits=(); for p in /root/h100-migration-kit* /root/pkg[0-9]* /home/*/h100-migration-kit* /home/*/pkg[0-9]* /opt/h100/h100-migration-kit* /tmp/h100-migration-kit*; do [ -e "$p" ] && kits+=("$p"); done
if [ ${#kits[@]} -gt 0 ]; then
  first=1
  while IFS= read -r p; do
    if [ $first -eq 1 ]; then row 보존 "$p" "가장 최신 키트 — 재배포용 1개 유지"; first=0; else row 삭제후보 "$p" "구버전 키트(설치된 /opt/h100/migration 과 별개 사본)"; fi
  done < <(newest_first "${kits[@]}")
fi
for p in /root/h100-incoming /home/*/h100-incoming; do row 보존 "$p" "구 서버 덤프 수신분 — 컷오버·롤백 대조용"; done
row 보존 /root/h100-legacy "구 서버 스냅샷 — 구 서버 정리 시점까지"
for p in /home/*/*.tar.gz /home/*/*.sha256 /home/*/*.sql /home/*/*.sql.gz; do
  case "$p" in */h100-migration-kit*) continue;; esac
  row 확인 "$p" "홈 디렉터리 전송물"
done

sec "C. 이전 작업 실행 기록 (/root/h100-migration/<시각>/)"
works=(/root/h100-migration/*/)
if [ ${#works[@]} -gt 0 ]; then
  cnt=0
  while IFS= read -r p; do
    p=${p%/}; cnt=$((cnt+1))
    if [ -e "$p/iptables-before.rules" ]; then row 보존 "$p" "방화벽 적용 전 규칙 포함(롤백 참고)"
    elif [ $cnt -le 3 ]; then row 보존 "$p" "최근 실행 3건"
    else row 삭제후보 "$p" "과거 점검/로그 (요약은 Obsidian 노트에 있음)"; fi
  done < <(newest_first "${works[@]}")
fi

sec "D. Docker (h100 이미지·컨테이너만 대상)"
if command -v docker >/dev/null 2>&1; then
  inuse=$(docker ps -a --format '{{.Image}}' 2>/dev/null)
  declare -A seen=()
  while IFS="|" read -r ref _id size since; do
    [ -n "$ref" ] || continue
    if printf '%s\n' "$inuse" | grep -qxF "$ref"; then
      printf '%-6s %7s  %s  %s  ← 사용 중\n' 보존 "$size" "$since" "image $ref" | tee -a "$OUT"
    else
      repo=${ref%%:*}
      if [ -z "${seen[$repo]:-}" ]; then seen[$repo]=1
        printf '%-6s %7s  %s  %s  ← 직전 태그 — 롤백용 1개 유지 권장\n' 확인 "$size" "$since" "image $ref" | tee -a "$OUT"
      else
        printf '%-6s %7s  %s  %s  ← 미사용 구 태그\n' 삭제후보 "$size" "$since" "image $ref" | tee -a "$OUT"
      fi
    fi
  done < <(docker images --format '{{.Repository}}:{{.Tag}}|{{.ID}}|{{.Size}}|{{.CreatedSince}}' 2>/dev/null | grep '^h100/')
  dang=$(docker images -f dangling=true -q 2>/dev/null | wc -l)
  [ "$dang" -gt 0 ] && printf '%-6s %7s  %s  %s\n' 삭제후보 "-" "-" "dangling 이미지 ${dang}개 (태그 없는 중간 레이어)" | tee -a "$OUT"
  docker ps -a -f status=exited --format '{{.Names}}|{{.Image}}|{{.Status}}' 2>/dev/null | while IFS='|' read -r n i s; do
    case "$n" in h100-*) printf '%-6s %7s  %s  %s\n' 확인 "-" "-" "종료된 컨테이너 $n ($i, $s)" | tee -a "$OUT";;
                 *) printf '%-6s %7s  %s  %s\n' 제외 "-" "-" "타 서비스 컨테이너 $n — 대상 아님" | tee -a "$OUT";; esac
  done
  docker volume ls -qf dangling=true 2>/dev/null | while read -r v; do
    printf '%-6s %7s  %s  %s\n' 확인 "-" "-" "미사용 볼륨 $v  ← 타 서비스/레거시 DB 일 수 있음, 소유 확인 전 삭제 금지" | tee -a "$OUT"
  done
  info "build cache / 전체 사용량(참고):"; docker system df 2>/dev/null | sed 's/^/[INFO] /' | tee -a "$OUT"
else
  warn "docker 명령 없음"
fi

sec "E. 임시 파일·WAR"
declare -A tseen=()
for p in /tmp/*h100* /tmp/*.sql* /tmp/*.tar* /var/tmp/*h100*; do
  [ -e "$p" ] || continue
  [ -n "${tseen[$p]:-}" ] && continue; tseen[$p]=1
  [ -n "$(find "$p" -maxdepth 0 -mtime +1 2>/dev/null)" ] && row 삭제후보 "$p" "1일 이상 지난 임시 파일"
done
wars=(/opt/h100/war/*.war); if [ ${#wars[@]} -gt 0 ]; then
  first=1; while IFS= read -r p; do
    if [ $first -eq 1 ]; then row 보존 "$p" "최신 WAR — 이미지 재빌드 원본"; first=0; else row 확인 "$p" "구 WAR (이미지 재현·롤백 필요 여부 확인)"; fi
  done < <(newest_first "${wars[@]}")
fi

say ""
say "------------------------------------------------------------"
say "삭제후보(경로 기준) 합계: $(hr $DEL_BYTES)   보존: $(hr $KEEP_BYTES)   확인필요: $(hr $REV_BYTES)"
say "도커 항목 용량은 위 표의 SIZE 열 참고 (이미지 레이어 공유로 합산 불가)"
say "목록 파일: $OUT"
say "※ 이 스크립트는 삭제/이동을 하지 않음. 지울 항목은 목록을 보고 번호·경로로 지정 → 별도 정리 스크립트로 처리(삭제 대신 휴지통 폴더로 이동 후 확인)."
