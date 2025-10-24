package com.example.bowlingmate.capture.service;

import com.example.bowlingmate.capture.dto.AnalyzeRequest;
import com.example.bowlingmate.capture.dto.AnalyzeResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.io.File;
import java.io.IOException;

@Service
public class AnalyzeService {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${flask.url:http://localhost:5000}")
    private String flaskUrl;

    public AnalyzeResponse analyzeVideo(AnalyzeRequest request) throws IOException {
        // Flask 요청 URL
        String url = flaskUrl + "/analyze_pose";

        // MultipartFormData 구성
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();

        // 임시 파일 저장
        File tempFile = File.createTempFile("upload_", ".mp4");
        request.getVideo().transferTo(tempFile);

        body.add("video", new FileSystemResource(tempFile));
        body.add("uid", request.getUid());
        body.add("pitch_type", request.getPitchType());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);

        ResponseEntity<AnalyzeResponse> response =
                restTemplate.exchange(url, HttpMethod.POST, entity, AnalyzeResponse.class);

        tempFile.delete();

        return response.getBody();
    }
}