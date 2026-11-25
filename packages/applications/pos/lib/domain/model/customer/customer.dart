/// pos-api's status of a removed customer: it is archived, not deleted, and
/// still returned by `GET /customers`.
const customerStatusArchived = 'ARCHIVED';

class Customer {
  final String id;
  final String code;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String status;
  final String type;

  Customer({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.status,
    required this.type,
  });

  /// A removed customer: kept on the server (an old bill still names it),
  /// but not listed nor offered for a new sale.
  bool get isArchived => status == customerStatusArchived;
}
