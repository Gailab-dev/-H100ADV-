#!/bin/bash

TARGET="go-build"

# 실행 중인 프로세스 중에 정확히 이 명령어가 있는지 확인
if pgrep -f "$TARGET" > /dev/null; then
    echo "Go 서버가 이미 실행 중입니다."
else
    echo "Go 서버가 실행 중이 아닙니다. 실행합니다..."
    nohup go run ./cmd/server > /dev/null 2>&1 &
    echo "서버 실행 완료."
fi
