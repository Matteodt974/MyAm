FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw -C -B -ntp dependency:go-offline

COPY src ./src
RUN ./mvnw -C -B -ntp clean package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8545

CMD ["sh", "-c", "java -jar app.jar --server.port=${PORT:-8545}"]
