package com.disabled.roi;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * ROI JSON 정규화(34번 작업계획서 §5.2, 2026-11-09 장비 파일 형식 정합).
 * 장비 파일의 정본 형식은 점 배열이다:
 *   {"Cam1":{"parking":[[[x,y],..],..],"driveway":[..],"ignore":[..]},"Cam2":{..}}
 * 두 카메라 × 정확히 세 키, 값 없음은 [], 도형은 점 배열만(id·name·null·추가 키 없음), 공백 없는 한 줄, 키 순서 Cam1→Cam2·parking→driveway→ignore.
 * 이 텍스트가 장비에 그대로 저장되는 바이트이며 해시도 이 텍스트의 SHA-256 이다(module_d Normalize 출력과 바이트까지 같아야 한다).
 * 화면(JS)용 ROI 는 도형을 {id,name,points} 객체로 다루고, id 는 웹 전용 부가정보, name 은 rh_meta_json 에 (카메라, 종류, 순번) 기준으로 보관한다.
 */
public final class RoiCodec {
    private static final Logger logger = LoggerFactory.getLogger(RoiCodec.class);
    public static final int NAME_MAX = 40;
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private RoiCodec() {}

    /** 정규화 결과. */
    public static final class Normalized {
        /** ID 가 확정된 ROI(이름 포함). 화면으로 되돌려 주는 값. */
        public final ObjectNode rois;
        /** 장비에 보내는 원문(정본, 점 배열 형식). */
        public final String text;
        public final String hash;
        /** tbl_roi_history.rh_meta_json — 도형 이름 맵(키: "Cam1/parking/0" 형식의 위치). */
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

    /** rh_meta_json 이름 맵의 키: 카메라/종류/순번. */
    static String positionKey(String cam, String kind, int index) {
        return cam + "/" + kind + "/" + index;
    }

    /**
     * 검증을 통과한 입력으로 정규화 결과를 만든다. 알 수 없는 키는 버리고, 새 도형(id 없음/형식 불가)에는 ID 를 발급한다.
     * 같은 ID 가 두 번 나오면 FormatException. 장비로 보내는 text 에는 점 배열만 들어간다(id·name 은 넣지 않는다).
     */
    public static Normalized normalize(JsonNode input) throws RoiValidator.FormatException {
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
                int index = 0;
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

                    canList.add(points.deepCopy()); // 장비 파일에는 점 배열만
                    if (!name.isEmpty()) names.put(positionKey(cam, kind, index), name);
                    index++;
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

    /** 화면용 ROI 의 도형 이름을 rh_meta_json 형식(위치 기준)으로. */
    public static String namesMetaJson(ObjectNode rois) {
        ObjectNode names = MAPPER.createObjectNode();
        for (String cam : RoiValidator.CAMERAS) {
            for (String kind : RoiValidator.KINDS) {
                int index = 0;
                for (JsonNode s : rois.path(cam).path(kind)) {
                    String name = s.path("name").asText("");
                    if (!name.isEmpty()) names.put(positionKey(cam, kind, index), name);
                    index++;
                }
            }
        }
        ObjectNode meta = MAPPER.createObjectNode();
        meta.set("names", names);
        return meta.toString();
    }

    /**
     * 장비(또는 이력)의 원문을 화면용 ROI 로 읽는다. 검증하지 않고 구조만 맞춘다.
     * 읽기는 관대하다: 도형은 점 배열(정본)과 {id,name,points} 객체 둘 다 받고, null 도형은 빈 슬롯으로 제거하며,
     * 없는 카메라·종류는 [] 로 보정하고, 알 수 없는 키(예: 구 키 double)는 무시한다(다음 저장에서 기록되지 않는다. 키 이름만 Info 로그).
     * id 가 없으면 (카메라, 종류, 순번) 기반 안정 ID 를 부여하고, 이름은 meta 의 위치 키(구 데이터는 id 키)로 보충한다.
     * JSON 이 아니거나 최상위가 객체가 아니면 null.
     */
    public static ObjectNode lenientRead(String text, Map<String, String> names) {
        JsonNode root;
        try {
            root = MAPPER.readTree(text);
        } catch (JsonProcessingException | RuntimeException e) {
            return null;
        }
        if (root == null || !root.isObject()) return null;
        ObjectNode out = MAPPER.createObjectNode();
        java.util.List<String> ignored = new java.util.ArrayList<>();
        Iterator<String> top = root.fieldNames();
        while (top.hasNext()) {
            String k = top.next();
            if (!k.equals("Cam1") && !k.equals("Cam2")) ignored.add(k);
        }
        for (String cam : RoiValidator.CAMERAS) {
            ObjectNode outCam = out.putObject(cam);
            JsonNode camNode = root.get(cam);
            if (camNode != null && camNode.isObject()) {
                Iterator<String> keys = camNode.fieldNames();
                while (keys.hasNext()) {
                    String k = keys.next();
                    boolean known = false;
                    for (String kind : RoiValidator.KINDS) if (kind.equals(k)) known = true;
                    if (!known) ignored.add(cam + "." + k);
                }
            }
            for (String kind : RoiValidator.KINDS) {
                ArrayNode list = outCam.putArray(kind);
                JsonNode shapes = camNode == null ? null : camNode.get(kind);
                if (shapes == null || !shapes.isArray()) continue;
                int index = 0;
                for (JsonNode s : shapes) {
                    if (s == null || s.isNull()) continue; // null 도형은 빈 슬롯으로 보고 제거한다
                    if (s.isArray()) {
                        ObjectNode shape = list.addObject();
                        String id = RoiIdGenerator.positionalId(cam, kind, index);
                        shape.put("id", id);
                        shape.put("name", nameFor(names, cam, kind, index, id));
                        shape.set("points", s);
                    } else if (s.isObject()) {
                        ObjectNode shape = list.addObject();
                        String id = s.hasNonNull("id") && s.get("id").isTextual() && !s.get("id").asText().isEmpty()
                                ? s.get("id").asText() : RoiIdGenerator.positionalId(cam, kind, index);
                        String name = s.hasNonNull("name") && s.get("name").isTextual() ? s.get("name").asText() : "";
                        if (name.isEmpty()) name = nameFor(names, cam, kind, index, id);
                        shape.put("id", id);
                        shape.put("name", name);
                        shape.set("points", s.has("points") ? s.get("points") : MAPPER.createArrayNode());
                    } else {
                        list.add(s); // 그대로 두면 이후 검증이 형식 오류로 알려 준다
                    }
                    index++;
                }
            }
        }
        if (!ignored.isEmpty()) {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < ignored.size() && i < 10; i++) {
                if (i > 0) sb.append(',');
                sb.append(ignored.get(i).replaceAll("[^A-Za-z0-9_.]", "?"));
            }
            logger.info("[ROI] 장비 ROI 파일의 알 수 없는 키를 무시했습니다(다음 저장에서 기록되지 않습니다): {}", sb);
        }
        return out;
    }

    private static String nameFor(Map<String, String> names, String cam, String kind, int index, String id) {
        if (names == null) return "";
        String byPosition = names.get(positionKey(cam, kind, index));
        if (byPosition != null) return byPosition;
        String byId = names.get(id);
        return byId == null ? "" : byId;
    }

    /** rh_meta_json 의 names 맵을 읽는다(없거나 깨져 있으면 빈 맵). 키는 위치("Cam1/parking/0") 또는 구 데이터의 도형 id. */
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
