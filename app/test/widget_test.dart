// Testes de unidade da camada de dados da migração para a API La Nona.
//
// Validam o parsing dos modelos a partir do JSON dos DTOs do backend e os
// utilitários de imagem (data URI vs URL). Não dependem de rede.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:la_nona/data/api/app_image.dart';
import 'package:la_nona/data/models/chat_message.dart';
import 'package:la_nona/data/models/menu_item.dart';
import 'package:la_nona/models/user_profile.dart';
import 'package:la_nona/services/cart_service.dart';

void main() {
  group('UserProfile.fromJson (UserResponse)', () {
    test('mapeia campos e deriva isAdmin a partir de role', () {
      final user = UserProfile.fromJson({
        'id': 'u-1',
        'email': 'maria@example.com',
        'name': 'Maria',
        'photo': 'https://x/p.png',
        'provider': 'google',
        'role': 'admin',
        'isAdmin': true,
        'onboardingCompleted': true,
        'address': {
          'cep': '01001-000',
          'rua': 'Praça da Sé',
          'bairro': 'Sé',
          'numero': '10',
          'cidade': 'São Paulo',
          'estado': 'SP',
          'complemento': '',
        },
      });

      expect(user.uid, 'u-1');
      expect(user.photoUrl, 'https://x/p.png');
      expect(user.isAdmin, isTrue);
      expect(user.hasAddress, isTrue);
      expect(user.address.cidade, 'São Paulo');
    });

    test('trata campos nulos com defaults seguros', () {
      final user = UserProfile.fromJson({'id': 'u-2', 'email': 'a@b.c'});
      expect(user.name, '');
      expect(user.photoUrl, '');
      expect(user.role, 'cliente');
      expect(user.isAdmin, isFalse);
      expect(user.address.isComplete, isFalse);
    });
  });

  group('MenuItem.fromJson (MenuItemResponse)', () {
    test('ordena imagens por position e expõe imageUrls', () {
      final item = MenuItem.fromJson({
        'id': 'm-1',
        'name': 'Pizza',
        'description': 'Margherita',
        'price': 49.9,
        'category': 'Pizza',
        'available': true,
        'images': [
          {'id': 'i2', 'data': 'data:image/png;base64,BBBB', 'position': 1},
          {'id': 'i1', 'data': 'https://x/1.png', 'position': 0},
        ],
      });

      expect(item.price, 49.9);
      expect(item.images.first.id, 'i1');
      expect(item.imageUrls, ['https://x/1.png', 'data:image/png;base64,BBBB']);
    });
  });

  group('CartItem.fromJson (CartItemResponse)', () {
    test('lê subtotal e menuItem aninhado', () {
      final cartItem = CartItem.fromJson({
        'id': 'c-1',
        'quantity': 2,
        'subtotal': 99.8,
        'menuItem': {
          'id': 'm-1',
          'name': 'Pizza',
          'description': 'x',
          'price': 49.9,
          'category': 'Pizza',
          'available': true,
          'images': [],
        },
      });

      expect(cartItem.quantity, 2);
      expect(cartItem.subtotal, 99.8);
      expect(cartItem.menuItem.id, 'm-1');
    });
  });

  group('ChatMessage.fromJson (ChatMessageResponse)', () {
    test('parseia sentAt ISO-8601', () {
      final message = ChatMessage.fromJson({
        'id': 'msg-1',
        'senderId': 'u-1',
        'text': 'Olá',
        'isAdmin': true,
        'sentAt': '2026-06-20T12:00:00Z',
      });
      expect(message.text, 'Olá');
      expect(message.isAdmin, isTrue);
      expect(message.sentAt, isA<DateTime>());
    });
  });

  group('app_image', () {
    test('appImageProvider distingue data URI, URL e vazio', () {
      expect(appImageProvider(null), isNull);
      expect(appImageProvider(''), isNull);
      expect(appImageProvider('https://x/p.png'), isA<NetworkImage>());
      expect(appImageProvider('data:image/png;base64,iVBORw0KGgo='),
          isA<MemoryImage>());
    });

    test('dataUriToPayload separa contentType e base64', () {
      final payload = dataUriToPayload('data:image/jpeg;base64,QUJD');
      expect(payload, isNotNull);
      expect(payload!.contentType, 'image/jpeg');
      expect(payload.base64, 'QUJD');
      expect(dataUriToPayload('https://x/1.png'), isNull);
    });
  });
}
