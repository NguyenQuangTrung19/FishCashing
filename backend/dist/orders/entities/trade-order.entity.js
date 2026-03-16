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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradeOrder = void 0;
const typeorm_1 = require("typeorm");
const syncable_entity_1 = require("../../common/entities/syncable.entity");
let TradeOrder = class TradeOrder extends syncable_entity_1.SyncableEntity {
    sessionId;
    partnerId;
    orderType;
    subtotalInCents;
    note;
};
exports.TradeOrder = TradeOrder;
__decorate([
    (0, typeorm_1.Column)('uuid', { nullable: true }),
    __metadata("design:type", String)
], TradeOrder.prototype, "sessionId", void 0);
__decorate([
    (0, typeorm_1.Column)('uuid', { nullable: true }),
    __metadata("design:type", String)
], TradeOrder.prototype, "partnerId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], TradeOrder.prototype, "orderType", void 0);
__decorate([
    (0, typeorm_1.Column)('bigint', { default: 0 }),
    __metadata("design:type", Number)
], TradeOrder.prototype, "subtotalInCents", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: '' }),
    __metadata("design:type", String)
], TradeOrder.prototype, "note", void 0);
exports.TradeOrder = TradeOrder = __decorate([
    (0, typeorm_1.Entity)('trade_orders')
], TradeOrder);
//# sourceMappingURL=trade-order.entity.js.map