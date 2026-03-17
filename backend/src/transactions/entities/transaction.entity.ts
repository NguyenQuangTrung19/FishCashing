import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('transactions')
export class Transaction extends SyncableEntity {
  @Column('uuid', { nullable: true })
  orderId: string;

  @Column()
  type: string; // 'income' or 'expense'

  @Column('bigint', { default: 0 })
  amountInCents: number;

  @Column({ default: '' })
  description: string;

  @Column({ default: 'cash' })
  paymentMethod: string;
}
