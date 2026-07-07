# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Estagio 1 - build: compila o JAR com Maven (mesma versao do wrapper: 3.9.x)
# ---------------------------------------------------------------------------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Primeiro so o pom.xml para aproveitar o cache de dependencias do Docker:
# enquanto o pom nao mudar, esta camada (download de dependencias) e reutilizada.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Agora o codigo-fonte e o empacotamento (sem testes: o build do deploy nao
# sobe Testcontainers/Postgres).
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---------------------------------------------------------------------------
# Estagio 2 - runtime: imagem enxuta apenas com a JRE + o JAR gerado
# ---------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Usuario nao-root por seguranca.
RUN addgroup -S app && adduser -S app -G app

COPY --from=build /app/target/*.jar app.jar
RUN chown -R app:app /app
USER app

# O Render injeta a variavel PORT (default 10000) e espera que a app escute nela;
# application.yml ja resolve server.port a partir de ${PORT}. EXPOSE e apenas
# documental.
EXPOSE 8080

# JAVA_OPTS permite ajustar memoria/flags via variavel de ambiente no Render
# sem reconstruir a imagem (ex.: -Xmx512m no plano free).
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
