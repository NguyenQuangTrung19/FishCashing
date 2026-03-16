import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class TradingSession extends SyncableEntity {
    note: string;
    totalBuyInCents: number;
    totalSellInCents: number;
    profitInCents: number;
}
