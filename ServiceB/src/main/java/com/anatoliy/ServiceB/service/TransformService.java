package com.anatoliy.ServiceB.service;

import org.springframework.stereotype.Service;

@Service
public class TransformService {

    public String transform(String text) {
        if (text == null || text.isEmpty()) {
            return "";
        }

        String reversed = new StringBuilder(text).reverse().toString();
        String uppercased = reversed.toUpperCase();

        return uppercased + " [TRANSFORMED]";
    }
}