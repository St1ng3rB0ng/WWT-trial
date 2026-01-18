package com.anatoliy.ServiceB.controller;

import com.anatoliy.ServiceB.dto.TransformRequest;
import com.anatoliy.ServiceB.dto.TransformResponse;
import com.anatoliy.ServiceB.service.TransformService;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class TransformController {

    private final TransformService transformService;

    @PostMapping("/transform")
    public ResponseEntity<@NonNull TransformResponse> transform(@RequestBody TransformRequest request) {
        String result = transformService.transform(request.getText());
        return ResponseEntity.ok(new TransformResponse(result));
    }
}