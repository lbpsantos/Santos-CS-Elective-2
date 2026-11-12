import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// These tests check the exact requests that OrderService sends to Supabase.
// A fake HTTP client answers instead of a real Supabase project.
void main() {
  late List<http.Request> requests;

  OrderService serviceThatReplies(
    Future<http.Response> Function(http.Request request) reply,
  ) {
    requests = [];
    final supabase = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await reply(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(supabase.dispose);
    return OrderService(supabase);
  }

  http.Response jsonReply(Object body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Map<String, dynamic> orderRow(int id) => {
    'id': id,
    'created_at': '2026-11-12T08:30:00+00:00',
    'user_id': 'user-123',
    'status': 'done',
    'total': 1129.0,
    'order_items': [
      {
        'id': 1,
        'order_id': id,
        'product_id': 5,
        'product_name': 'The Lightning Thief',
        'unit_price': 450,
        'quantity': 2,
      },
      {
        'id': 2,
        'order_id': id,
        'product_id': null, // the book was deleted later
        'product_name': 'Old Book',
        'unit_price': 229,
        'quantity': 1,
      },
    ],
  };

  test('placeOrder calls place_order with only ids and quantities', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply(orderRow(42)),
    );

    final order = await service.placeOrder([
      {'product_id': 5, 'quantity': 2},
      {'product_id': 9, 'quantity': 1},
    ]);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/rest/v1/rpc/place_order');
    // No prices or names are sent: the database looks them up
    expect(jsonDecode(request.body), {
      'items': [
        {'product_id': 5, 'quantity': 2},
        {'product_id': 9, 'quantity': 1},
      ],
    });
    expect(order.orderNumber, '#00042');
    expect(order.status, OrderStatus.done);
    expect(order.total, 1129);
    expect(order.itemCount, 3);
    expect(order.items.last.productId, isNull);
    expect(order.items.last.productName, 'Old Book');
  });

  test('a stock error from place_order reaches the app', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply({
        'code': 'P0001',
        'message': 'Only 1 left in stock for "Dune".',
      }, status: 400),
    );

    await expectLater(
      service.placeOrder([
        {'product_id': 1, 'quantity': 3},
      ]),
      throwsA(
        isA<PostgrestException>().having(
          (error) => error.message,
          'message',
          'Only 1 left in stock for "Dune".',
        ),
      ),
    );
  });

  test('fetchMyOrders asks for own orders with items, newest first', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply([orderRow(2), orderRow(1)]),
    );

    final orders = await service.fetchMyOrders('user-123');

    final query = requests.single.url.queryParameters;
    expect(requests.single.url.path, '/rest/v1/orders');
    expect(query['select'], '*,order_items(*)');
    expect(query['user_id'], 'eq.user-123');
    expect(query['order'], 'created_at.desc.nullslast,id.desc.nullslast');
    expect(orders.map((order) => order.id), [2, 1]);
  });

  test('fetchAllOrders also asks for the customer', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply([
        {
          ...orderRow(1),
          'profiles': {
            'firstname': 'Juan',
            'lastname': 'Dela Cruz',
            'email': 'juan@example.com',
          },
        },
      ]),
    );

    final orders = await service.fetchAllOrders();

    expect(
      requests.single.url.queryParameters['select'],
      '*,order_items(*),profiles(firstname,lastname,email)',
    );
    expect(orders.single.customerName, 'Juan Dela Cruz');
  });

  test('updateStatus only sends the status', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply([
        {'id': 7},
      ]),
    );

    await service.updateStatus(7, OrderStatus.cancelled);

    final request = requests.single;
    expect(request.method, 'PATCH');
    expect(request.url.queryParameters['id'], 'eq.7');
    expect(jsonDecode(request.body), {'status': 'cancelled'});
  });

  test('a status change blocked by RLS is reported', () async {
    // RLS hides the row from non-admins, so nothing comes back.
    final service = serviceThatReplies((request) async => jsonReply([]));

    await expectLater(
      service.updateStatus(7, OrderStatus.done),
      throwsA(isA<PostgrestException>()),
    );
  });
}
