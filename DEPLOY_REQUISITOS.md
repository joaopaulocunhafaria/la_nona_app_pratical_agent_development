# Requisitos para colocar o La Nona em produção

> **Como usar este documento:** ele descreve a aplicação e os requisitos mínimos
> de hospedagem. Cole-o em uma ferramenta de IA (ChatGPT, Gemini, etc.) e peça
> recomendações de provedores/planos atuais do mercado. No fim há uma seção
> **"Perguntas para a IA"** já pronta com o que pedir.

---

## 1. Objetivo

Colocar em produção, para **usuários externos reais**, apenas:

- a **versão web** (frontend Angular);
- o **backend** (API Spring Boot);
- o **banco de dados** (PostgreSQL).

O app mobile (Flutter) **não** será hospedado — ele apenas consome a mesma API.

### Perfil de uso esperado (importante para dimensionar custo)

- Fluxo de usuários **muito reduzido** (early stage / poucos clientes).
- **Baixíssimas requisições por minuto** (dezenas por dia, picos pequenos).
- **Prioridade absoluta: menor custo / melhor custo-benefício.** Latência,
  alta disponibilidade e escala horizontal **não** são prioridade nesta fase.
- Aceita-se "cold start" / instância que hiberna quando ociosa, desde que
  funcione para o usuário final.

---

## 2. Arquitetura (3 componentes)

```
[ Navegador do usuário ]
          |
          v  HTTPS
[ Frontend Web - Angular SPA (arquivos estáticos) ]
          |
          v  HTTPS (REST + WebSocket)
[ Backend - Spring Boot (JAR Java) ]
          |
          v  TCP 5432
[ Banco de Dados - PostgreSQL ]
```

Os três podem estar no mesmo provedor ou em provedores diferentes.

---

## 3. Componente 1 — Frontend Web (Angular)

- **Tipo:** Single Page Application **estática** (HTML/CSS/JS já compilados).
- **Stack:** Angular 19.
- **Build:** `npm install && npm run build` → gera a pasta `web/dist/la-nona-web`.
- **Tamanho do build:** ~14 MB de arquivos estáticos.
- **Requisito de hospedagem:** qualquer serviço de **static hosting / CDN**.
  Não precisa de servidor de aplicação nem de Node.js em runtime.
- **Necessário:**
  - servir `index.html` como fallback para todas as rotas (SPA / rewrite para
    `index.html`) — senão o refresh em rotas internas dá 404;
  - **HTTPS** com domínio próprio ou subdomínio;
  - configurar a URL da API de produção no build do Angular (variável de
    ambiente do app).

---

## 4. Componente 2 — Backend (Spring Boot)

- **Stack:** Spring Boot 3.5.15, **Java 17**, empacotado como **JAR executável**
  (`./mvnw clean package` → `backend/target/api-0.0.1-SNAPSHOT.jar`).
- **Execução:** `java -jar api.jar` (porta padrão 8080, configurável via
  `SERVER_PORT`).
- **Ainda NÃO existe Dockerfile** — será preciso criar um (ou usar buildpacks /
  deploy nativo de JAR que o provedor oferecer). O provedor escolhido precisa
  suportar **uma destas opções**: Docker, buildpacks (Java), ou deploy de JAR.

### Recursos mínimos do backend

- **Memória RAM:** mínimo **512 MB**, recomendado **1 GB** (JVM Spring Boot).
  Com 256 MB tende a falhar/ficar instável.
- **CPU:** 1 vCPU compartilhada é suficiente para este volume.
- **Disco:** mínimo (~300 MB para o JAR + JRE). Não grava arquivos em disco.
- **Porta exposta:** HTTP na porta da aplicação, atrás de **HTTPS/TLS**
  (terminação TLS pode ser feita pelo provedor / reverse proxy).

### Restrição arquitetural importante — INSTÂNCIA ÚNICA

- O chat usa **WebSocket com broker STOMP em memória**
  (`enableSimpleBroker`, dentro do próprio processo).
- Consequência: **não dá para rodar 2+ instâncias do backend** sem um broker
  externo (Redis/RabbitMQ). Para esta fase, planejar **1 instância apenas**.
- Se o provedor usar autoescala/múltiplas réplicas, é preciso **fixar em 1
  réplica** (ou habilitar sticky sessions). Mais simples: 1 instância.
- O servidor de hospedagem **precisa suportar conexões WebSocket** (long-lived
  HTTP / SockJS). Confirmar isso no provedor — nem todo PaaS barato suporta bem.

### Variáveis de ambiente obrigatórias em produção

