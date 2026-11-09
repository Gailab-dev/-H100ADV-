package roi

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math"
)

// ROI 기하 검증. 같은 알고리즘이 웹 JS(roiGeometry.js)·Java(RoiValidator)에도 있다.
// 알고리즘을 바꾸면 세 곳을 함께 바꿀 것.
// 좌표는 1920x1080 원본 기준 정수 픽셀, 원점은 왼쪽 위.

const (
	frameWidth  = 1920
	frameHeight = 1080
	// 겹침 허용 두께(px): 겹친 영역의 두께가 이 값 이하이면 허용한다.
	overlapTolerancePx = 2.0
	depthThreshold     = overlapTolerancePx / 2
	eps                = 1e-9
)

var (
	kinds   = []string{"parking", "driveway", "ignore"}
	cameras = []string{"Cam1", "Cam2"}
)

type point struct{ x, y float64 }

// Shape 는 ROI 도형 하나. 장비 파일의 정본 형식은 점 배열 [[x,y],...] 이다.
// 입력은 점 배열(정본)과 객체 {id,name,points}(기존 웹 형식) 둘 다 받아들이고(UnmarshalJSON),
// 쓸 때는 항상 점 배열만 낸다(MarshalJSON) — id·name 은 파일에 남기지 않는다.
type Shape struct {
	Points [][]int
	// isNull 은 입력에 null 도형이 있었다는 표시. 파싱 직후 목록에서 제거된다(빈 슬롯).
	isNull bool
}

// UnmarshalJSON 은 점 배열 또는 객체 {id,name,points} 를 읽는다. null 은 isNull 로 표시한다.
// 점 좌표가 정수가 아니면 오류를 돌려준다(상위에서 "ROI 좌표는 정수여야 합니다" 로 거부).
func (s *Shape) UnmarshalJSON(b []byte) error {
	b = bytes.TrimSpace(b)
	switch {
	case len(b) == 0 || string(b) == "null":
		*s = Shape{isNull: true}
		return nil
	case b[0] == '[':
		var pts [][]int
		if err := json.Unmarshal(b, &pts); err != nil {
			return err
		}
		*s = Shape{Points: pts}
		return nil
	case b[0] == '{':
		// 알 수 없는 키(id, name, double 등)는 무시한다.
		var obj struct {
			Points [][]int `json:"points"`
		}
		if err := json.Unmarshal(b, &obj); err != nil {
			return err
		}
		*s = Shape{Points: obj.Points}
		return nil
	}
	return fmt.Errorf("ROI 도형 형식 오류")
}

// MarshalJSON 은 정본 형식(점 배열)으로만 쓴다.
func (s Shape) MarshalJSON() ([]byte, error) {
	if s.Points == nil {
		return []byte("[]"), nil
	}
	return json.Marshal(s.Points)
}

// Camera 는 카메라 하나의 3종류 도형 목록.
type Camera struct {
	Parking  []Shape `json:"parking"`
	Driveway []Shape `json:"driveway"`
	Ignore   []Shape `json:"ignore"`
}

// dropNull 은 null 도형(빈 슬롯)을 제거한다. 남은 도형의 순번이 문제 코드의 index 가 된다.
func dropNull(in []Shape) []Shape {
	out := make([]Shape, 0, len(in))
	for _, s := range in {
		if !s.isNull {
			out = append(out, s)
		}
	}
	return out
}

// normalized 는 null 도형을 제거하고 모든 목록이 nil 이 아니게(→ JSON [] ) 만든다.
func (c Camera) normalized() Camera {
	return Camera{Parking: dropNull(c.Parking), Driveway: dropNull(c.Driveway), Ignore: dropNull(c.Ignore)}
}

// Rois 는 ROI JSON 전체.
type Rois struct {
	Cam1 Camera `json:"Cam1"`
	Cam2 Camera `json:"Cam2"`
}

// Problem 은 검증 실패 한 건.
type Problem struct {
	Camera string
	Kind   string
	Index  int
	Code   string
}

