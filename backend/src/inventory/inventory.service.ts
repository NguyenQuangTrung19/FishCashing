import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DeepPartial, FindOptionsWhere } from 'typeorm';
import { InventoryAdjustment } from './entities/inventory-adjustment.entity';

@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryAdjustment)
    private readonly repository: Repository<InventoryAdjustment>,
  ) {}

  async create(userId: string, data: any): Promise<InventoryAdjustment> {
    return this.repository.save(
      this.repository.create({
        ...data,
        userId,
      } as DeepPartial<InventoryAdjustment>),
    );
  }

  async findAll(userId: string): Promise<InventoryAdjustment[]> {
    return this.repository.find({
      where: { userId } as FindOptionsWhere<InventoryAdjustment>,
      order: { createdAt: 'DESC' },
    });
  }
}
