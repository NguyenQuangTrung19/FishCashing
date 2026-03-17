import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('inventory_adjustments')
export class InventoryAdjustment extends SyncableEntity {
  @Column('uuid')
  productId: string;

  @Column('bigint', { default: 0 })
  quantityInGrams: number;

  @Column({ default: '' })
  reason: string;
}
