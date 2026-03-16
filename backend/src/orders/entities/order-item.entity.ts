import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('order_items')
export class OrderItem extends SyncableEntity {
  @Column('uuid')
  orderId: string;

  @Column('uuid')
  productId: string;

  @Column('bigint', { default: 0 })
  quantityInGrams: number;

  @Column()
  unit: string;

  @Column('bigint', { default: 0 })
  unitPriceInCents: number;

  @Column('bigint', { default: 0 })
  lineTotalInCents: number;
}
