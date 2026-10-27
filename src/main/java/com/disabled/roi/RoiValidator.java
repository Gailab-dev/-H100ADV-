package com.disabled.roi;

import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * ROI 기하 검증(34번 작업계획서 §7). 같은 알고리즘이 웹 JS(roiGeometry.js)·Go(module_d roi/validate.go)에도 있다.
 * 알고리즘을 바꾸면 세 곳을 함께 바꿀 것. 좌표는 1920x1080 원본 기준 정수 픽셀, 원점은 왼쪽 위.
 */
public final class RoiValidator {
    public static final int WIDTH = 1920;
    public static final int HEIGHT = 1080;
    public static final String[] KINDS = {"parking", "driveway", "ignore"};
    public static final String[] CAMERAS = {"Cam1", "Cam2"};

    /** 겹친 영역의 두께가 이 값 이하이면 허용한다. */
    public static final double OVERLAP_TOLERANCE_PX = 2.0;
    private static final double DEPTH_THRESHOLD = OVERLAP_TOLERANCE_PX / 2;
    private static final double EPS = 1e-9;

    private RoiValidator() {}

    /** 검증 실패 한 건. */
    public static final class Problem {
        public final String camera;
        public final String kind;
        public final int index;
        public final String code;

        public Problem(String camera, String kind, int index, String code) {
            this.camera = camera;
            this.kind = kind;
            this.index = index;
            this.code = code;
        }

        @Override
        public String toString() {
            return camera + "/" + kind + "[" + index + "]:" + code;
        }
    }

    /** JSON 구조 자체가 잘못된 경우(문제 목록이 아니라 400 으로 처리). */
    public static final class FormatException extends Exception {
        private static final long serialVersionUID = 1L;

        public FormatException(String message) {
            super(message);
        }
    }

    private static final class Pt {
        final double x, y;

        Pt(double x, double y) {
            this.x = x;
            this.y = y;
        }
    }

    private static double cross(double ax, double ay, double bx, double by, double cx, double cy) {
        return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    }

    private static int sign(double v) {
        return v > 0 ? 1 : (v < 0 ? -1 : 0);
    }

    private static boolean onSegment(Pt a, Pt b, Pt p) {
        return Math.min(a.x, b.x) <= p.x && p.x <= Math.max(a.x, b.x) && Math.min(a.y, b.y) <= p.y && p.y <= Math.max(a.y, b.y);
    }

    private static boolean segmentsIntersect(Pt a, Pt b, Pt c, Pt d) {
        int d1 = sign(cross(a.x, a.y, b.x, b.y, c.x, c.y));
        int d2 = sign(cross(a.x, a.y, b.x, b.y, d.x, d.y));
        int d3 = sign(cross(c.x, c.y, d.x, d.y, a.x, a.y));
        int d4 = sign(cross(c.x, c.y, d.x, d.y, b.x, b.y));
        if (d1 * d2 < 0 && d3 * d4 < 0) return true;
        if (d1 == 0 && onSegment(a, b, c)) return true;
        if (d2 == 0 && onSegment(a, b, d)) return true;
        if (d3 == 0 && onSegment(c, d, a)) return true;
        return d4 == 0 && onSegment(c, d, b);
    }

    private static Pt properCrossing(Pt a, Pt b, Pt c, Pt d) {
        int d1 = sign(cross(a.x, a.y, b.x, b.y, c.x, c.y));
        int d2 = sign(cross(a.x, a.y, b.x, b.y, d.x, d.y));
        int d3 = sign(cross(c.x, c.y, d.x, d.y, a.x, a.y));
        int d4 = sign(cross(c.x, c.y, d.x, d.y, b.x, b.y));
        if (d1 * d2 < 0 && d3 * d4 < 0) {
            double rx = b.x - a.x, ry = b.y - a.y;
            double sx = d.x - c.x, sy = d.y - c.y;
            double denom = rx * sy - ry * sx;
            double t = ((c.x - a.x) * sy - (c.y - a.y) * sx) / denom;
            return new Pt(a.x + t * rx, a.y + t * ry);
        }
        return null;
    }