| Variável | Descrição |
|---|---|
| `SPRING_PROFILES_ACTIVE` | Definir como `prod`. |
| `DB_URL` | JDBC do Postgres, ex.: `jdbc:postgresql://HOST:5432/la_nona`. |
| `DB_USERNAME` | Usuário do banco. |
| `DB_PASSWORD` | Senha do banco (segredo). |
| `DB_SCHEMA` | Schema da aplicação (padrão `la_nona_api`). |
| `JWT_SECRET` | **Segredo forte e único** para assinar tokens JWT. Trocar o valor de desenvolvimento. |
| `GOOGLE_CLIENT_ID` | Client ID do OAuth Google (login com Google). |
| `CORS_ALLOWED_ORIGINS` | Domínio do frontend em produção, ex.: `https://app.meudominio.com`. |
| `SERVER_PORT` | Porta HTTP (muitos PaaS injetam via `PORT`). |
| `AWS_ACCESS_KEY` | Access Key da credencial IAM com acesso ao bucket (segredo). Em EC2/ECS/EKS pode ficar **vazio** e usar IAM Role. |
| `AWS_SECRET_KEY` | Secret Key da credencial IAM (segredo). Idem acima. |
| `AWS_REGION` | Região do bucket, ex.: `sa-east-1`. |
| `AWS_S3_URL` | Endpoint base para montar a URL pública, ex.: `https://s3.sa-east-1.amazonaws.com`. |
| `AWS_S3_BUCKET` | Nome do bucket onde as imagens são gravadas. |

> O provedor precisa permitir **definir variáveis de ambiente / secrets**.
>
> **Imagens vão para um bucket (S3), não para o banco.** O código já está
> pronto: basta criar o bucket e preencher as 5 variáveis `AWS_*` acima — nada
> mais precisa mudar. Permissões IAM mínimas no bucket: `s3:PutObject`,
> `s3:GetObject`, `s3:DeleteObject`, `s3:PutObjectAcl`. As imagens são gravadas
> com ACL pública de leitura (a URL devolvida pela API é acessada direto pelos
> clientes).

---

## 5. Componente 3 — Banco de Dados (PostgreSQL)

- **Versão:** PostgreSQL **16** (testado com 16-alpine; 15+ deve funcionar).
- **Schema gerenciado por Flyway:** as migrations rodam automaticamente no
  start do backend. Não é preciso criar tabelas manualmente — só um banco vazio
  e um usuário com permissão de criar schema/tabelas.
- **Extensão necessária:** `gen_random_uuid()` (módulo `pgcrypto` / disponível
  nativamente no Postgres 13+). Confirmar que o provedor permite.
- **Persistência:** precisa de **armazenamento durável** (os dados não podem ser
  perdidos no restart). Nada de banco efêmero.

### Tamanho / crescimento do banco

- As **imagens vão para um bucket de object storage (Amazon S3)**; o banco
  guarda **apenas a URL** de cada imagem. O banco, portanto, **não incha** com
  o conteúdo das fotos.
- **Estimativa inicial:** começar com **1 GB** de storage e poucas conexões
  (5–10) é mais que suficiente para os dados de texto/metadados.
- O dimensionamento do **bucket** é à parte (ver Componente 4) e cresce
  conforme o número/tamanho das imagens.

### Requisitos do plano de banco

- Armazenamento durável (mínimo ~1 GB, com possibilidade de aumentar).
- Conexões: 5–10 simultâneas bastam.
- **Backups automáticos** desejáveis (mesmo que diários), mas não obrigatórios
  nesta fase de custo mínimo.
- Acesso via TCP/SSL a partir do backend.

### Componente 4 (novo) — Object Storage para imagens (Amazon S3)

- As imagens de cardápio e fotos de perfil são enviadas pelo backend para um
  **bucket S3** e o banco guarda só a URL pública.
- **Requisito:** um bucket S3 (ou compatível com a API S3) com leitura pública
  dos objetos e uma credencial IAM com `Put/Get/Delete Object` + `PutObjectAcl`.
- **Configuração:** preencher as variáveis `AWS_*` da seção 4. O código já está
  pronto — **só falta apontar para o bucket real**.
- **Custo:** para poucas imagens o custo de storage/transferência é baixíssimo;
  a maioria dos provedores tem free tier inicial. Alternativas compatíveis com a
  API S3 (ex.: Cloudflare R2, Backblaze B2) também funcionam ajustando
  `AWS_S3_URL`/`AWS_REGION`.

---

## 6. Requisitos transversais

- **HTTPS/TLS obrigatório** no frontend e no backend (login Google e JWT exigem
  conexão segura). Certificado gerenciado pelo provedor é o ideal (Let's Encrypt
  automático).
- **Domínio próprio** (ou subdomínios), ex.: `app.meudominio.com` para o web e
  `api.meudominio.com` para a API. Pode-se usar os domínios gratuitos do
  provedor no início.
- **CORS:** o backend só aceitará requisições do domínio configurado em
  `CORS_ALLOWED_ORIGINS`.
- **Login com Google (OAuth):** será preciso cadastrar os domínios de produção
  (origens autorizadas) no Google Cloud Console.
