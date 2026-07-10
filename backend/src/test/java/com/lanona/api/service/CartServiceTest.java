package com.lanona.api.service;

import com.lanona.api.dto.request.AddCartItemRequest;
import com.lanona.api.entity.CartItem;
import com.lanona.api.entity.MenuCategory;
import com.lanona.api.entity.MenuItem;
import com.lanona.api.entity.MenuItemStatus;
import com.lanona.api.entity.User;
import com.lanona.api.repository.CartItemRepository;
import com.lanona.api.repository.MenuItemRepository;
import com.lanona.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CartServiceTest {

    @Mock
    private CartItemRepository cartItemRepository;
    @Mock
    private MenuItemRepository menuItemRepository;
    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CartService cartService;

    private UUID userId;
    private UUID menuItemId;
    private MenuItem menuItem;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        menuItemId = UUID.randomUUID();
        menuItem = MenuItem.builder()
                .id(menuItemId)
                .name("Pizza")
                .description("desc")
                .price(new BigDecimal("45.00"))
                .category(MenuCategory.builder().id(UUID.randomUUID()).name("Pizza").build())
                .status(MenuItemStatus.DISPONIVEL)
                .build();

        lenient().when(menuItemRepository.findById(menuItemId)).thenReturn(Optional.of(menuItem));
        lenient().when(userRepository.getReferenceById(userId)).thenReturn(User.builder().id(userId).build());
        lenient().when(cartItemRepository.save(any(CartItem.class))).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void addItem_createsNewLine_whenNotYetInCart() {
        when(cartItemRepository.findByUserIdAndMenuItemId(userId, menuItemId)).thenReturn(Optional.empty());
        when(cartItemRepository.findByUserIdOrderByAddedAtDesc(userId)).thenAnswer(invocation -> List.of(
                CartItem.builder().menuItem(menuItem).quantity(2).build()
        ));

        var response = cartService.addItem(userId, new AddCartItemRequest(menuItemId, 2));

        assertThat(response.items()).hasSize(1);
        assertThat(response.items().get(0).quantity()).isEqualTo(2);
        assertThat(response.total()).isEqualByComparingTo("90.00");
    }

    @Test
    void addItem_incrementsExistingLine_insteadOfDuplicating() {
        CartItem existing = CartItem.builder().menuItem(menuItem).quantity(2).build();
        when(cartItemRepository.findByUserIdAndMenuItemId(userId, menuItemId)).thenReturn(Optional.of(existing));
        when(cartItemRepository.findByUserIdOrderByAddedAtDesc(userId)).thenAnswer(invocation -> List.of(existing));

        cartService.addItem(userId, new AddCartItemRequest(menuItemId, 3));

        assertThat(existing.getQuantity()).isEqualTo(5);
    }

    @Test
    void total_reflectsCurrentMenuItemPrice_notASnapshot() {
        CartItem line = CartItem.builder().menuItem(menuItem).quantity(3).build();
        when(cartItemRepository.findByUserIdOrderByAddedAtDesc(userId)).thenReturn(List.of(line));

        var response = cartService.getCart(userId);

        assertThat(response.items().get(0).subtotal()).isEqualByComparingTo("135.00");
        assertThat(response.total()).isEqualByComparingTo("135.00");
    }
}
