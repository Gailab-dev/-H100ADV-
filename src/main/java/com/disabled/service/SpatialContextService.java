package com.disabled.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.disabled.mapper.SpatialContextMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class SpatialContextService {
    @Autowired private SpatialContextMapper mapper;
    private final ObjectMapper json = new ObjectMapper();

    public static class Point {
        public Double lat;
        public Double lng;
    }
    public static class Pose extends Point { public Double heading; }
    public static class Update {
        public Integer evId;
        public List<Point> boundary;
        public Pose pose;
    }

    public Map<String, Object> load(int evId) {
        Map<String, Object> row = mapper.getContext(evId);
        if (row == null) throw new IllegalArgumentException("이벤트를 찾을 수 없습니다.");
        Map<String, Object> result = new HashMap<>();
        result.put("evId", evId);
        result.put("boundary", List.of());
        if (row.get("dv_lat") != null && row.get("dv_lng") != null) {
            double lat = number(row.get("dv_lat")), lng = number(row.get("dv_lng"));
            if (validPoint(lat, lng) && (lat != 0 || lng != 0)) result.put("origin", Map.of("lat", lat, "lng", lng));
        }
        if (row.get("boundary_json") != null) {
            try {
                result.put("boundary", json.readValue(row.get("boundary_json").toString(), new TypeReference<List<Point>>() {}));
            } catch (Exception error) { throw new IllegalStateException("주차구역 데이터를 읽을 수 없습니다.", error); }
        }
        if (row.get("vehicle_lat") != null) result.put("pose", Map.of("lat", row.get("vehicle_lat"), "lng", row.get("vehicle_lng"), "heading", row.get("heading")));
        return result;
    }

    @Transactional
    public Map<String, Object> save(Update update, int userId) {
        if (update == null || update.evId == null || update.evId <= 0 || update.boundary == null || update.boundary.size() > 128)
            throw new IllegalArgumentException("경계 좌표를 확인하십시오.");
        Map<String, Object> row = mapper.getContext(update.evId);
        if (row == null) throw new IllegalArgumentException("이벤트를 찾을 수 없습니다.");
        if (row.get("dv_id") == null || row.get("dv_lat") == null || row.get("dv_lng") == null)
            throw new IllegalArgumentException("장비 설치 좌표를 먼저 등록하십시오.");
        double lat = number(row.get("dv_lat")), lng = number(row.get("dv_lng"));
        if (!validPoint(lat, lng) || (lat == 0 && lng == 0)) throw new IllegalArgumentException("장비 설치 좌표를 확인하십시오.");
        List<Point> boundary = new ArrayList<>(update.boundary);
        if (boundary.size() > 1 && equal(boundary.get(0), boundary.get(boundary.size()-1))) boundary.remove(boundary.size()-1);
        if (!boundary.isEmpty() && boundary.size() < 3) throw new IllegalArgumentException("경계는 세 점 이상이어야 합니다.");
        for (Point point : boundary) validateNearby(point, lat, lng);
        if (!boundary.isEmpty()) validatePolygon(boundary, lat, lng);
        if (update.pose != null) {
            validateNearby(update.pose, lat, lng);
            if (update.pose.heading == null || !Double.isFinite(update.pose.heading) || update.pose.heading < 0 || update.pose.heading >= 360)
                throw new IllegalArgumentException("차량 방향은 0도 이상 360도 미만이어야 합니다.");
        }
        Map<String, Object> values = new HashMap<>();
        values.put("deviceId", row.get("dv_id")); values.put("evId", update.evId); values.put("userId", userId);
        try { values.put("boundary", json.writeValueAsString(boundary)); }
        catch (Exception error) { throw new IllegalArgumentException("경계 좌표를 확인하십시오."); }
        if (boundary.isEmpty()) mapper.deleteBoundary(((Number)row.get("dv_id")).intValue()); else mapper.saveBoundary(values);
        if (update.pose == null) mapper.deletePose(update.evId);
        else {
            values.put("lat", update.pose.lat); values.put("lng", update.pose.lng); values.put("heading", update.pose.heading);
            mapper.savePose(values);
        }
        return load(update.evId);
    }

    private double number(Object value) { return ((Number)value).doubleValue(); }
    private boolean validPoint(double lat, double lng) { return Double.isFinite(lat) && Double.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180; }
    private boolean equal(Point a, Point b) { return a != null && b != null && a.lat != null && a.lng != null && a.lat.equals(b.lat) && a.lng.equals(b.lng); }
    private void validateNearby(Point p, double lat, double lng) {
        if (p == null || p.lat == null || p.lng == null || !validPoint(p.lat,p.lng)
            || Math.hypot((p.lat-lat)*111320, (p.lng-lng)*111320*Math.cos(Math.toRadians(lat))) > 5000)
            throw new IllegalArgumentException("설치 위치 반경 5km 이내의 유효한 좌표를 입력하십시오.");
    }
    private double cross(Point a, Point b, Point c) { return (b.lng-a.lng)*(c.lat-a.lat)-(b.lat-a.lat)*(c.lng-a.lng); }
    private void validatePolygon(List<Point> points, double lat, double lng) {
        double area = 0;
        int n = points.size();
        for (int i=0;i<n;i++) {
            Point a=points.get(i), b=points.get((i+1)%n);
            if (equal(a,b)) throw new IllegalArgumentException("중복 경계점을 제거하십시오.");
            Point next=points.get((i+2)%n);
            if (Math.abs(cross(a,b,next)) < 1e-18 && (b.lng-a.lng)*(next.lng-b.lng)+(b.lat-a.lat)*(next.lat-b.lat) < 0)
                throw new IllegalArgumentException("경계선이 겹칩니다.");
            area += (a.lng-lng)*(b.lat-lat)-(b.lng-lng)*(a.lat-lat);
            for (int j=i+1;j<n;j++) {
                if (j==i+1 || (i==0 && j==n-1)) continue;
                Point c=points.get(j), d=points.get((j+1)%n);
                if (Math.max(Math.min(a.lng,b.lng),Math.min(c.lng,d.lng)) <= Math.min(Math.max(a.lng,b.lng),Math.max(c.lng,d.lng))
                    && Math.max(Math.min(a.lat,b.lat),Math.min(c.lat,d.lat)) <= Math.min(Math.max(a.lat,b.lat),Math.max(c.lat,d.lat))
                    && cross(a,b,c)*cross(a,b,d)<=0 && cross(c,d,a)*cross(c,d,b)<=0)
                    throw new IllegalArgumentException("경계선이 서로 교차합니다.");
            }
        }
        if (Math.abs(area)*111320*111320*Math.cos(Math.toRadians(lat)) < 0.1) throw new IllegalArgumentException("면적이 있는 주차구역을 입력하십시오.");
    }
}
