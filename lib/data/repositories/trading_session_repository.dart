/// Repository for Trading Session operations.
library;

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:fishcash_pos/data/database/app_database.dart';
import 'package:fishcash_pos/data/database/daos/trading_session_dao.dart';

/// Domain model for trading session
class TradingSessionModel {
  final String id;
  final String note;
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal profit;
  final int orderCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TradingSessionModel({
    required this.id,
    required this.note,
    required this.totalBuy,
    required this.totalSell,
    required this.profit,
    this.orderCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}

class TradingSessionRepository {
  final TradingSessionDao _dao;
  static const _uuid = Uuid();

  TradingSessionRepository(this._dao);

  static Decimal _centsToDecimal(int cents) {
    return (Decimal.fromInt(cents) / Decimal.fromInt(100)).toDecimal();
  }

  TradingSessionModel _toModel(TradingSession entity, {int orderCount = 0}) {
    return TradingSessionModel(
      id: entity.id,
      note: entity.note,
      totalBuy: _centsToDecimal(entity.totalBuyInCents),
      totalSell: _centsToDecimal(entity.totalSellInCents),
      profit: _centsToDecimal(entity.profitInCents),
      orderCount: orderCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Get all sessions
  Future<List<TradingSessionModel>> getAll() async {
    final entities = await _dao.getAll();
    final result = <TradingSessionModel>[];
    for (final entity in entities) {
      final count = await _dao.getOrderCount(entity.id);
      result.add(_toModel(entity, orderCount: count));
    }
    return result;
  }

  /// Watch all sessions
  Stream<List<TradingSessionModel>> watchAll() {
    return _dao.watchAll().asyncMap((entities) async {
      final result = <TradingSessionModel>[];
      for (final entity in entities) {
        final count = await _dao.getOrderCount(entity.id);
        result.add(_toModel(entity, orderCount: count));
      }
      return result;
    });
  }

  /// Get session by ID
  Future<TradingSessionModel?> getById(String id) async {
    final entity = await _dao.getById(id);
    if (entity == null) return null;
    final count = await _dao.getOrderCount(id);
    return _toModel(entity, orderCount: count);
  }

  /// Create new session
  Future<TradingSessionModel> create({String note = ''}) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _dao.insertSession(TradingSessionsCompanion(
      id: Value(id),
      note: Value(note),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return TradingSessionModel(
      id: id,
      note: note,
      totalBuy: Decimal.zero,
      totalSell: Decimal.zero,
      profit: Decimal.zero,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update session note
  Future<void> updateNote(String id, String note) async {
    await _dao.updateSession(TradingSessionsCompanion(
      id: Value(id),
      note: Value(note),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete session and all its orders
  Future<void> delete(String id) async {
    await _dao.deleteSession(id);
  }
}
