package com.example.bowlingmate.capture.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyzeResponse {
    @JsonProperty("comparison_video_path")
    private String comparisonVideoPath;
    private DtwResult dtw;
    private LstmResult lstm;
    private String feedback;
    @JsonProperty("pitch_type")
    private String pitchType;
}