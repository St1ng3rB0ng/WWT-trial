package com.anatoliy.ServiceA.service;

import com.anatoliy.ServiceA.dto.ProcessRequest;
import com.anatoliy.ServiceA.dto.ProcessResponse;
import com.anatoliy.ServiceA.dto.TransformRequest;
import com.anatoliy.ServiceA.dto.TransformResponse;
import com.anatoliy.ServiceA.entity.ProcessingLog;
import com.anatoliy.ServiceA.repository.ProcessingLogRepository;
import com.anatoliy.ServiceA.repository.UserRepository;
import com.anatoliy.ServiceA.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProcessService {

    private final ProcessingLogRepository processingLogRepository;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final RestTemplate restTemplate;

    @Value("${service.b.url}")
    private String serviceBUrl;

    @Value("${internal.api.token}")
    private String internalToken;

    @Transactional
    public ProcessResponse process(ProcessRequest request, String token) {
        // Extract user ID from token
        UUID userId = jwtUtil.extractUserId(token.substring(7)); // Remove "Bearer "

        // Verify user exists
        userRepository.findById(userId)
                      .orElseThrow(() -> new RuntimeException("User not found"));

        // Call Service B
        String transformResult = callServiceB(request.getText());

        // Save processing log
        ProcessingLog log = ProcessingLog.builder()
                                         .userId(userId)
                                         .inputText(request.getText())
                                         .outputText(transformResult)
                                         .build();

        processingLogRepository.save(log);

        return new ProcessResponse(transformResult);
    }

    private String callServiceB(String text) {
        String url = serviceBUrl + "/api/transform";

        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Token", internalToken);
        headers.set("Content-Type", "application/json");

        TransformRequest transformRequest = new TransformRequest(text);
        var entity = new HttpEntity<>(transformRequest, headers);

        try {
            var response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    entity,
                    TransformResponse.class
            );

            if (response.getBody() != null) {
                return response.getBody().getResult();
            } else {
                throw new RuntimeException("Empty response from Service B");
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to call Service B: " + e.getMessage(), e);
        }
    }
}