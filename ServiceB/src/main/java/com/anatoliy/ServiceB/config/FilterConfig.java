package com.anatoliy.ServiceB.config;

import com.anatoliy.ServiceB.filter.InternalTokenFilter;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class FilterConfig {

    private final InternalTokenFilter internalTokenFilter;

    @Bean
    public FilterRegistrationBean<@NonNull InternalTokenFilter> internalTokenFilterRegistration() {
        FilterRegistrationBean<@NonNull InternalTokenFilter> registration = new FilterRegistrationBean<>();
        registration.setFilter(internalTokenFilter);
        registration.addUrlPatterns("/api/*");
        registration.setOrder(1);
        return registration;
    }
}