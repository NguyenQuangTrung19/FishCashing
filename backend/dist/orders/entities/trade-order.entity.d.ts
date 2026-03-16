import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class TradeOrder extends SyncableEntity {
    sessionId: string;
    partnerId: string;
    orderType: string;
    subtotalInCents: number;
    note: string;
}
