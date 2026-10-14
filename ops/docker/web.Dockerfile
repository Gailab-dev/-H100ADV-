FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
COPY ops/config/globals.properties ./src/main/resources/globals.properties
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp package -DskipTests

FROM tomcat:9.0-jdk17-temurin AS runtime
RUN rm -rf /usr/local/tomcat/webapps/* && mkdir -p /app/H100_system /app/logs
COPY --from=build /build/target/*.war /usr/local/tomcat/webapps/ROOT.war
COPY ops/docker/start-web.sh /usr/local/bin/start-web.sh
ENV TZ=Asia/Seoul
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=5s --start-period=90s --retries=12 CMD curl -fsS http://localhost:8080/user/login.do > /dev/null || exit 1
CMD ["sh", "/usr/local/bin/start-web.sh"]
