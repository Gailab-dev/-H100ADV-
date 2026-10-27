package com.disabled.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;

@Configuration
// 개발 PC 전용 외부 파일(H100_LOCAL_PROPERTIES, 없으면 무시)이 뒤에 오므로 같은 키는 외부 파일 값이 우선한다.
@PropertySource(value = { "classpath:globals.properties", "${H100_LOCAL_PROPERTIES:file:/dev/null}" },
		encoding = "UTF-8", ignoreResourceNotFound = true)
public class LogConfig {
}
