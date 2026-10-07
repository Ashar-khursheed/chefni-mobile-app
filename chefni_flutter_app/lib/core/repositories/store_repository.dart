import '../network/api_client.dart';

class Store {
  const Store({
    required this.id,
    required this.name,
    required this.isDefault,
    this.address,
    this.itemCount,
    this.lowStockCount,
    this.expiringCount,
  });

  final int id;
  final String name;
  final bool isDefault;
  final String? address;
  final int? itemCount;
  final int? lowStockCount;
  final int? expiringCount;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
        address: json['address'] as String?,
        itemCount: (json['item_count'] as num?)?.toInt(),
        lowStockCount: (json['low_stock_count'] as num?)?.toInt(),
        expiringCount: (json['expiring_count'] as num?)?.toInt(),
      );
}

class StoreRepository {
  StoreRepository(this._api);

  final ApiClient _api;

  Future<List<Store>> fetchAll() async {
    final json = await _api.get('/stores');
    return (json['data'] as List)
        .map((e) => Store.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Store> add({required String name, String? address}) async {
    final json = await _api.post('/stores', body: {
      'name': name,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    return Store.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> remove(int id) => _api.delete('/stores/$id');
}
