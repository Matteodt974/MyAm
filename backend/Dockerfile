ARG JDK_DIGEST=sha256:da9d3a4f7650db39b918fc5a2c3da76556fb8cc8e5f3767cdea0bb409286951a
ARG JRE_DIGEST=sha256:273396ed5998598ed1091e8d72711c2d36980a0e65103859c55a4e977a41ffd3

FROM eclipse-temurin:21-jdk@${JDK_DIGEST} AS build
WORKDIR /app

COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw -C -B -ntp dependency:go-offline

COPY src ./src
RUN ./mvnw -C -B -ntp clean package -DskipTests

FROM eclipse-temurin:21-jre@${JRE_DIGEST}

LABEL org.opencontainers.image.source="https://github.com/MyAm-org/MyAm"
LABEL org.opencontainers.image.description="MyAm Backend"

RUN useradd --create-home --uid 1001 --shell /sbin/nologin appuser \
    && rm -f /usr/bin/pebble

WORKDIR /app
COPY --from=build --chown=appuser:appuser /app/target/*.jar app.jar

ENV PORT=8545
EXPOSE 8545

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD wget -qO- http://localhost:8545/health || exit 1

CMD ["java", "-jar", "app.jar", "--server.port=${PORT}"]
