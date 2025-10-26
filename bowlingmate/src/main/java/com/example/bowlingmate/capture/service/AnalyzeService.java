package com.example.bowlingmate.capture.service;

//project 내부 import
import com.example.bowlingmate.capture.dto.AnalyzeRequest;
import com.example.bowlingmate.capture.dto.AnalyzeResponse;
import com.example.bowlingmate.common.json.TimestampSerializer;
import com.example.bowlingmate.common.json.TimestampDeserializer;

//Firestore / Cloud
import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;

//Lombok
import lombok.RequiredArgsConstructor;

//Spring Framework
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;


//Java 표준 라이브러리
import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class AnalyzeService {
    private final Firestore firestore;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${flask.url:http://localhost:5000}")
    private String flaskUrl;

    public AnalyzeService(Firestore firestore) {
        this.firestore = firestore;
    }
    //저장
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

        AnalyzeResponse result = response.getBody();
        if (result != null) {
            result.setCreated_at(Timestamp.now());
            saveAnalyzeResult(result);
        }
        return result;
    }

    //결과 저장
    private void saveAnalyzeResult(AnalyzeResponse result) {
        try {
            if (result.getUid() == null) return;

            DocumentReference docRef = firestore.collection("users")
                    .document(result.getUid())
                    .collection("analysis")
                    .document(); // 자동 생성 ID
                

            //생성된 문서 ID 추출 후, Result에 저장
            String analysisId = docRef.getId();
            result.setAnalysis_id(analysisId);

            Map<String, Object> data = new HashMap<>();
            data.put("analysis_id", analysisId);
            data.put("created_at", result.getCreated_at());
            data.put("pitch_type", result.getPitch_type());
            data.put("range", result.getRange());
            data.put("dtw", result.getDtw());
            data.put("lstm", result.getLstm());
            data.put("feedback", result.getFeedback());
            data.put("comparison_video_path", result.getComparison_video_path());

            docRef.set(data);
            System.out.println("Firestore 저장 완료: " + result.getUid()
                    + " | 시간: " + result.getCreated_at().toDate());

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //전체 결과 조회
    public List<AnalyzeResponse> getAnalyzeResults(String uid) throws ExecutionException, InterruptedException {
        CollectionReference analysisRef = firestore.collection("users")
                .document(uid)
                .collection("analysis");

        ApiFuture<QuerySnapshot> future = analysisRef.orderBy("created_at", Query.Direction.DESCENDING).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<AnalyzeResponse> results = new ArrayList<>();

        for (QueryDocumentSnapshot doc : documents) {
            AnalyzeResponse response = doc.toObject(AnalyzeResponse.class);
            response.setUid(uid); // Firestore에는 uid가 없으므로 세팅
            results.add(response);
        }

        return results;
    }

    //단일 분석 결과 조회
    public AnalyzeResponse getAnalyzeResult(String uid, String analysisId)
        throws ExecutionException, InterruptedException {

        DocumentReference docRef = firestore.collection("users")
                .document(uid)
                .collection("analysis")
                .document(analysisId);

        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            AnalyzeResponse result = document.toObject(AnalyzeResponse.class);
            result.setUid(uid);
            return result;
        } else {
            System.out.println("분석 결과 문서를 찾을 수 없습니다: " + analysisId);
            return null;
        }
    }

    //삭제
    public boolean deleteAnalyzeResult(String uid, String analysisId) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection("users")
                .document(uid)
                .collection("analysis")
                .document(analysisId);

        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot doc = future.get();

        if (doc.exists()) {
            docRef.delete();
            System.out.println("분석 결과 삭제 완료: " + analysisId);
            return true;
        } else {
            System.out.println("해당 문서가 존재하지 않습니다: " + analysisId);
            return false;
        }
    }
}