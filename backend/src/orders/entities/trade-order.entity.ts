import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('trade_orders')
export class TradeOrder extends SyncableEntity {
  @Column('uuid', { nullable: true })
  sessionId: string;

  @Column('uuid', { nullable: true })
  partnerId: string;

  @Column()
  orderType: string; // 'buy', 'sell', 'pos'

  @Column('bigint', { default: 0 })
  subtotalInCents: number;

  @Column({ default: '' })
  note: string;
}