    private static double pointSegmentDistance(Pt p, Pt a, Pt b) {
        double dx = b.x - a.x, dy = b.y - a.y;
        double len2 = dx * dx + dy * dy;
        if (len2 == 0) return Math.hypot(p.x - a.x, p.y - a.y);
        double t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
        t = Math.max(0, Math.min(1, t));
        return Math.hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy));
    }

    private static double distToBoundary(Pt p, List<Pt> poly) {
        double best = Double.POSITIVE_INFINITY;
        int n = poly.size();
        for (int i = 0; i < n; i++) {
            double d = pointSegmentDistance(p, poly.get(i), poly.get((i + 1) % n));
            if (d < best) best = d;
        }
        return best;
    }

    private static boolean rayInside(Pt p, List<Pt> poly) {
        boolean inside = false;
        int n = poly.size();
        for (int i = 0, j = n - 1; i < n; j = i, i++) {
            double yi = poly.get(i).y, yj = poly.get(j).y;
            if ((yi > p.y) != (yj > p.y)) {
                double x = (poly.get(j).x - poly.get(i).x) * (p.y - yi) / (yj - yi) + poly.get(i).x;
                if (p.x < x) inside = !inside;
            }
        }
        return inside;
    }

    private static boolean strictlyInside(Pt p, List<Pt> poly) {
        return distToBoundary(p, poly) > EPS && rayInside(p, poly);
    }

    private static boolean insideOrOn(Pt p, List<Pt> poly) {
        return distToBoundary(p, poly) <= EPS || rayInside(p, poly);
    }

    private static Pt areaCentroid(List<Pt> poly) {
        double a = 0, cx = 0, cy = 0;
        int n = poly.size();
        for (int i = 0; i < n; i++) {
            Pt p = poly.get(i), q = poly.get((i + 1) % n);
            double f = p.x * q.y - q.x * p.y;
            a += f;
            cx += (p.x + q.x) * f;
            cy += (p.y + q.y) * f;
        }
        if (a == 0) return poly.get(0);
        return new Pt(cx / (3 * a), cy / (3 * a));
    }

    private static List<Pt> toPts(int[][] points) {
        List<Pt> out = new ArrayList<>(points.length);
        for (int[] p : points) out.add(new Pt(p[0], p[1]));
        return out;
    }

    /** 좌표·형태 문제 코드(POINTS_MIN, POINT_FORMAT, OUT_OF_RANGE, DUPLICATE_POINT, SELF_INTERSECTION, ZERO_AREA). 문제 없으면 null. */
    public static String polygonProblem(int[][] points) {
        if (points.length < 3) return "POINTS_MIN";
        int n = points.length;
        for (int[] p : points) {
            if (p.length != 2) return "POINT_FORMAT";
            if (p[0] < 0 || p[0] > WIDTH - 1 || p[1] < 0 || p[1] > HEIGHT - 1) return "OUT_OF_RANGE";
        }
        for (int i = 0; i < n; i++) {
            int[] q = points[(i + 1) % n];
            if (points[i][0] == q[0] && points[i][1] == q[1]) return "DUPLICATE_POINT";
        }
        List<Pt> pts = toPts(points);
        for (int i = 0; i < n; i++) {
            for (int j = i + 1; j < n; j++) {
                boolean adjacent = j == i + 1 || (i == 0 && j == n - 1);
                Pt a1 = pts.get(i), a2 = pts.get((i + 1) % n), b1 = pts.get(j), b2 = pts.get((j + 1) % n);
                if (adjacent) {
                    Pt shared, o1, o2;
                    if (j == i + 1) {
                        shared = a2;
                        o1 = a1;
                        o2 = b2;
                    } else {
                        shared = a1;
                        o1 = a2;
                        o2 = b1;
                    }
                    double cr = cross(shared.x, shared.y, o1.x, o1.y, o2.x, o2.y);
                    double dot = (o1.x - shared.x) * (o2.x - shared.x) + (o1.y - shared.y) * (o2.y - shared.y);
                    if (cr == 0 && dot > 0) return "SELF_INTERSECTION";
                } else if (segmentsIntersect(a1, a2, b1, b2)) {
                    return "SELF_INTERSECTION";
                }
            }
        }
        double area2 = 0;
        for (int i = 0; i < n; i++) {
            Pt a = pts.get(i), b = pts.get((i + 1) % n);
            area2 += a.x * b.y - b.x * a.y;
        }
        if (area2 == 0) return "ZERO_AREA";
        return null;
    }

    /** 두 다각형이 허용 두께(OVERLAP_TOLERANCE_PX)를 넘어 겹치는지 판정한다. 각 다각형은 이미 polygonProblem 을 통과한 것이어야 한다. */
    public static boolean polygonsOverlap(int[][] a, int[][] b) {
        return overlap(toPts(a), toPts(b));
    }

    private static boolean overlap(List<Pt> A, List<Pt> B) {
        List<Pt> q = new ArrayList<>();
        for (Pt v : A) if (insideOrOn(v, B)) q.add(v);
        for (Pt v : B) if (insideOrOn(v, A)) q.add(v);
        int nA = A.size(), nB = B.size();
        for (int i = 0; i < nA; i++) {
            for (int j = 0; j < nB; j++) {
                Pt x = properCrossing(A.get(i), A.get((i + 1) % nA), B.get(j), B.get((j + 1) % nB));
                if (x != null) q.add(x);
            }
        }
        List<Pt> cand = new ArrayList<>();
        cand.add(areaCentroid(A));
        cand.add(areaCentroid(B));
        if (!q.isEmpty()) {
            double mx = 0, my = 0;
            for (Pt p : q) {
                mx += p.x;
                my += p.y;
            }
            cand.add(new Pt(mx / q.size(), my / q.size()));
            for (int i = 0; i < q.size(); i++) {
                for (int j = i + 1; j < q.size(); j++) {
                    cand.add(new Pt((q.get(i).x + q.get(j).x) / 2, (q.get(i).y + q.get(j).y) / 2));
                    if (q.size() <= 12) {
                        for (int k = j + 1; k < q.size(); k++) {
                            cand.add(new Pt((q.get(i).x + q.get(j).x + q.get(k).x) / 3, (q.get(i).y + q.get(j).y + q.get(k).y) / 3));
                        }
                    }
                }
            }
        }
        for (Pt p : cand) {
            if (strictlyInside(p, A) && strictlyInside(p, B)) {
                if (Math.min(distToBoundary(p, A), distToBoundary(p, B)) > DEPTH_THRESHOLD) return true;
            }
        }
        return false;
    }

    /** points JSON(배열의 배열, 각 값은 정수)을 int[][] 로. 정수가 아니면 FormatException. */
    static int[][] readPoints(JsonNode node) throws FormatException {
        if (node == null || node.isNull()) return new int[0][]; // 키가 없으면 점 0개 -> POINTS_MIN (Go 와 동일)
        if (!node.isArray()) throw new FormatException("points 는 배열이어야 합니다");
        int[][] out = new int[node.size()][];
        for (int i = 0; i < node.size(); i++) {
            JsonNode p = node.get(i);
            if (!p.isArray()) throw new FormatException("점은 [x,y] 배열이어야 합니다");
            out[i] = new int[p.size()];
            for (int k = 0; k < p.size(); k++) {
                JsonNode v = p.get(k);
                if (!v.isIntegralNumber() || !v.canConvertToInt()) throw new FormatException("ROI 좌표는 정수여야 합니다");
                out[i][k] = v.intValue();
            }
        }
        return out;
    }

    /**
     * ROI JSON 전체를 검증한다. 카메라·종류 키가 모두 있어야 하고(비어도 []), 알 수 없는 키는 거부하지 않는다.
     * 구조가 잘못되었으면 FormatException, 문제가 있으면 목록(첫 구조 문제 한 건 또는 도형 문제 전부), 없으면 빈 목록.
     */
    public static List<Problem> validate(JsonNode root) throws FormatException {
        List<Problem> problems = new ArrayList<>();
        if (root == null || !root.isObject()) throw new FormatException("ROI JSON 형식 오류");
        for (String cam : CAMERAS) {
            JsonNode c = root.get(cam);
            if (c == null || c.isNull()) {
                problems.add(new Problem(cam, "", 0, "CAMERA_MISSING"));
                return problems;
            }
            if (!c.isObject()) throw new FormatException("ROI JSON 형식 오류");
            for (String kind : KINDS) {
                JsonNode v = c.get(kind);
                if (v == null || v.isNull()) {
                    problems.add(new Problem(cam, kind, 0, "KIND_MISSING"));
                    return problems;
                }
                if (!v.isArray()) throw new FormatException("ROI JSON 형식 오류");
            }
        }
        for (String cam : CAMERAS) problems.addAll(validateCamera(cam, root.get(cam)));
        return problems;
    }

    private static List<Problem> validateCamera(String cam, JsonNode camNode) throws FormatException {
        List<Problem> problems = new ArrayList<>();
        List<String> itemKinds = new ArrayList<>();
        List<Integer> itemIdx = new ArrayList<>();
        List<int[][]> itemPts = new ArrayList<>();
        for (String kind : KINDS) {
            JsonNode shapes = camNode.get(kind);
            for (int idx = 0; idx < shapes.size(); idx++) {
                JsonNode s = shapes.get(idx);
                if (!s.isObject()) throw new FormatException("도형은 객체여야 합니다");
                for (String f : new String[] {"id", "name"}) {
                    JsonNode fv = s.get(f);
                    if (fv != null && !fv.isNull() && !fv.isTextual()) throw new FormatException("ROI JSON 형식 오류");
                }
                int[][] pts = readPoints(s.get("points"));
                String why = polygonProblem(pts);
                if (why != null) {
                    problems.add(new Problem(cam, kind, idx, why));
                    continue;
                }
                itemKinds.add(kind);
                itemIdx.add(idx);
                itemPts.add(pts);
            }
        }
        for (int i = 0; i < itemPts.size(); i++) {
            for (int j = i + 1; j < itemPts.size(); j++) {
                if (polygonsOverlap(itemPts.get(i), itemPts.get(j))) {
                    problems.add(new Problem(cam, itemKinds.get(i), itemIdx.get(i), "OVERLAP"));
                }
            }
        }
        return problems;
    }
}
