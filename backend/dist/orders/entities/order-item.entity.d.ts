import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class OrderItem extends SyncableEntity {
    orderId: string;
    productId: string;
    quantityInGrams: number;
    unit: string;
    unitPriceInCents: number;
    lineTotalInCents: number;
}
