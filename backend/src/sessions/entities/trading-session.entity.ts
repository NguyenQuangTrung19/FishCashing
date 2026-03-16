import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('trading_sessions')
export class TradingSession extends SyncableEntity {
  @Column({ default: '' })
  note: string;

  @Column('bigint', { default: 0 })
  totalBuyInCents: number;

  @Column('bigint', { default: 0 })
  totalSellInCents: number;

  @Column('bigint', { default: 0 })
  profitInCents: number;
}
