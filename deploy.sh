#!/bin/bash

APP_NAME="catcatChat"
JAR_PATH="/home/ubuntu/catcatChat"
LOG_FILE="$JAR_PATH/server.log"

echo "🛑 기존 애플리케이션 종료 중..."
PID=$(pgrep -f "java.*$APP_NAME")
if [ -n "$PID" ]; then
  echo "→ 실행 중인 PID: $PID"
  kill -9 $PID
  echo "✅ 프로세스 종료 완료"
else
  echo "ℹ️ 실행 중인 애플리케이션 없음"
fi

echo "🧹 기존 JAR 파일 삭제 중..."
rm -f $JAR_PATH/*.jar.old   # 만약 이전 백업 남기는 용도 있었다면
rm -f $JAR_PATH/*.jar       # 남아있던 예전 JAR 파일 제거

echo "🚀 새 애플리케이션 실행 중..."
nohup java -Duser.timezone=Asia/Seoul -jar $JAR_PATH/catcatChat.jar > $LOG_FILE 2>&1 &

NEW_PID=$!
echo "✅ 새 PID: $NEW_PID"

# 로그에 명시적으로 기록
echo "🚀 [$(date '+%Y-%m-%d %H:%M:%S')] 새 버전 배포 완료 (PID: $NEW_PID)" >> $LOG_FILE
echo "📄 로그: $LOG_FILE"
