import { Repository } from 'typeorm';
import { InventoryAdjustment } from './entities/inventory-adjustment.entity';
export declare class InventoryService {
    private readonly repository;
    constructor(repository: Repository<InventoryAdjustment>);
    create(userId: string, data: any): Promise<InventoryAdjustment>;
    findAll(userId: string): Promise<InventoryAdjustment[]>;
}
