package com.lanona.api;

import com.amazonaws.services.s3.AmazonS3;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Base para testes de integracao: levanta um Postgres real via Testcontainers
 * (nada de mock de banco) e cada teste roda dentro de uma transacao que e'
 * revertida ao final, isolando os testes entre si sem precisar de dados
 * fixos/unicos por teste.
 *
 * Padrao "singleton container": o campo static e' iniciado manualmente UMA
 * vez (bloco static) e nunca e' parado entre classes de teste - se ficasse
 * com @Testcontainers/@Container, o JUnit pararia e recriaria o container
 * (em outra porta) a cada classe, invalidando o ApplicationContext que o
 * Spring ja' cacheou com a porta antiga.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
public abstract class AbstractIntegrationTest {

    // Sem AWS real nos testes: o cliente S3 e' mockado, entao uploads nao saem
    // pela rede. O S3StorageService monta a URL publica de forma deterministica
    // a partir da config, entao as respostas continuam com URLs validas.
    @MockitoBean
    protected AmazonS3 amazonS3;

    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    static {
        POSTGRES.start();
    }
}
