# La Nona API

Backend Spring Boot que substitui o Firebase (Authentication, Firestore, Storage) usado hoje pelo app Flutter em `../app`.

Plano completo de migração (mapeamento de funcionalidades, modelagem de dados, endpoints, fases de implementação): veja [`SPRINGBOOT.md`](./SPRINGBOOT.md).

## Stack

- Java 17, Spring Boot 3.5.x, Maven
- PostgreSQL + Flyway (migrations versionadas, sem `ddl-auto: update`)
- Spring Security + JWT (access + refresh token) e validação de login Google
- WebSocket/STOMP para o chat de suporte em tempo real
- springdoc-openapi (Swagger UI)

## Pré-requisitos

- JDK 17+
- Docker (para o Postgres local)

## Subindo o ambiente de desenvolvimento

```bash
# 1. Banco de dados local
docker compose up -d

# 2. Aplicação (perfil dev por padrão)
./mvnw spring-boot:run
```

A aplicação sobe em `http://localhost:8080`. As migrations Flyway em `src/main/resources/db/migration` são aplicadas automaticamente no startup, isoladas no schema `la_nona_api` (o Postgres é compartilhado com outros projetos). Documentação interativa da API em `http://localhost:8080/swagger-ui.html`.

## Variáveis de ambiente

| Variável | Padrão (dev) | Descrição |
|---|---|---|
| `DB_URL` | `jdbc:postgresql://localhost:5432/la_nona` | URL JDBC do Postgres |
| `DB_USERNAME` / `DB_PASSWORD` | `icismep` / `icismep` | Credenciais do banco |
| `JWT_SECRET` | valor de desenvolvimento embutido | **Trocar em produção** |
| `JWT_ACCESS_EXPIRATION_MS` | `3600000` (1h) | Validade do access token |
| `JWT_REFRESH_EXPIRATION_MS` | `2592000000` (30 dias) | Validade do refresh token |
| `GOOGLE_CLIENT_ID` | vazio | Client ID OAuth usado para validar o `idToken` do login Google |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:*` | Origens permitidas |

## Estrutura de pacotes

```
src/main/java/com/lanona/api/
├── config/        configurações de infraestrutura (Security, WebSocket, CORS)
├── controller/     controllers REST (só DTOs, nunca entidades)
├── websocket/      handlers STOMP do chat em tempo real
├── service/        regras de negócio
├── repository/     interfaces Spring Data JPA
├── entity/          entidades JPA
├── dto/request/     corpo de requisição dos endpoints
├── dto/response/    corpo de resposta dos endpoints
├── security/        JWT, filtro de autenticação
└── exception/       exceções de negócio + @ControllerAdvice global
```

## Testes

```bash
./mvnw test      # unitarios (services, validacao) + integracao (Testcontainers, Postgres real)
./mvnw verify    # idem + empacotamento
```

Os testes de integração sobem um Postgres descartável via Testcontainers (precisa de Docker disponível) — não usam o Postgres de desenvolvimento configurado acima.

## Promovendo o primeiro usuário admin

Não há seed com senha de admin hardcoded. Para promover um usuário (depois de ele se registrar normalmente via `POST /api/auth/register`):

```sql
SET search_path TO la_nona_api;
UPDATE users SET role = 'admin' WHERE email = 'seu-email@exemplo.com';
```

O usuário precisa logar de novo (`POST /api/auth/login`) depois da promoção, para receber um token com a role atualizada — o token antigo, emitido antes da promoção, continua com `role: cliente` até expirar.

## Estado atual

Implementação completa: schema (Flyway), autenticação (JWT + login Google), perfil/admin de usuários, cardápio (CRUD + imagens em base64), carrinho, favoritos e chat de suporte (REST + WebSocket/STOMP), com testes unitários e de integração passando. Ver a seção 11 de [`SPRINGBOOT.md`](./SPRINGBOOT.md) para decisões e ajustes feitos durante a implementação que não estavam previstos no plano original.

Próximo passo (fora deste módulo): trocar os `services` Dart do app Flutter para consumir esta API em vez do Firebase (ver seção 9 de `SPRINGBOOT.md`).
