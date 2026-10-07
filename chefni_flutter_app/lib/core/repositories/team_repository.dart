import '../network/api_client.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    this.storeId,
    this.phone,
  });

  final int id;
  final String name;
  final String role; // manager | chef | staff
  final bool isActive;
  final int? storeId;
  final String? phone;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'staff',
        isActive: json['is_active'] as bool? ?? true,
        storeId: (json['store_id'] as num?)?.toInt(),
        phone: json['phone'] as String?,
      );

  String get roleLabel {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'chef':
        return 'Head chef';
      case 'staff':
      default:
        return 'Kitchen staff';
    }
  }
}

class TeamRepository {
  TeamRepository(this._api);

  final ApiClient _api;

  Future<({List<StaffMember> staff, int maxStaff})> fetchAll() async {
    final json = await _api.get('/team');
    final staff = (json['data'] as List)
        .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
        .toList();
    return (staff: staff, maxStaff: (json['max_staff'] as num?)?.toInt() ?? 5);
  }

  Future<StaffMember> add({
    required String name,
    required String role,
    String? phone,
    int? storeId,
  }) async {
    final json = await _api.post('/team', body: {
      'name': name,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (storeId != null) 'store_id': storeId,
    });
    return StaffMember.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<StaffMember> setActive(int id, bool isActive) async {
    final json = await _api.patch('/team/$id', body: {'is_active': isActive});
    return StaffMember.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> remove(int id) => _api.delete('/team/$id');
}