- **CI/CD:** desejado para atualizações rápidas e dinâmicas — detalhado na
  seção 7.

---

## 7. CI/CD — atualizações rápidas e automáticas

Objetivo: ao dar `git push`, os apps subirem sozinhos para produção, sem deploy
manual. O código já está no **GitHub**
(`joaopaulocunhafaria/la_nona_app_pratical_agent_development`), então a opção
mais natural e de menor atrito é o **GitHub Actions** (gratuito para repositório
nesse volume: 2.000 min/mês em repo privado, ilimitado em repo público).

### O que o pipeline precisa fazer

| Componente | Etapas do pipeline |
|---|---|
| **Frontend Web** | `npm ci` → `npm run build` → publicar `web/dist/la-nona-web` no static host/CDN |
| **Backend** | `./mvnw clean package` (Java 17) → build da imagem Docker (ou JAR) → deploy na plataforma |
| **Banco** | nada no CI: as migrations Flyway rodam sozinhas no start do backend |

### Requisitos para o CI/CD funcionar

- **Repositório no GitHub** (já existe).
- **Plataforma de deploy com integração Git ou CLI/API** para o Actions chamar.
  Quase todo PaaS moderno oferece um destes:
  - **Deploy automático por Git** (a plataforma observa o branch e faz build/deploy
    sozinha — ex.: Render, Railway, Vercel/Netlify para o web). É o mais simples:
    quase não precisa escrever pipeline.
  - **Deploy via GitHub Actions** usando token/secret da plataforma (mais
    controle; serve para AWS, Fly.io, etc.).
- **Secrets no GitHub Actions** (Settings → Secrets) para guardar credenciais de
  deploy e variáveis sensíveis (`JWT_SECRET`, `DB_*`, tokens da plataforma).
  Nunca commitar segredos no repositório.
- **Estratégia de branch:** push em `main` → deploy em produção. (Opcional: um
  branch/ambiente de homologação — o web já tem build `build-homolog`.)
- **Pré-requisito recomendado:** criar um **Dockerfile** para o backend (ainda
  não existe), pois a maioria das plataformas faz deploy a partir dele.

### Recomendação para custo mínimo

- **Mais simples (quase sem pipeline):** usar o **auto-deploy nativo por Git** da
  própria plataforma de hospedagem (Render/Railway/Vercel/Netlify conectam ao
  GitHub e fazem build a cada push). Bom para começar rápido.
- **Mais portável:** **GitHub Actions** disparando o deploy — não prende você a
  um provedor e funciona igual se trocar de host depois.

---

## 8. Resumo dos requisitos mínimos

| Componente | Requisito mínimo | Observação |
|---|---|---|
| Frontend Web | Static hosting + CDN + HTTPS | SPA Angular, ~14 MB, rewrite p/ `index.html` |
| Backend | 512 MB–1 GB RAM, 1 vCPU, Java 17, HTTPS, **WebSocket**, **1 instância** | Docker/buildpack/JAR; suportar env vars |
| Banco | PostgreSQL 16, ~1 GB storage durável, `pgcrypto` | Flyway cria o schema; guarda só URLs (imagens vão p/ bucket) |
| Object storage | Bucket S3 (ou compatível) com leitura pública | Imagens do cardápio/perfil; só preencher as variáveis `AWS_*` |
| Rede | Domínio + TLS gerenciado | CORS restrito ao domínio do web |
| CI/CD | GitHub Actions ou auto-deploy por Git | push em `main` → build e deploy automático |

---

## 9. Perguntas para a IA externa

> Cole tudo acima e depois faça estes pedidos:

1. Considerando **custo mínimo** e o perfil de tráfego muito baixo descrito
   acima, **quais provedores e planos atuais** você recomenda para hospedar
   cada um dos 3 componentes (web estático, backend Spring Boot com WebSocket,
   PostgreSQL gerenciado)?
2. Compare ao menos **3 combinações** de provedores, com **estimativa de custo
   mensal em BRL e USD**, incluindo opção com **tier gratuito** se existir.
3. Indique qual combinação tem o **melhor custo-benefício** para começar e como
   ela **escala depois** se o tráfego crescer.
4. Aponte **limitações** de cada opção barata para o meu caso específico,
   principalmente: suporte a **WebSocket**, hibernação/cold start, limites de
   horas/RAM no tier free, e crescimento do banco (imagens base64).
5. Diga se vale a pena **juntar backend + banco no mesmo provedor** ou separar,
   e por quê, no critério custo.
6. Liste o **passo a passo de deploy** para a combinação recomendada (incluindo
   se preciso criar Dockerfile para o backend).
7. Recomende a forma mais simples e barata de **CI/CD** (atualização automática a
   cada `git push` no GitHub) para a combinação escolhida: vale usar o
   **auto-deploy nativo por Git** da plataforma ou montar um pipeline no
   **GitHub Actions**? Mostre um exemplo de workflow para o frontend e para o
   backend.
