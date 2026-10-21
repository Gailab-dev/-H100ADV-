package com.disabled.roi;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * ROI JSON 정규화(34번 작업계획서 §5.2 "JSON 원문 확정, SHA-256 계산").
 * 웹이 보낸 도형을 검증한 뒤 ID 를 확정하고, 키 순서·공백이 항상 같은 "원문 텍스트"를 만든다.
 * 이 텍스트가 장비에 그대로 저장되는 바이트이며 해시도 이 텍스트의 SHA-256 이다.
 */
public final class RoiCodec {
    public static final int NAME_MAX = 40;
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private RoiCodec() {}

    /** 정규화 결과. */
    public static final class Normalized {
        /** ID 가 확정된 ROI(이름 포함). 화면으로 되돌려 주는 값. */
        public final ObjectNode rois;
        /** 장비에 보내는 원문(canonical). includeName=false 이면 name 이 빠진다. */
        public final String text;
        public final String hash;
        /** tbl_roi_history.rh_meta_json — 도형 이름 맵. */
        public final String metaJson;

        Normalized(ObjectNode rois, String text, String hash, String metaJson) {
            this.rois = rois;
            this.text = text;
            this.hash = hash;
            this.metaJson = metaJson;
        }
    }

    public static ObjectMapper mapper() {
        return MAPPER;
    }

    public static String sha256Hex(String text) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(text.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(64);
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /** 이름 정리: 제어문자 제거, 공백 다듬기, 최대 NAME_MAX 글자(코드포인트). */
    static String cleanName(JsonNode n) {
        if (n == null || !n.isTextual()) return "";
        String s = n.asText().replaceAll("\\p{Cntrl}", "").trim();
        if (s.codePointCount(0, s.length()) > NAME_MAX) {
            s = s.substring(0, s.offsetByCodePoints(0, NAME_MAX));
        }
        return s;
    }

    /**
     * 검증을 통과한 입력으로 정규화 결과를 만든다. 알 수 없는 키는 버리고, 새 도형(id 없음/형식 불가)에는 ID 를 발급한다.
     * 같은 ID 가 두 번 나오면 FormatException.
     */
    public static Normalized normalize(JsonNode input, boolean includeName) throws RoiValidator.FormatException {
        ObjectNode rois = MAPPER.createObjectNode();
        ObjectNode canonical = MAPPER.createObjectNode();
        ObjectNode names = MAPPER.createObjectNode();
        Set<String> usedIds = new HashSet<>();
        for (String cam : RoiValidator.CAMERAS) {
            ObjectNode roiCam = rois.putObject(cam);
            ObjectNode canCam = canonical.putObject(cam);
            for (String kind : RoiValidator.KINDS) {
                ArrayNode roiList = roiCam.putArray(kind);
                ArrayNode canList = canCam.putArray(kind);
                for (JsonNode s : input.get(cam).get(kind)) {
                    String id = s.hasNonNull("id") ? s.get("id").asText() : null;
                    if (!RoiIdGenerator.isKeepable(id)) id = RoiIdGenerator.newId();
                    if (!usedIds.add(id)) throw new RoiValidator.FormatException("도형 ID 가 중복되었습니다");
                    String name = cleanName(s.get("name"));
                    ArrayNode points = MAPPER.createArrayNode();
                    for (JsonNode p : s.get("points")) points.addArray().add(p.get(0).intValue()).add(p.get(1).intValue());

                    ObjectNode full = roiList.addObject();
                    full.put("id", id);
                    full.put("name", name);
                    full.set("points", points);

                    ObjectNode forDevice = canList.addObject();
                    forDevice.put("id", id);
                    if (includeName) forDevice.put("name", name);
                    forDevice.set("points", points.deepCopy());
                    if (!name.isEmpty()) names.put(id, name);
                }
            }
        }
        try {
            String text = MAPPER.writeValueAsString(canonical);
            ObjectNode meta = MAPPER.createObjectNode();
            meta.set("names", names);
            return new Normalized(rois, text, sha256Hex(text), MAPPER.writeValueAsString(meta));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }

    /**
     * 장비(또는 이력)의 원문을 화면용 ROI 로 읽는다. 검증하지 않고 구조만 맞춘다(없는 카메라·종류는 [], 이름은 namesById 로 보충).
     * JSON 이 아니거나 최상위가 객체가 아니면 null.
     */
    public static ObjectNode lenientRead(String text, Map<String, String> namesById) {
        JsonNode root;
        try {
            root = MAPPER.readTree(text);
        } catch (JsonProcessingException | RuntimeException e) {
            return null;
        }
        if (root == null || !root.isObject()) return null;
        ObjectNode out = MAPPER.createObjectNode();
        for (String cam : RoiValidator.CAMERAS) {
            ObjectNode outCam = out.putObject(cam);
            JsonNode camNode = root.get(cam);
            for (String kind : RoiValidator.KINDS) {
                ArrayNode list = outCam.putArray(kind);
                JsonNode shapes = camNode == null ? null : camNode.get(kind);
                if (shapes == null || !shapes.isArray()) continue;
                for (JsonNode s : shapes) {
                    if (!s.isObject()) {
                        list.add(s); // 그대로 두면 이후 검증이 형식 오류로 알려 준다
                        continue;
                    }
                    ObjectNode shape = list.addObject();
                    String id = s.hasNonNull("id") && s.get("id").isTextual() ? s.get("id").asText() : "";
                    String name = s.hasNonNull("name") && s.get("name").isTextual() ? s.get("name").asText() : "";
                    if (name.isEmpty() && namesById != null && namesById.containsKey(id)) name = namesById.get(id);
                    shape.put("id", id);
                    shape.put("name", name);
                    shape.set("points", s.has("points") ? s.get("points") : MAPPER.createArrayNode());
                }
            }
        }
        return out;
    }

    /** rh_meta_json 의 names 맵을 읽는다(없거나 깨져 있으면 빈 맵). */
    public static Map<String, String> readNames(String metaJson) {
        Map<String, String> out = new HashMap<>();
        if (metaJson == null || metaJson.isEmpty()) return out;
        try {
            JsonNode names = MAPPER.readTree(metaJson).get("names");
            if (names != null && names.isObject()) {
                Iterator<Map.Entry<String, JsonNode>> it = names.fields();
                while (it.hasNext()) {
                    Map.Entry<String, JsonNode> e = it.next();
                    if (e.getValue().isTextual()) out.put(e.getKey(), e.getValue().asText());
                }
            }
        } catch (JsonProcessingException | RuntimeException e) {
            // 부가정보이므로 읽지 못해도 무시한다
        }
        return out;
    }
}
