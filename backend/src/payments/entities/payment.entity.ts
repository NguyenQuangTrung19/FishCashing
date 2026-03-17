import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('payments')
export class Payment extends SyncableEntity {
  @Column('uuid')
  orderId: string;

  @Column('bigint', { default: 0 })
  amountInCents: number;

  @Column({ default: '' })
  note: string;
}
