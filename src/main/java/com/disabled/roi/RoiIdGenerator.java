package com.disabled.roi;

import java.nio.charset.StandardCharsets;
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

    /**
     * 장비 파일에서 읽은 도형에 부여하는 ID. 장비 파일(점 배열 형식)에는 ID 가 없으므로 (카메라, 종류, 순번) 으로 정해 같은 파일을 다시 읽어도
     * 같은 ID 가 나오게 한다(임시본 비교·선택 상태가 불필요하게 달라지지 않도록).
     */
    public static String positionalId(String camera, String kind, int index) {
        return UUID.nameUUIDFromBytes(("h100-roi/" + camera + "/" + kind + "/" + index).getBytes(StandardCharsets.UTF_8)).toString();
    }

    /** 클라이언트가 보낸 ID 를 유지해도 되는 형식인지. */
    public static boolean isKeepable(String id) {
        return id != null && ACCEPTED.matcher(id).matches();
    }
}
