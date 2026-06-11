# Build multi-stage : on compile le jar avec le JDK, puis on ne garde que le JRE.
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Copie d'abord le wrapper + pom pour profiter du cache de couches Docker
# (les dependances ne sont retelechargees que si pom.xml change).
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw -B -ntp dependency:go-offline

COPY src ./src
RUN ./mvnw -B -ntp clean package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

# Forme shell pour que ${PORT} soit interprete. Render injecte PORT ; en local -> 8080.
CMD ["sh", "-c", "java -jar app.jar --server.port=${PORT:-8080}"]
