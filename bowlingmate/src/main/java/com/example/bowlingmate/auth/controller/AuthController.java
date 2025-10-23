package com.example.bowlingmate.auth.controller;

import com.example.bowlingmate.auth.dto.*;
import com.example.bowlingmate.auth.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // 회원가입
    @PostMapping("/signup")
    public ResponseEntity<SignupResponse> signup(@RequestBody SignupRequest request) throws Exception {
        SignupResponse response = authService.signup(request);
        return ResponseEntity.ok(response);
    }

    // 로그인
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) throws Exception {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    // JWT로 역할 확인
    @GetMapping("/role")
    public ResponseEntity<RoleResponse> getRole(@RequestHeader("Authorization") String token) {
        // Authorization: Bearer <jwt>
        String jwt = token.replace("Bearer ", "");
        String role = authService.getRoleFromToken(jwt);
        return ResponseEntity.ok(new RoleResponse(role));
    }

    // 비밀번호 재설정 링크 발송
    @PostMapping("/reset-password")
    public ResponseEntity<String> resetPassword(@RequestParam String email) throws Exception {
        String link = authService.resetPassword(email);
        return ResponseEntity.ok(link);
    }

    // 비밀번호 직접 변경 (로그인 상태에서)
    @PutMapping("/update-password/{uid}")
    public ResponseEntity<String> updatePassword(
            @PathVariable String uid,
            @RequestParam String newPassword) throws Exception {
        authService.updatePassword(uid, newPassword);
        return ResponseEntity.ok("비밀번호가 성공적으로 변경되었습니다.");
    }
}