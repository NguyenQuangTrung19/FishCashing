import { Entity, Column, PrimaryColumn, CreateDateColumn } from 'typeorm';

@Entity('inventory_adjustments')
export class InventoryAdjustment {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @Column('uuid')
  productId: string;

  @Column('bigint')
  quantityInGrams: number;

  @Column({ default: '' })
  reason: string;

  @CreateDateColumn()
  createdAt: Date;
}
