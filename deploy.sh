#!/usr/bin/env bash
set -euo pipefail

# ── [입력 인자: 외부 레포의 커밋 SHA (7자리)] ───────────────────────────────
SHA="${1:-}"
if [[ -z "${SHA}" ]]; then
  echo "❌ 사용법: $0 <BE_SHA>"
  exit 1
fi

# ── [경로/이름 설정] ────────────────────────────────────────────────────────
APP_NAME="catcatChat"
APP_DIR="/home/ubuntu/catcatChat"
RELEASES_DIR="$APP_DIR/releases"

UPLOADED_JAR="$APP_DIR/${APP_NAME}-${SHA}.jar"   # 워크플로우가 업로드한 파일
TARGET_JAR="$RELEASES_DIR/${APP_NAME}-${SHA}.jar" # releases로 이동시킬 최종 위치
CURRENT_LINK="$APP_DIR/${APP_NAME}.jar"           # 항상 이 경로로 실행(심볼릭 링크)

LOG_FILE="$APP_DIR/server.log"
TZ_OPT="-Duser.timezone=Asia/Seoul"

mkdir -p "$RELEASES_DIR"

# ── [업로드된 JAR 확인 및 이동] ─────────────────────────────────────────────
if [[ ! -f "$UPLOADED_JAR" ]]; then
  echo "❌ 업로드된 JAR가 없음: $UPLOADED_JAR"
  exit 1
fi

echo "📦 릴리즈 디렉토리로 이동: $UPLOADED_JAR → $TARGET_JAR"
mv -f "$UPLOADED_JAR" "$TARGET_JAR"

# ── [심볼릭 링크 갱신] ────────────────────────────────────────────────────
echo "🔗 현재 실행 링크 갱신: $CURRENT_LINK → $TARGET_JAR"
ln -sfn "$TARGET_JAR" "$CURRENT_LINK"
echo "ℹ️ 링크 확인: $(ls -l "$CURRENT_LINK")"

# ── [기존 프로세스 종료] ──────────────────────────────────────────────────
echo "🛑 기존 애플리케이션 종료 중..."
# current 링크를 기준으로 잡는 것이 가장 안전
PID=$(pgrep -f "java.*${CURRENT_LINK}" || true)
if [[ -n "${PID}" ]]; then
  echo "→ 실행 중인 PID: ${PID}"
  kill -9 ${PID}
  echo "✅ 프로세스 종료 완료"
else
  echo "ℹ️ 실행 중인 애플리케이션 없음"
fi

# ── [로그 헤더 남기기] ────────────────────────────────────────────────────
{
  echo
  echo "🚀 [$(date '+%Y-%m-%d %H:%M:%S')] 새 버전 배포 및 실행 시작"
  echo "    - SHA: ${SHA}"
  echo "    - Target: ${TARGET_JAR}"
} >> "$LOG_FILE"

# ── [새 프로세스 실행] ────────────────────────────────────────────────────
echo "🚀 새 애플리케이션 실행 중..."
# 로그를 덮어쓰지 않도록 >> 사용(추가 기록)
nohup java $TZ_OPT -jar "$CURRENT_LINK" >> "$LOG_FILE" 2>&1 &

NEW_PID=$!
echo "✅ 새 PID: $NEW_PID"
echo "✅ 시작 커맨드: java $TZ_OPT -jar $CURRENT_LINK"
echo "✅ 실파일: $(readlink -f "$CURRENT_LINK")"
