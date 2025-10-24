package com.example.bowlingmate.capture.controller;

import com.example.bowlingmate.capture.dto.AnalyzeRequest;
import com.example.bowlingmate.capture.dto.AnalyzeResponse;
import com.example.bowlingmate.capture.service.AnalyzeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/analyze")
@RequiredArgsConstructor
public class AnalyzeController {

    private final AnalyzeService analyzeService;

    @PostMapping
    public ResponseEntity<AnalyzeResponse> analyze(
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
            return ResponseEntity.ok(result);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
