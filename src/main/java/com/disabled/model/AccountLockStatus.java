package com.disabled.model;

// 계정 잠금 상태 코드
public enum AccountLockStatus {
    NO_ACCOUNT,          // 계정 없음
    NOT_LOCKED,          // 잠금 아님
    LOCKED_UNDER_TERM,   // 잠금 상태 + 5분 안 지남
    LOCKED_UNLOCKABLE       // 잠금 상태였지만 5분 지남 (해제 가능)
}