func (p Problem) String() string {
	return fmt.Sprintf("%s/%s[%d]:%s", p.Camera, p.Kind, p.Index, p.Code)
}

func cross(ax, ay, bx, by, cx, cy float64) float64 { return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax) }

func sign(v float64) int {
	switch {
	case v > 0:
		return 1
	case v < 0:
		return -1
	}
	return 0
}

func onSegment(a, b, p point) bool {
	return math.Min(a.x, b.x) <= p.x && p.x <= math.Max(a.x, b.x) && math.Min(a.y, b.y) <= p.y && p.y <= math.Max(a.y, b.y)
}

func segmentsIntersect(a, b, c, d point) bool {
	d1 := sign(cross(a.x, a.y, b.x, b.y, c.x, c.y))
	d2 := sign(cross(a.x, a.y, b.x, b.y, d.x, d.y))
	d3 := sign(cross(c.x, c.y, d.x, d.y, a.x, a.y))
	d4 := sign(cross(c.x, c.y, d.x, d.y, b.x, b.y))
	if d1*d2 < 0 && d3*d4 < 0 {
		return true
	}
	if d1 == 0 && onSegment(a, b, c) {
		return true
	}
	if d2 == 0 && onSegment(a, b, d) {
		return true
	}
	if d3 == 0 && onSegment(c, d, a) {
		return true
	}
	if d4 == 0 && onSegment(c, d, b) {
		return true
	}
	return false
}

func properCrossing(a, b, c, d point) (point, bool) {
	d1 := sign(cross(a.x, a.y, b.x, b.y, c.x, c.y))
	d2 := sign(cross(a.x, a.y, b.x, b.y, d.x, d.y))
	d3 := sign(cross(c.x, c.y, d.x, d.y, a.x, a.y))
	d4 := sign(cross(c.x, c.y, d.x, d.y, b.x, b.y))
	if d1*d2 < 0 && d3*d4 < 0 {
		rx, ry := b.x-a.x, b.y-a.y
		sx, sy := d.x-c.x, d.y-c.y
		denom := rx*sy - ry*sx
		t := ((c.x-a.x)*sy - (c.y-a.y)*sx) / denom
		return point{a.x + t*rx, a.y + t*ry}, true
	}
	return point{}, false
}

func pointSegmentDistance(p, a, b point) float64 {
	dx, dy := b.x-a.x, b.y-a.y
	len2 := dx*dx + dy*dy
	if len2 == 0 {
		return math.Hypot(p.x-a.x, p.y-a.y)
	}
	t := ((p.x-a.x)*dx + (p.y-a.y)*dy) / len2
	t = math.Max(0, math.Min(1, t))
	return math.Hypot(p.x-(a.x+t*dx), p.y-(a.y+t*dy))
}

func distToBoundary(p point, poly []point) float64 {
	best := math.Inf(1)
	n := len(poly)
	for i := 0; i < n; i++ {
		if d := pointSegmentDistance(p, poly[i], poly[(i+1)%n]); d < best {
			best = d
		}
	}
	return best
}

func rayInside(p point, poly []point) bool {
	inside := false
	n := len(poly)
	for i, j := 0, n-1; i < n; j, i = i, i+1 {
		yi, yj := poly[i].y, poly[j].y
		if (yi > p.y) != (yj > p.y) {
			x := (poly[j].x-poly[i].x)*(p.y-yi)/(yj-yi) + poly[i].x
			if p.x < x {
				inside = !inside
			}
		}
	}
	return inside
}

func strictlyInside(p point, poly []point) bool {
	return distToBoundary(p, poly) > eps && rayInside(p, poly)
}
func insideOrOn(p point, poly []point) bool {
	return distToBoundary(p, poly) <= eps || rayInside(p, poly)
}

func areaCentroid(poly []point) point {
	var a, cx, cy float64
	n := len(poly)
	for i := 0; i < n; i++ {
		p, q := poly[i], poly[(i+1)%n]
		f := p.x*q.y - q.x*p.y
		a += f
		cx += (p.x + q.x) * f
		cy += (p.y + q.y) * f
	}
	if a == 0 {
		return poly[0]
	}
	return point{cx / (3 * a), cy / (3 * a)}
}

