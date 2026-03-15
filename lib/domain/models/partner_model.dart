/// Domain model representing a partner (Supplier or Buyer).
library;

import 'package:equatable/equatable.dart';

enum PartnerType {
  supplier, // Nhà cung cấp (chủ ghe, tàu)
  buyer, // Khách mua (nhà hàng, cơ sở chế biến)
}

class PartnerModel extends Equatable {
  final String id;
  final String name;
  final PartnerType type;
  final String phone;
  final String address;
  final String note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PartnerModel({
    required this.id,
    required this.name,
    required this.type,
    this.phone = '',
    this.address = '',
    this.note = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  PartnerModel copyWith({
    String? id,
    String? name,
    PartnerType? type,
    String? phone,
    String? address,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeLabel =>
      type == PartnerType.supplier ? 'Nhà cung cấp' : 'Khách mua';

  @override
  List<Object?> get props => [id, name, type, phone, isActive];
}
