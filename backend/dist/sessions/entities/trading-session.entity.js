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
exports.TradingSession = void 0;
const typeorm_1 = require("typeorm");
const syncable_entity_1 = require("../../common/entities/syncable.entity");
let TradingSession = class TradingSession extends syncable_entity_1.SyncableEntity {
    note;
    totalBuyInCents;
    totalSellInCents;
    profitInCents;
};
exports.TradingSession = TradingSession;
__decorate([
    (0, typeorm_1.Column)({ default: '' }),
    __metadata("design:type", String)
], TradingSession.prototype, "note", void 0);
__decorate([
    (0, typeorm_1.Column)('bigint', { default: 0 }),
    __metadata("design:type", Number)
], TradingSession.prototype, "totalBuyInCents", void 0);
__decorate([
    (0, typeorm_1.Column)('bigint', { default: 0 }),
    __metadata("design:type", Number)
], TradingSession.prototype, "totalSellInCents", void 0);
__decorate([
    (0, typeorm_1.Column)('bigint', { default: 0 }),
    __metadata("design:type", Number)
], TradingSession.prototype, "profitInCents", void 0);
exports.TradingSession = TradingSession = __decorate([
    (0, typeorm_1.Entity)('trading_sessions')
], TradingSession);
//# sourceMappingURL=trading-session.entity.js.map