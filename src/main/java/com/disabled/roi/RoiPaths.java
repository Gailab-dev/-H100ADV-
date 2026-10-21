package com.disabled.roi;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.regex.Pattern;

/**
 * ROI 스냅샷 파일 경로 규칙. 임시 스냅샷은 module_c(roi/handlers)가 쓰고 Java 가 읽으며,
 * 기준 스냅샷은 Java 가 임시 파일을 복사해 만든다. 두 프로세스가 같은 미디어 기준 폴더를 공유해야 한다
 * (module_c 의 FILE_UPLOAD_PATH == Java 의 roi.media.base 또는 image.dec.path 의 부모).
 * 파일 경로는 항상 서버가 DB·세션 값으로 결정하고 클라이언트 값은 쓰지 않는다.
 */
public final class RoiPaths {
    private static final Pattern SERIAL = Pattern.compile("^[0-9]{13}$");
    private static final Pattern BASELINE_REL = Pattern.compile("^roi/baseline/[0-9]{13}/[0-9]+/Cam[12]\\.jpg$");

    private RoiPaths() {}

    public static boolean isSerial(String serial) {
        return serial != null && SERIAL.matcher(serial).matches();
    }

    public static boolean isCamera(String cam) {
        return "Cam1".equals(cam) || "Cam2".equals(cam);
    }

    /**
     * 계정명을 폴더명으로 바꾼다. 허용 문자(영문·숫자·_·-) 외에는 %XX(UTF-8 바이트, 대문자 hex)로 인코딩해
     * 경로 이탈(.., /)이 불가능하다. Go(module_c encodeAccount)와 규칙이 같아야 한다.
     */
    public static String encodeAccount(String account) {
        if (account == null || account.isEmpty()) throw new IllegalArgumentException("계정명이 올바르지 않습니다");
        byte[] raw = account.getBytes(StandardCharsets.UTF_8);
        if (raw.length > 64) throw new IllegalArgumentException("계정명이 올바르지 않습니다");
        StringBuilder b = new StringBuilder();
        for (byte v : raw) {
            int c = v & 0xff;
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-') {
                b.append((char) c);
            } else {
                b.append(String.format("%%%02X", c));
            }
        }
        return b.toString();
    }

    /** 임시 스냅샷 상대 경로: roi/snapshot/{계정}/{serial}/CamN.jpg */
    public static String tempRelative(String account, String serial, String cam) {
        requireSerialAndCamera(serial, cam);
        return "roi/snapshot/" + encodeAccount(account) + "/" + serial + "/" + cam + ".jpg";
    }

    /** 기준 스냅샷 상대 경로(DB 에 저장되는 값): roi/baseline/{serial}/{rh_id}/CamN.jpg */
    public static String baselineRelative(String serial, long rhId, String cam) {
        requireSerialAndCamera(serial, cam);
        if (rhId <= 0) throw new IllegalArgumentException("이력 ID 가 올바르지 않습니다");
        return "roi/baseline/" + serial + "/" + rhId + "/" + cam + ".jpg";
    }

    public static boolean isBaselineRelative(String rel) {
        return rel != null && BASELINE_REL.matcher(rel).matches();
    }

    /**
     * base 아래의 상대 경로를 실제 경로로 푼다. 상대 경로가 base 밖으로 나가거나(.., 절대경로) 심볼릭 링크를 따라
     * base 밖을 가리키면 거부한다(IOException). 파일이 없을 수도 있으므로 존재 여부는 확인하지 않는다.
     */
    public static Path resolveUnder(Path base, String relative) throws IOException {
        Path realBase = base.toRealPath();
        Path target = realBase.resolve(relative).normalize();
        if (!target.startsWith(realBase)) throw new IOException("허용되지 않은 경로");
        // 존재하는 가장 깊은 상위를 실제 경로로 확인해 심볼릭 링크 이탈도 막는다.
        Path probe = target;
        while (probe != null && !Files.exists(probe)) probe = probe.getParent();
        if (probe != null && !probe.toRealPath().startsWith(realBase)) throw new IOException("허용되지 않은 경로");
        return target;
    }

    public static Path basePath(String base) {
        return Paths.get(base).toAbsolutePath().normalize();
    }

    private static void requireSerialAndCamera(String serial, String cam) {
        if (!isSerial(serial)) throw new IllegalArgumentException("장비 시리얼이 올바르지 않습니다");
        if (!isCamera(cam)) throw new IllegalArgumentException("카메라 구분이 올바르지 않습니다");
    }
}
