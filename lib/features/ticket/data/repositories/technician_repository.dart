import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/technician_model.dart';

final technicianRepositoryProvider = Provider((ref) => TechnicianRepository());

class TechnicianRepository {
  // Dummy technicians
  static final List<Technician> _technicians = [
    Technician(id: 'tech_001', name: 'Alan Udin', username: 'udin'),
    Technician(id: 'tech_002', name: 'Vikibara Can', username: 'viki'),
    Technician(id: 'tech_003', name: 'Rizkimok', username: 'rizki'),
  ];

  /// Get all technicians
  Future<List<Technician>> getTechnicians() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _technicians;
  }

  /// Get technician by id
  Future<Technician?> getTechnicianById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _technicians.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get technician by username
  Future<Technician?> getTechnicianByUsername(String username) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _technicians.firstWhere((t) => t.username == username);
    } catch (e) {
      return null;
    }
  }
}
