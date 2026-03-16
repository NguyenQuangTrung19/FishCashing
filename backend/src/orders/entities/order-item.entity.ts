import { Entity, Column, PrimaryColumn } from 'typeorm';

@Entity('order_items')
export class OrderItem {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @Column('uuid')
  orderId: string;

  @Column('uuid')
  productId: string;

  @Column('integer')
  quantityInGrams: number;

  @Column()
  unit: string;

  @Column('integer')
  unitPriceInCents: number;

  @Column('integer')
  lineTotalInCents: number;
}
