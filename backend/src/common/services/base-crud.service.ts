import { Repository, MoreThan, DeepPartial } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';

/// Generic CRUD service for all syncable entities.
/// Provides: create, findAll (by userId), findOne, update, softDelete
export class BaseCrudService<T extends Record<string, any>> {
  constructor(protected readonly repository: Repository<T>) {}

  async create(userId: string, data: any): Promise<T> {
    const entity = this.repository.create({
      ...data,
      id: data.id || uuidv4(),
      userId,
    } as DeepPartial<T>);
    return this.repository.save(entity as any);
  }

  async findAll(userId: string): Promise<T[]> {
    return this.repository.find({
      where: { userId, isDeleted: false } as any,
      order: { createdAt: 'DESC' } as any,
    });
  }

  async findOne(userId: string, id: string): Promise<T | null> {
    return this.repository.findOne({
      where: { id, userId, isDeleted: false } as any,
    });
  }

  async update(userId: string, id: string, data: any): Promise<T | null> {
    const entity = await this.findOne(userId, id);
    if (!entity) return null;

    Object.assign(entity, data);
    return this.repository.save(entity as any);
  }

  async softDelete(userId: string, id: string): Promise<boolean> {
    const entity = await this.findOne(userId, id);
    if (!entity) return false;

    (entity as any).isDeleted = true;
    await this.repository.save(entity as any);
    return true;
  }

  async getChangesSince(userId: string, since: Date): Promise<T[]> {
    return this.repository.find({
      where: {
        userId,
        updatedAt: MoreThan(since),
      } as any,
    });
  }
}
