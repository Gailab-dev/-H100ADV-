package com.disabled.roi;

import java.util.UUID;
import java.util.regex.Pattern;

/**
 * ROI 도형 ID 발급(34번 작업계획서 확정사항 5). 새 도형에만 발급하고, 한 번 발급한 ID 는 수정해도 유지한다.
 * 발급 방식을 바꿀 때 이 클래스만 바꾸면 되도록 별도 모듈로 분리했다.
 */
public final class RoiIdGenerator {
    /** 기존(장비에 이미 있는) ID 도 받아들이기 위해 UUID 형식보다 넓게 허용한다. */
    private static final Pattern ACCEPTED = Pattern.compile("^[A-Za-z0-9_-]{1,64}$");

    private RoiIdGenerator() {}

    public static String newId() {
        return UUID.randomUUID().toString();
    }

    /** 클라이언트가 보낸 ID 를 유지해도 되는 형식인지. */
    public static boolean isKeepable(String id) {
        return id != null && ACCEPTED.matcher(id).matches();
    }
}
