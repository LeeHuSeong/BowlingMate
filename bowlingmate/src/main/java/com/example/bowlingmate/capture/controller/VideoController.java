package com.example.bowlingmate.capture.controller;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@RestController
@RequestMapping("/video")
public class VideoController {

    @GetMapping("/{uid}/{filename:.+}")
    public ResponseEntity<Resource> getVideo(
            @PathVariable String uid,
            @PathVariable String filename) {

        try {
            // Flask에서 저장한 절대 경로에 맞춰 수정
            Path videoPath = Paths.get("/app/shared/comparison/" + uid + "/" + filename);

            if (!Files.exists(videoPath)) {
                System.err.println("Video file not found at: " + videoPath.toAbsolutePath());
                return ResponseEntity.notFound().build();
            }

            Resource resource = new FileSystemResource(videoPath);

            HttpHeaders headers = new HttpHeaders();
            headers.add(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=" + filename);
            headers.add(HttpHeaders.ACCEPT_RANGES, "bytes"); // 시킹(시점 이동) 지원

            return ResponseEntity.ok()
                    .headers(headers)
                    .contentType(MediaTypeFactory.getMediaType(resource)
                            .orElse(MediaType.APPLICATION_OCTET_STREAM))
                    .body(resource);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
