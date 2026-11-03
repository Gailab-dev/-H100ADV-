#!/usr/bin/env bash
# [구 개발서버(192.168.0.15)에서 root 로 실행] 구 서버 운영 설정 사본(스냅샷) 만들기
# 원칙: 원본은 읽기만 한다(복사·조회). 쓰기는 $BASE(/root/h100-snapshots) 아래에만. 서비스 정지/재시작 없음.
# 비밀값은 화면에 출력하지 않는다. 사본 안에는 비밀 파일(server.xml 키스토어 비번, .env, ssl 키 등)이 들어가므로 권한 700/600.
# 사용: sudo ./legacy-snapshot.sh --dry-run     # 무엇을 복사할지 점검만
#       sudo ./legacy-snapshot.sh               # 실제 생성
set -uo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행하세요 (sudo)"; exit 2; }

BASE=${BASE:-/root/h100-snapshots}
CATALINA=${CATALINA:-/usr/share/tomcat9_jdk17/apache-tomcat-9.0.106}
MC=${MC:-/home/dsic/h100_module_c}
MEDIA=${MEDIA:-/home/dsic/Desktop/H100_system}
WAR_NAME=gov-disabled-web-adv
UNITS="tomcat9_jdk17 h100_module_c"
DATE=$(date +%Y%m%d)
SNAP="legacy-dev-0.15-$DATE"
OUT="$BASE/$SNAP"
[ -e "$OUT" ] && OUT="$BASE/$SNAP-$(date +%H%M)" && SNAP=$(basename "$OUT")
TARBALL="$BASE/h100-$SNAP.tar.gz"

N_FAIL=0
ok()   { printf '[PASS] %s\n' "$*"; }
bad()  { printf '[FAIL] %s\n' "$*"; N_FAIL=$((N_FAIL+1)); }
info() { printf '[INFO] %s\n' "$*"; }

# ---- 사전 점검 ----
for p in "$CATALINA/conf/server.xml" "$CATALINA/webapps2/$WAR_NAME.war" "$MC/cmd" "$MC/config"; do
  [ -e "$p" ] && ok "존재: $p" || bad "없음: $p"
