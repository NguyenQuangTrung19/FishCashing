import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('order_items')
export class OrderItem extends SyncableEntity {
  @Column('uuid')
  orderId: string;

  @Column('uuid')
  productId: string;

  @Column('bigint')
  quantityInGrams: number;

  @Column()
  unit: string;

  @Column('bigint')
  unitPriceInCents: number;

  @Column('bigint')
  lineTotalInCents: number;
}
