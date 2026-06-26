package com.disabled.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;

@Configuration
@PropertySource(value = "classpath:globals.properties", encoding = "UTF-8")
public class LogConfig {
}
