package com.anatoliy.ServiceA.controller;

import com.anatoliy.ServiceA.dto.ProcessRequest;
import com.anatoliy.ServiceA.dto.ProcessResponse;
import com.anatoliy.ServiceA.service.ProcessService;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ProcessController {

    private final ProcessService processService;

    @PostMapping("/process")
    public ResponseEntity<@NonNull ProcessResponse> process(
            @RequestBody ProcessRequest request,
            @RequestHeader("Authorization") String authHeader
    ) {
        try {
            ProcessResponse response = processService.process(request, authHeader);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(500).build();
        }
    }
}