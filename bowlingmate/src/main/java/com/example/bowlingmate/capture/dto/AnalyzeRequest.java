package com.example.bowlingmate.capture.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyzeRequest {
    private MultipartFile video;
    private String uid;
    private String pitchType;
}