func toPoints(points [][]int) []point {
	out := make([]point, len(points))
	for i, p := range points {
		out[i] = point{float64(p[0]), float64(p[1])}
	}
	return out
}

// polygonProblem 은 좌표·형태 문제 코드를 돌려준다(문제 없으면 빈 문자열).
func polygonProblem(points [][]int) string {
	if len(points) < 3 {
		return "POINTS_MIN"
	}
	n := len(points)
	for _, p := range points {
		if len(p) != 2 {
			return "POINT_FORMAT"
		}
		if p[0] < 0 || p[0] > frameWidth-1 || p[1] < 0 || p[1] > frameHeight-1 {
			return "OUT_OF_RANGE"
		}
	}
	for i := 0; i < n; i++ {
		q := points[(i+1)%n]
		if points[i][0] == q[0] && points[i][1] == q[1] {
			return "DUPLICATE_POINT"
		}
	}
	pts := toPoints(points)
	for i := 0; i < n; i++ {
		for j := i + 1; j < n; j++ {
			adjacent := j == i+1 || (i == 0 && j == n-1)
			a1, a2, b1, b2 := pts[i], pts[(i+1)%n], pts[j], pts[(j+1)%n]
			if adjacent {
				var shared, o1, o2 point
				if j == i+1 {
					shared, o1, o2 = a2, a1, b2
				} else {
					shared, o1, o2 = a1, a2, b1
				}
				cr := cross(shared.x, shared.y, o1.x, o1.y, o2.x, o2.y)
				dot := (o1.x-shared.x)*(o2.x-shared.x) + (o1.y-shared.y)*(o2.y-shared.y)
				if cr == 0 && dot > 0 {
					return "SELF_INTERSECTION"
				}
			} else if segmentsIntersect(a1, a2, b1, b2) {
				return "SELF_INTERSECTION"
			}
		}
	}
	var area2 float64
	for i := 0; i < n; i++ {
		a, b := pts[i], pts[(i+1)%n]
		area2 += a.x*b.y - b.x*a.y
	}
	if area2 == 0 {
		return "ZERO_AREA"
	}
	return ""
}

// polygonsOverlap 은 두 다각형이 허용 두께를 넘어 겹치는지 판정한다.
func polygonsOverlap(A, B []point) bool {
	var Q []point
	for _, v := range A {
		if insideOrOn(v, B) {
			Q = append(Q, v)
		}
	}
	for _, v := range B {
		if insideOrOn(v, A) {
			Q = append(Q, v)
		}
	}
	nA, nB := len(A), len(B)
	for i := 0; i < nA; i++ {
		for j := 0; j < nB; j++ {
			if x, ok := properCrossing(A[i], A[(i+1)%nA], B[j], B[(j+1)%nB]); ok {
				Q = append(Q, x)
			}
		}
	}
	cand := []point{areaCentroid(A), areaCentroid(B)}
	if len(Q) > 0 {
		var mx, my float64
		for _, q := range Q {
			mx += q.x
			my += q.y
		}
		cand = append(cand, point{mx / float64(len(Q)), my / float64(len(Q))})
		for i := 0; i < len(Q); i++ {
			for j := i + 1; j < len(Q); j++ {
				cand = append(cand, point{(Q[i].x + Q[j].x) / 2, (Q[i].y + Q[j].y) / 2})
				if len(Q) <= 12 {
					for k := j + 1; k < len(Q); k++ {
						cand = append(cand, point{(Q[i].x + Q[j].x + Q[k].x) / 3, (Q[i].y + Q[j].y + Q[k].y) / 3})
					}
				}
			}
		}
	}
	for _, p := range cand {
		if strictlyInside(p, A) && strictlyInside(p, B) {
			if math.Min(distToBoundary(p, A), distToBoundary(p, B)) > depthThreshold {
				return true
			}
		}
	}
	return false
}

func cameraShapes(c Camera) map[string][]Shape {
	return map[string][]Shape{"parking": c.Parking, "driveway": c.Driveway, "ignore": c.Ignore}
}

