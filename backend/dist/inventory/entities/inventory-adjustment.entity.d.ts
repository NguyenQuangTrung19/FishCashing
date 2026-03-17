import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class InventoryAdjustment extends SyncableEntity {
    productId: string;
    quantityInGrams: number;
    reason: string;
}
