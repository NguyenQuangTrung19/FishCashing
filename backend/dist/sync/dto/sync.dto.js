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
exports.SyncPullQueryDto = exports.SyncPushDto = exports.SyncEntityDto = void 0;
const class_validator_1 = require("class-validator");
const class_transformer_1 = require("class-transformer");
const swagger_1 = require("@nestjs/swagger");
class SyncEntityDto {
    table;
    records;
}
exports.SyncEntityDto = SyncEntityDto;
__decorate([
    (0, swagger_1.ApiProperty)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SyncEntityDto.prototype, "table", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Array of records to push' }),
    (0, class_validator_1.IsArray)(),
    __metadata("design:type", Array)
], SyncEntityDto.prototype, "records", void 0);
class SyncPushDto {
    changes;
    lastSyncAt;
}
exports.SyncPushDto = SyncPushDto;
__decorate([
    (0, swagger_1.ApiProperty)({ type: [SyncEntityDto] }),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.ValidateNested)({ each: true }),
    (0, class_transformer_1.Type)(() => SyncEntityDto),
    __metadata("design:type", Array)
], SyncPushDto.prototype, "changes", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Client last sync timestamp (ISO string)', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SyncPushDto.prototype, "lastSyncAt", void 0);
class SyncPullQueryDto {
    since;
}
exports.SyncPullQueryDto = SyncPullQueryDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Last sync timestamp (ISO string)', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SyncPullQueryDto.prototype, "since", void 0);
//# sourceMappingURL=sync.dto.js.map