done
for u in $UNITS; do [ -f "/etc/systemd/system/$u.service" ] && ok "systemd 유닛: $u" || bad "systemd 유닛 없음: $u"; done
info "크기: module_c(로그·바이너리 제외 전) $(du -sh "$MC" 2>/dev/null | cut -f1), conf $(du -sh "$CATALINA/conf" 2>/dev/null | cut -f1), WAR $(du -sh "$CATALINA/webapps2/$WAR_NAME.war" 2>/dev/null | cut -f1)"
mapfile -t TLSFILES < <(grep -oE '(certificateKeystoreFile|keystoreFile|certificateFile|certificateKeyFile)="[^"]+"' "$CATALINA/conf/server.xml" 2>/dev/null | sed -E 's/^[^=]+="(.*)"$/\1/' | sort -u)
for f in "${TLSFILES[@]}"; do
  case "$f" in /*) fp="$f";; *) fp="$CATALINA/$f";; esac
  [ -f "$fp" ] && ok "Tomcat TLS 파일 발견(복사 대상): $fp" || info "TLS 파일 경로 확인 필요(없음): $fp"
done
info "출력: $OUT  /  $TARBALL"
[ "$N_FAIL" -eq 0 ] || { echo "OVERALL: FAIL (사전 점검)"; exit 1; }
[ "$DRY" -eq 1 ] && { echo "dry-run 끝. 문제 없으면 옵션 없이 다시 실행"; exit 0; }

# ---- 생성 ----
umask 077
mkdir -p "$BASE" && chmod 700 "$BASE"
mkdir -p "$OUT"/{systemd,tomcat/conf,tomcat/webapps2,tomcat/tls,module_c,sysinfo}

# 1) systemd 유닛(+drop-in)
for u in $UNITS; do
  cp -p "/etc/systemd/system/$u.service" "$OUT/systemd/"
  [ -d "/etc/systemd/system/$u.service.d" ] && cp -a "/etc/systemd/system/$u.service.d" "$OUT/systemd/"
done
ok "systemd 유닛 복사"

# 2) Tomcat: conf 전체, setenv.sh, webapps 목록, WAR, TLS 파일
cp -a "$CATALINA/conf/." "$OUT/tomcat/conf/"
[ -f "$CATALINA/bin/setenv.sh" ] && cp -p "$CATALINA/bin/setenv.sh" "$OUT/tomcat/"
cp -p "$CATALINA/webapps2/$WAR_NAME.war" "$OUT/tomcat/webapps2/"
ls -la "$CATALINA/webapps" > "$OUT/tomcat/ls_webapps.txt" 2>&1
ls -la "$CATALINA/webapps2" > "$OUT/tomcat/ls_webapps2.txt" 2>&1
: > "$OUT/tomcat/tls/ORIGIN.txt"
for f in "${TLSFILES[@]}"; do
  case "$f" in /*) fp="$f";; *) fp="$CATALINA/$f";; esac
  if [ -f "$fp" ]; then cp -p "$fp" "$OUT/tomcat/tls/" && echo "$(basename "$fp") <- $fp" >> "$OUT/tomcat/tls/ORIGIN.txt"; fi
done
ok "Tomcat conf·setenv·WAR·TLS 복사"

# 3) 전개 디렉터리 vs WAR 일치 여부(G3 근거). 내용은 출력하지 않고 차이 파일 이름만 기록
TMPD=$(mktemp -d "$BASE/.tmp-war-XXXXXX")
if command -v unzip >/dev/null 2>&1; then unzip -q -o "$CATALINA/webapps2/$WAR_NAME.war" -d "$TMPD" 2>/dev/null
else python3 -I -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$CATALINA/webapps2/$WAR_NAME.war" "$TMPD" 2>/dev/null; fi
diff -rq "$TMPD" "$CATALINA/webapps2/$WAR_NAME" > "$OUT/sysinfo/war_vs_exploded.txt" 2>&1
NDIFF=$(wc -l < "$OUT/sysinfo/war_vs_exploded.txt")
rm -rf "$TMPD"
[ "$NDIFF" -eq 0 ] && ok "WAR 와 전개 디렉터리 동일" || info "WAR 와 전개 디렉터리 차이 ${NDIFF}건 (sysinfo/war_vs_exploded.txt 에 파일명만 기록)"

# 4) module_c 소스·설정 (로그·바이너리 제외; 바이너리는 크기·해시만 기록)
tar -C "$(dirname "$MC")" -cf - --anchored --exclude="$(basename "$MC")/logs" --exclude="$(basename "$MC")/$(basename "$MC")" "$(basename "$MC")" | tar -C "$OUT/module_c" -xf -
[ -f "$MC/$(basename "$MC")" ] && { ls -l "$MC/$(basename "$MC")"; sha256sum "$MC/$(basename "$MC")"; } > "$OUT/sysinfo/module_c_binary.txt"
ls -la "$MC/logs" > "$OUT/sysinfo/module_c_logs_ls.txt" 2>&1
ok "module_c 복사 (logs/·바이너리 제외)"

# 5) 시스템 정보(비밀 없음)
{
  echo "== date/tz =="; date; timedatectl 2>&1 | head -8
  echo "== os =="; uname -a; ( . /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" )
  echo "== java =="; JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 "$CATALINA/bin/version.sh" 2>&1 | grep -E "Server version|JVM Version|JAVA_HOME"
  echo "== go =="; /usr/local/go/bin/go version 2>&1
  echo "== db =="; mysql --version 2>&1
  echo "== units =="; for u in $UNITS mariadb mysql nginx; do printf '%s: enabled=%s active=%s\n' "$u" "$(systemctl is-enabled "$u" 2>&1)" "$(systemctl is-active "$u" 2>&1)"; done
  echo "== listen =="; ss -tlnp 2>&1 | awk 'NR==1 || /:(9443|9444|8089|8189|3307|3306|18080)\b/'
  echo "== packages =="; dpkg -l 2>/dev/null | awk '/^ii/ && $2 ~ /openjdk|mariadb|mysql-server|nginx/ {print $2, $3}'
} > "$OUT/sysinfo/system.txt" 2>&1
{
  for d in output_images output_images_enc output_videos output_videos_enc output_audios; do
    printf '%s\tfiles=%s\tbytes=%s\n' "$d" "$(find "$MEDIA/$d" -type f 2>/dev/null | wc -l)" "$(du -sb "$MEDIA/$d" 2>/dev/null | cut -f1)"
  done
} > "$OUT/sysinfo/media_counts.txt"
ok "시스템 정보·미디어 개수 기록 (미디어 파일 자체는 사본에 넣지 않음)"

# 6) 복구 안내
cat > "$OUT/README.txt" <<TXT
구 개발서버(192.168.0.15) 운영 설정 사본 — $SNAP ($(date '+%F %T'))
태그: legacy-dev-0.15-20261027 (commit 1cabb45) 와 쌍으로 보관. 비밀값 포함 → 외부 반출·git 커밋 금지.
구성: systemd/(유닛) tomcat/(conf 전체, setenv.sh, WAR, TLS 파일, webapps 목록) module_c/(소스·.env·config·ssl, 로그·바이너리 제외) sysinfo/(버전·포트·미디어 개수·WAR 일치 점검)
복구 개요(필요 시): 유닛 → /etc/systemd/system/ ; tomcat/conf → \$CATALINA/conf ; WAR → webapps2/ ; module_c → /home/dsic/ 에 풀고 dsic 소유로 ; systemctl daemon-reload 후 서비스 기동.
무결성: SHA256SUMS.txt(내부 파일) / 사본 옆 *.sha256(압축본)
TXT

# 7) 목록·체크섬·압축
( cd "$OUT" && find . -type f -printf '%m %u:%g %s %TY-%Tm-%Td %TH:%TM %P\n' | sort -k6 > MANIFEST.txt )
( cd "$OUT" && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt )
( cd "$OUT" && sha256sum -c --quiet SHA256SUMS.txt ) && ok "내부 SHA256 검증 ($(wc -l < "$OUT/SHA256SUMS.txt")개 파일)" || bad "내부 SHA256 불일치"
tar -C "$BASE" -czf "$TARBALL" "$SNAP" && ( cd "$BASE" && sha256sum "$(basename "$TARBALL")" > "$(basename "$TARBALL").sha256" )
chmod -R go-rwx "$OUT"; chmod 600 "$TARBALL" "$TARBALL.sha256"
( cd "$BASE" && sha256sum -c --quiet "$(basename "$TARBALL").sha256" ) && ok "압축본 SHA256 검증" || bad "압축본 SHA256 불일치"
tar tzf "$TARBALL" | grep -c . | sed 's/^/[INFO] 압축본 항목 수: /'
ls -l "$TARBALL" "$TARBALL.sha256"
echo "----------------------------------------------"
[ "$N_FAIL" -eq 0 ] && echo "OVERALL: PASS" || echo "OVERALL: FAIL"
