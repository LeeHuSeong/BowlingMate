package com.example.bowlingmate.capture.dto;

import java.util.List;
import com.google.cloud.Timestamp;
import com.example.bowlingmate.common.json.TimestampSerializer;
import com.example.bowlingmate.common.json.TimestampDeserializer;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyzeResponse {
    private String uid;
    private String analysis_id;

    private String pitch_type;
    private List<Integer> range;
    private DtwResult dtw;
    private LstmResult lstm;

    private String feedback;

    private String comparison_video_path;

    @JsonSerialize(using = TimestampSerializer.class)
    @JsonDeserialize(using = TimestampDeserializer.class)
    private Timestamp created_at;
}