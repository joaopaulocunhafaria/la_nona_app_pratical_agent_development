package com.lanona.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lanona.api.entity.Role;
import com.lanona.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CartIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    private String token(String email, boolean asAdmin) throws Exception {
        String response = mockMvc.perform(post("/api/auth/register").contentType("application/json")
                        .content("{\"email\":\"%s\",\"password\":\"Senha1234\",\"name\":\"Test\"}".formatted(email)))
                .andReturn().getResponse().getContentAsString();

        if (asAdmin) {
            var user = userRepository.findByEmail(email).orElseThrow();
            user.setRole(Role.ADMIN);
            userRepository.saveAndFlush(user);
            response = mockMvc.perform(post("/api/auth/login").contentType("application/json")
                            .content("{\"email\":\"%s\",\"password\":\"Senha1234\"}".formatted(email)))
                    .andReturn().getResponse().getContentAsString();
        }
        return objectMapper.readTree(response).get("accessToken").asText();
    }

    private String createMenuItem(String adminToken, String name, String price) throws Exception {
        String response = mockMvc.perform(post("/api/menu-items").contentType("application/json")
                        .header("Authorization", "Bearer " + adminToken)
                        .content("""
                                {"name":"%s","description":"desc","price":%s,"category":"Pizza",
                                 "status":"DISPONIVEL","images":[{"base64":"Zm9v","contentType":"image/jpeg"}]}
                                """.formatted(name, price)))
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(response).get("id").asText();
    }

    @Test
    void addUpdateAndClearCart_computesTotalFromCurrentPrice() throws Exception {
        String adminToken = token("cart-admin@lanona.com", true);
        String clienteToken = token("cart-cliente@lanona.com", false);
        String itemId = createMenuItem(adminToken, "Pizza Marguerita", "45.00");

        mockMvc.perform(get("/api/cart").header("Authorization", "Bearer " + clienteToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(0))
                .andExpect(jsonPath("$.total").value(0));

        mockMvc.perform(post("/api/cart/items").contentType("application/json")
                        .header("Authorization", "Bearer " + clienteToken)
                        .content("{\"menuItemId\":\"%s\",\"quantity\":2}".formatted(itemId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(90.00));

        // adicionar de novo incrementa (2 + 1 = 3) em vez de duplicar a linha
        mockMvc.perform(post("/api/cart/items").contentType("application/json")
                        .header("Authorization", "Bearer " + clienteToken)
                        .content("{\"menuItemId\":\"%s\"}".formatted(itemId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].quantity").value(3))
                .andExpect(jsonPath("$.total").value(135.00));

        mockMvc.perform(put("/api/cart/items/" + itemId).contentType("application/json")
                        .header("Authorization", "Bearer " + clienteToken)
                        .content("{\"quantity\":0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(0));

        mockMvc.perform(post("/api/cart/items").contentType("application/json")
                        .header("Authorization", "Bearer " + clienteToken)
                        .content("{\"menuItemId\":\"%s\",\"quantity\":1}".formatted(itemId)))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/api/cart").header("Authorization", "Bearer " + clienteToken))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/cart").header("Authorization", "Bearer " + clienteToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(0));
    }
}
