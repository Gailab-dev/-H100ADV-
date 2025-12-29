#!/bin/bash

TARGET="go-build"
TARGET2="ffmpeg"

# 실행 중인 ffmpeg 프로세스 찾기
PID2=$(pgrep -f "$TARGET2")

if [ -z "$PID2" ]; then
    echo "ffmpeg이 실행 중이지 않습니다."
else
    echo "ffmpeg 종료 중 (PID: $PID2)..."
    kill "$PID2"

    # ffmpeg 프로세스가 정상 종료될 때까지 대기
    for i in {1..5}; do
        sleep 1
        if ! kill -0 "$PID2" 2>/dev/null; then
            echo "서버가 성공적으로 종료되었습니다."
            exit 0
        fi
    done

    # 강제 종료
    echo "정상 종료 실패. SIGKILL 시도."
    kill -9 "$PID2"
    echo "서버가 강제로 종료되었습니다."
fi
# 실행 중인 go 프로세스 찾기
PID=$(pgrep -f "$TARGET")

if [ -z "$PID" ]; then
    echo "서버가 실행 중이지 않습니다."
else
    echo "서버 종료 중 (PID: $PID)..."
    kill "$PID"

    # go프로세스가 정상 종료될 때까지 대기
    for i in {1..5}; do
        sleep 1
        if ! kill -0 "$PID" 2>/dev/null; then
            echo "서버가 성공적으로 종료되었습니다."
            exit 0
        fi
    done

    # 강제 종료
    echo "정상 종료 실패. SIGKILL 시도."
    kill -9 "$PID"
    echo "서버가 강제로 종료되었습니다."
fi
