package com.lanona.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lanona.api.entity.Role;
import com.lanona.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MenuItemIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    private String registerAndGetToken(String email, boolean asAdmin) throws Exception {
        String response = mockMvc.perform(post("/api/auth/register").contentType("application/json")
                        .content("""
                                {"email":"%s","password":"Senha1234","name":"Test"}
                                """.formatted(email)))
                .andReturn().getResponse().getContentAsString();

        if (asAdmin) {
            var user = userRepository.findByEmail(email).orElseThrow();
            user.setRole(Role.ADMIN);
            userRepository.saveAndFlush(user);
            // o token emitido no registro carrega role=cliente; promovendo depois,
            // o teste precisa logar de novo para receber um token com role=admin.
            response = mockMvc.perform(post("/api/auth/login").contentType("application/json")
                            .content("""
                                    {"email":"%s","password":"Senha1234"}
                                    """.formatted(email)))
                    .andReturn().getResponse().getContentAsString();
        }

        return objectMapper.readTree(response).get("accessToken").asText();
    }

    @Test
    void createReadUpdateDeleteAsAdmin_andRejectAsNonAdmin() throws Exception {
        String adminToken = registerAndGetToken("menu-admin@lanona.com", true);
        String clienteToken = registerAndGetToken("menu-cliente@lanona.com", false);

        String createBody = """
                {"name":"X-Burguer","description":"Pao, carne, queijo","price":29.90,
                 "category":"hamburguer","status":"DISPONIVEL",
                 "images":[{"base64":"Zm9v","contentType":"image/jpeg"}]}
                """;

        // requisicao anonima em endpoint admin-only: Spring Security devolve
        // 403 aqui (nao 401) porque o AnonymousAuthenticationToken e' tratado
        // como "autenticado" para fins de authorization, so' falha na checagem
        // de role — mesmo comportamento observado manualmente nos testes da Fase 5.
        mockMvc.perform(post("/api/menu-items").contentType("application/json").content(createBody))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/menu-items").contentType("application/json")
                        .header("Authorization", "Bearer " + clienteToken)
                        .content(createBody))
                .andExpect(status().isForbidden());

        String created = mockMvc.perform(post("/api/menu-items").contentType("application/json")
                        .header("Authorization", "Bearer " + adminToken)
                        .content(createBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.category").value("Hamburguer"))
                .andExpect(jsonPath("$.images.length()").value(1))
                .andReturn().getResponse().getContentAsString();

        String id = objectMapper.readTree(created).get("id").asText();

        mockMvc.perform(get("/api/menu-items"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(id));

        mockMvc.perform(get("/api/menu-items").param("category", "Pizza"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        mockMvc.perform(delete("/api/menu-items/" + id).header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/menu-items/" + id))
                .andExpect(status().isNotFound());
    }

    @Test
    void listCategoriesReturnsDistinctRegisteredCategories() throws Exception {
        String adminToken = registerAndGetToken("menu-categorias@lanona.com", true);

        createItem(adminToken, "X-Burguer", "hamburguer");
        createItem(adminToken, "X-Salada", "hamburguer");
        createItem(adminToken, "Coca-Cola", "bebida");

        // apesar de dois itens de hamburguer, a categoria aparece uma unica vez;
        // apenas as categorias efetivamente cadastradas sao retornadas.
        mockMvc.perform(get("/api/menu-items/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$", containsInAnyOrder("Hamburguer", "Bebida")));
    }

    @Test
    void searchByNameAndCategoryFiltersResults() throws Exception {
        String adminToken = registerAndGetToken("menu-busca@lanona.com", true);

        createItem(adminToken, "Pizza Margherita", "pizza");
        createItem(adminToken, "Pizza Calabresa", "pizza");
        createItem(adminToken, "Suco de Laranja", "bebida");

        mockMvc.perform(get("/api/menu-items").param("q", "margherita"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].name").value("Pizza Margherita"));

        mockMvc.perform(get("/api/menu-items").param("category", "Pizza"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    private void createItem(String adminToken, String name, String category) throws Exception {
        mockMvc.perform(post("/api/menu-items").contentType("application/json")
                        .header("Authorization", "Bearer " + adminToken)
                        .content("""
                                {"name":"%s","description":"teste","price":19.90,
                                 "category":"%s","status":"DISPONIVEL",
                                 "images":[{"base64":"Zm9v","contentType":"image/jpeg"}]}
                                """.formatted(name, category)))
                .andExpect(status().isCreated());
    }

    @Test
    void createStoresImageInBucketAndReturnsUrlNotBase64() throws Exception {
        String adminToken = registerAndGetToken("menu-imagem@lanona.com", true);

        String created = mockMvc.perform(post("/api/menu-items").contentType("application/json")
                        .header("Authorization", "Bearer " + adminToken)
                        .content("""
                                {"name":"X-Foto","description":"teste","price":19.90,
                                 "category":"hamburguer","status":"DISPONIVEL",
                                 "images":[{"base64":"Zm9v","contentType":"image/jpeg"}]}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.images.length()").value(1))
                // a imagem nao volta como base64: o backend subiu para o bucket
                // (S3 mockado) e persistiu apenas a URL publica do objeto.
                .andExpect(jsonPath("$.images[0].url")
                        .value(org.hamcrest.Matchers.startsWith(
                                "https://s3.sa-east-1.amazonaws.com/la-nona-images/menu-items/")))
                .andReturn().getResponse().getContentAsString();

        // confirma que nenhum data URI base64 escapou para a resposta.
        org.assertj.core.api.Assertions.assertThat(created).doesNotContain("data:image");
    }

    @Test
    void createWithoutImagesIsRejected() throws Exception {
        String adminToken = registerAndGetToken("menu-admin-2@lanona.com", true);

        mockMvc.perform(post("/api/menu-items").contentType("application/json")
                        .header("Authorization", "Bearer " + adminToken)
                        .content("""
                                {"name":"Sem imagem","description":"teste","price":10,
                                 "category":"Pizza","status":"DISPONIVEL","images":[]}
                                """))
                .andExpect(status().isBadRequest());
    }
}
