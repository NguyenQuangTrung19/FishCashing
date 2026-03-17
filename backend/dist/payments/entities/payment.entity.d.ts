import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class Payment extends SyncableEntity {
    orderId: string;
    amountInCents: number;
    note: string;
}
