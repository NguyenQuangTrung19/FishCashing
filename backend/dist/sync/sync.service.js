"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var SyncService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SyncService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("typeorm");
const category_entity_1 = require("../categories/entities/category.entity");
const product_entity_1 = require("../products/entities/product.entity");
const partner_entity_1 = require("../partners/entities/partner.entity");
const trading_session_entity_1 = require("../sessions/entities/trading-session.entity");
const trade_order_entity_1 = require("../orders/entities/trade-order.entity");
const order_item_entity_1 = require("../orders/entities/order-item.entity");
const transaction_entity_1 = require("../transactions/entities/transaction.entity");
const inventory_adjustment_entity_1 = require("../inventory/entities/inventory-adjustment.entity");
const payment_entity_1 = require("../payments/entities/payment.entity");
const store_info_entity_1 = require("../store/entities/store-info.entity");
const TABLE_ENTITY_MAP = {
    categories: category_entity_1.Category,
    products: product_entity_1.Product,
    partners: partner_entity_1.Partner,
    trading_sessions: trading_session_entity_1.TradingSession,
    trade_orders: trade_order_entity_1.TradeOrder,
    order_items: order_item_entity_1.OrderItem,
    transactions: transaction_entity_1.Transaction,
    inventory_adjustments: inventory_adjustment_entity_1.InventoryAdjustment,
    payments: payment_entity_1.Payment,
    store_infos: store_info_entity_1.StoreInfo,
};
const SYNCABLE_TABLES = Object.keys(TABLE_ENTITY_MAP);
const ALL_TABLES = Object.keys(TABLE_ENTITY_MAP);
let SyncService = SyncService_1 = class SyncService {
    dataSource;
    logger = new common_1.Logger(SyncService_1.name);
    constructor(dataSource) {
        this.dataSource = dataSource;
    }
    async push(userId, dto) {
        const results = {};
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
                    record.userId = userId;
                    const existing = await repo.findOne({
                        where: { id: record.id, userId },
                    });
                    if (existing) {
                        const clientUpdated = new Date(record.updatedAt || record.createdAt);
                        const serverUpdated = new Date(existing.updatedAt || existing.createdAt);
                        if (clientUpdated >= serverUpdated) {
                            Object.assign(existing, record);
                            existing.syncedAt = new Date();
                            await repo.save(existing);
                            accepted++;
                        }
                        else {
                            rejected++;
                        }
                    }
                    else {
                        record.syncedAt = new Date();
                        const entity = repo.create(record);
                        await repo.save(entity);
                        accepted++;
                    }
                }
                catch (error) {
                    this.logger.error(`Push error for ${change.table}/${record.id}: ${error.message}`);
                    rejected++;
                }
            }
            results[change.table] = { accepted, rejected };
        }
        return { results, serverTime: new Date().toISOString() };
    }
    async pull(userId, since) {
        const sinceDate = since ? new Date(since) : new Date(0);
        const changes = {};
        for (const tableName of ALL_TABLES) {
            const entityClass = TABLE_ENTITY_MAP[tableName];
            const repo = this.dataSource.getRepository(entityClass);
            let records;
            if (SYNCABLE_TABLES.includes(tableName)) {
                records = await repo.find({
                    where: {
                        userId,
                        updatedAt: (0, typeorm_1.MoreThan)(sinceDate),
                    },
                });
            }
            else {
                records = await repo.find({
                    where: {
                        userId,
                        createdAt: (0, typeorm_1.MoreThan)(sinceDate),
                    },
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
    async getStatus(userId) {
        const status = {};
        for (const tableName of ALL_TABLES) {
            const entityClass = TABLE_ENTITY_MAP[tableName];
            const repo = this.dataSource.getRepository(entityClass);
            status[tableName] = await repo.count({
                where: { userId },
            });
        }
        return { status, serverTime: new Date().toISOString() };
    }
};
exports.SyncService = SyncService;
exports.SyncService = SyncService = SyncService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeorm_1.DataSource])
], SyncService);
//# sourceMappingURL=sync.service.js.map