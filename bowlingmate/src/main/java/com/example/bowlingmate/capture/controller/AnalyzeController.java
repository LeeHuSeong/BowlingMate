package com.example.bowlingmate.capture.controller;

import com.example.bowlingmate.capture.dto.AnalyzeRequest;
import com.example.bowlingmate.capture.dto.AnalyzeResponse;
import com.example.bowlingmate.capture.service.AnalyzeService;
import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/analyze")
@RequiredArgsConstructor
public class AnalyzeController {

    private final AnalyzeService analyzeService;

    //POST -> 자세 분석
    @PostMapping
    public ResponseEntity<?> analyze(
            @RequestParam("video") MultipartFile video,
            @RequestParam("uid") String uid,
            @RequestParam("pitchType") String pitchType) {

        try {
            AnalyzeRequest request = AnalyzeRequest.builder()
                    .video(video)
                    .uid(uid)
                    .pitchType(pitchType)
                    .build();

            AnalyzeResponse result = analyzeService.analyzeVideo(request);

             if (result == null) {
                return ResponseEntity.status(502).body("Flask 서버 응답이 없습니다.");
            }

            return ResponseEntity.ok(result);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }


    //GET -> 사용자 전체 분석 결과 조회
    @GetMapping("/{uid}")
    public ResponseEntity<?> getAnalyzeResults(@PathVariable String uid) {
        try {
            List<AnalyzeResponse> results = analyzeService.getAnalyzeResults(uid);
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body("분석 결과 조회 중 오류: " + e.getMessage());
        }
    }

    //GET -> 사용자 단일 분석 결과 조회
    @GetMapping("/{uid}/{analysisId}")
    public ResponseEntity<?> getAnalyzeResult(
            @PathVariable String uid,
            @PathVariable String analysisId) {
        try {
            AnalyzeResponse result = analyzeService.getAnalyzeResult(uid, analysisId);
            if (result == null) {
                return ResponseEntity.status(404).body("해당 분석 결과를 찾을 수 없습니다.");
            }
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body("단일 분석 결과 조회 중 오류: " + e.getMessage());
        }
    }

    
    //DELETE -> 사용자 분석 결과 삭제
    @DeleteMapping("/{uid}/{analysisId}")
    public ResponseEntity<?> deleteAnalyzeResult(
            @PathVariable String uid,
            @PathVariable String analysisId) {
        try {
            boolean deleted = analyzeService.deleteAnalyzeResult(uid, analysisId);
            if (deleted) {
                return ResponseEntity.ok("삭제 완료: " + analysisId);
            } else {
                return ResponseEntity.status(404).body("해당 분석 결과가 존재하지 않습니다.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError()
                    .body("삭제 중 오류: " + e.getMessage());
        }
    }
}
