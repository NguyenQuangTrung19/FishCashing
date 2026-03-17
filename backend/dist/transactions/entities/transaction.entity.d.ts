import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class Transaction extends SyncableEntity {
    orderId: string;
    type: string;
    amountInCents: number;
    description: string;
    paymentMethod: string;
}
