import { Injectable, Logger } from '@nestjs/common';
import { DataSource, MoreThan } from 'typeorm';

import { Category } from '../categories/entities/category.entity';
import { Product } from '../products/entities/product.entity';
import { Partner } from '../partners/entities/partner.entity';
import { TradingSession } from '../sessions/entities/trading-session.entity';
import { TradeOrder } from '../orders/entities/trade-order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { Transaction as TransactionEntity } from '../transactions/entities/transaction.entity';
import { InventoryAdjustment } from '../inventory/entities/inventory-adjustment.entity';
import { Payment } from '../payments/entities/payment.entity';
import { StoreInfo } from '../store/entities/store-info.entity';
import { SyncPushDto } from './dto/sync.dto';

/// Table name → Entity class mapping
const TABLE_ENTITY_MAP: Record<string, any> = {
  categories: Category,
  products: Product,
  partners: Partner,
  trading_sessions: TradingSession,
  trade_orders: TradeOrder,
  order_items: OrderItem,
  transactions: TransactionEntity,
  inventory_adjustments: InventoryAdjustment,
  payments: Payment,
  store_infos: StoreInfo,
};

// All entities extend SyncableEntity, all support updatedAt filter
const SYNCABLE_TABLES = Object.keys(TABLE_ENTITY_MAP);

const ALL_TABLES = Object.keys(TABLE_ENTITY_MAP);

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);

  constructor(private readonly dataSource: DataSource) {}

  /// Push changes from client to server.
  /// Strategy: last-write-wins based on updatedAt.
  async push(userId: string, dto: SyncPushDto) {
    const results: Record<string, { accepted: number; rejected: number }> = {};

    for (const change of dto.changes) {
      const entityClass = TABLE_ENTITY_MAP[change.table];
      if (!entityClass) {
        this.logger.warn(`Unknown table: ${change.table}`);
        continue;
      }

      const repo = this.dataSource.getRepository(entityClass);
      let accepted = 0;
      let rejected = 0;

      for (const record of change.records) {
        try {
          // Always assign userId for multi-tenant isolation
          record.userId = userId;

          // Check if record exists
          const existing = await repo.findOne({
            where: { id: record.id, userId } as any,
          });

          if (existing) {
            // Last-write-wins: only accept if client's updatedAt >= server's
            const clientUpdated = new Date(
              record.updatedAt || record.createdAt,
            );
            const serverUpdated = new Date(
              (existing as any).updatedAt || (existing as any).createdAt,
            );

            if (clientUpdated >= serverUpdated) {
              Object.assign(existing, record);
              (existing as any).syncedAt = new Date();
              await repo.save(existing as any);
              accepted++;
            } else {
              rejected++;
            }
          } else {
            // New record — insert
            record.syncedAt = new Date();
            const entity = repo.create(record);
            await repo.save(entity as any);
            accepted++;
          }
        } catch (error) {
          this.logger.error(
            `Push error for ${change.table}/${record.id}: ${error.message}`,
          );
          rejected++;
        }
      }

      results[change.table] = { accepted, rejected };
    }

    return { results, serverTime: new Date().toISOString() };
  }

  /// Pull changes from server since a given timestamp.
  async pull(userId: string, since?: string) {
    const sinceDate = since ? new Date(since) : new Date(0);
    const changes: Record<string, any[]> = {};

    for (const tableName of ALL_TABLES) {
      const entityClass = TABLE_ENTITY_MAP[tableName];
      const repo = this.dataSource.getRepository(entityClass);

      let records: any[];

      // For syncable entities (with updatedAt), use updatedAt filter
      if (SYNCABLE_TABLES.includes(tableName)) {
        records = await repo.find({
          where: {
            userId,
            updatedAt: MoreThan(sinceDate),
          } as any,
        });
      } else {
        // For append-only entities (with createdAt only)
        records = await repo.find({
          where: {
            userId,
            createdAt: MoreThan(sinceDate),
          } as any,
        });
      }

      if (records.length > 0) {
        changes[tableName] = records;
      }
    }

    return {
      changes,
      serverTime: new Date().toISOString(),
    };
  }

  /// Get sync status: count of records per table.
  async getStatus(userId: string) {
    const status: Record<string, number> = {};

    for (const tableName of ALL_TABLES) {
      const entityClass = TABLE_ENTITY_MAP[tableName];
      const repo = this.dataSource.getRepository(entityClass);
      status[tableName] = await repo.count({
        where: { userId } as any,
      });
    }

    return { status, serverTime: new Date().toISOString() };
  }
}
