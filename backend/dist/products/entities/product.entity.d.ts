import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class Product extends SyncableEntity {
    categoryId: string;
    name: string;
    priceInCents: number;
    unit: string;
    imagePath: string;
    isActive: boolean;
}