func validateCamera(name string, c Camera) []Problem {
	var problems []Problem
	type item struct {
		kind  string
		index int
		pts   []point
	}
	var items []item
	shapes := cameraShapes(c)
	for _, kind := range kinds {
		for idx, s := range shapes[kind] {
			if why := polygonProblem(s.Points); why != "" {
				problems = append(problems, Problem{name, kind, idx, why})
				continue
			}
			items = append(items, item{kind, idx, toPoints(s.Points)})
		}
	}
	for i := 0; i < len(items); i++ {
		for j := i + 1; j < len(items); j++ {
			if polygonsOverlap(items[i].pts, items[j].pts) {
				problems = append(problems, Problem{name, items[i].kind, items[i].index, "OVERLAP"})
			}
		}
	}
	return problems
}

// ValidateText 는 ROI JSON 원문을 검증한다. 3종류 키가 모두 있어야 하고(비어도 [] 로), 알 수 없는 키는 거부하지 않는다.
// 도형은 점 배열·객체 두 형식 모두 받는다. 문제가 없으면 nil 을 돌려준다.
func ValidateText(text []byte) ([]Problem, error) {
	_, problems, err := ParseAndValidate(text)
	return problems, err
}

// ParseAndValidate 는 ROI JSON 원문을 검증하고, 문제가 없으면 정본 형식으로 직렬화한 바이트(normalized)를 돌려준다.
// 정본: {"Cam1":{"parking":[..],"driveway":[..],"ignore":[..]},"Cam2":{..}} — 두 카메라 × 정확히 세 키, 값 없음은 [],
// 도형은 점 배열 [[x,y],..] 만(null·id·name·추가 키 없음), 키 순서는 Cam1→Cam2, parking→driveway→ignore.
// null 도형은 빈 슬롯으로 제거한 뒤 검증한다(문제 코드의 index 는 제거 후 순번).
// 카메라·종류 키가 통째로 없거나 null 이면 CAMERA_MISSING/KIND_MISSING 으로 거부한다(요청 누락으로 기존 ROI 를 지우지 않기 위함).
func ParseAndValidate(text []byte) (normalized []byte, problems []Problem, err error) {
	var raw map[string]map[string]json.RawMessage
	if err := json.Unmarshal(text, &raw); err != nil {
		return nil, nil, fmt.Errorf("ROI JSON 형식 오류")
	}
	for _, cam := range cameras {
		c, ok := raw[cam]
		if !ok {
			return nil, []Problem{{Camera: cam, Code: "CAMERA_MISSING"}}, nil
		}
		for _, kind := range kinds {
			v, ok := c[kind]
			if !ok || string(v) == "null" {
				return nil, []Problem{{Camera: cam, Kind: kind, Code: "KIND_MISSING"}}, nil
			}
		}
	}
	var rois Rois
	if err := json.Unmarshal(text, &rois); err != nil {
		return nil, nil, fmt.Errorf("ROI 좌표는 정수여야 합니다")
	}
	rois.Cam1, rois.Cam2 = rois.Cam1.normalized(), rois.Cam2.normalized()
	problems = append(validateCamera("Cam1", rois.Cam1), validateCamera("Cam2", rois.Cam2)...)
	if len(problems) > 0 {
		return nil, problems, nil
	}
	return Normalize(rois), nil, nil
}

// Normalize 는 Rois 를 정본 형식(위 ParseAndValidate 설명)의 JSON 바이트로 직렬화한다.
func Normalize(r Rois) []byte {
	out, err := json.Marshal(struct {
		Cam1 Camera `json:"Cam1"`
		Cam2 Camera `json:"Cam2"`
	}{r.Cam1.normalized(), r.Cam2.normalized()})
	if err != nil { // Shape.MarshalJSON 은 실패하지 않는다
		return []byte(`{"Cam1":{"parking":[],"driveway":[],"ignore":[]},"Cam2":{"parking":[],"driveway":[],"ignore":[]}}`)
	}
	return out
}
