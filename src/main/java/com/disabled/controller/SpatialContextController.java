package com.disabled.controller;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.UUID;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import com.disabled.service.SpatialContextService;

@Controller
@RequestMapping("/eventList/spatialContext")
public class SpatialContextController {
    @Autowired private SpatialContextService service;

    @GetMapping
    @ResponseBody
    public ResponseEntity<?> get(@RequestParam int evId, HttpSession session) {
        if (session.getAttribute("uId") == null) return ResponseEntity.status(401).build();
        try {
            Map<String,Object> result = service.load(evId);
            synchronized (session) {
                if (session.getAttribute("spatialCsrf") == null) session.setAttribute("spatialCsrf", UUID.randomUUID().toString());
                result.put("token", session.getAttribute("spatialCsrf"));
            }
            return ResponseEntity.ok().header("Cache-Control", "no-store").body(result);
        } catch (IllegalArgumentException error) { return failure(404,error.getMessage()); }
    }

    @PostMapping
    @ResponseBody
    public ResponseEntity<?> save(@RequestBody SpatialContextService.Update update, HttpSession session, HttpServletRequest request) {
        if (session.getAttribute("uId") == null) return ResponseEntity.status(401).build();
        String expected=(String)session.getAttribute("spatialCsrf"), supplied=request.getHeader("X-H100-CSRF");
        if (expected==null || supplied==null || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),supplied.getBytes(StandardCharsets.UTF_8))) return failure(403,"요청 인증에 실패했습니다.");
        try {
            return ResponseEntity.ok().header("Cache-Control","no-store").body(service.save(update, Integer.parseInt(session.getAttribute("uId").toString())));
        } catch (IllegalArgumentException error) { return failure(400,error.getMessage()); }
    }
    private ResponseEntity<?> failure(int code,String message) { return ResponseEntity.status(code).body(Map.of("message",message)); }
}
