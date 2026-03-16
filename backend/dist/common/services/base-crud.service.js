"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BaseCrudService = void 0;
const typeorm_1 = require("typeorm");
class BaseCrudService {
    repository;
    constructor(repository) {
        this.repository = repository;
    }
    async create(userId, data) {
        const entity = this.repository.create({
            ...data,
            userId,
        });
        return this.repository.save(entity);
    }
    async findAll(userId) {
        return this.repository.find({
            where: { userId, isDeleted: false },
            order: { createdAt: 'DESC' },
        });
    }
    async findOne(userId, id) {
        return this.repository.findOne({
            where: { id, userId, isDeleted: false },
        });
    }
    async update(userId, id, data) {
        const entity = await this.findOne(userId, id);
        if (!entity)
            return null;
        Object.assign(entity, data);
        return this.repository.save(entity);
    }
    async softDelete(userId, id) {
        const entity = await this.findOne(userId, id);
        if (!entity)
            return false;
        entity.isDeleted = true;
        await this.repository.save(entity);
        return true;
    }
    async getChangesSince(userId, since) {
        return this.repository.find({
            where: {
                userId,
                updatedAt: (0, typeorm_1.MoreThan)(since),
            },
        });
    }
}
exports.BaseCrudService = BaseCrudService;
//# sourceMappingURL=base-crud.service.js.map