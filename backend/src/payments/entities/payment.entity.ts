import { Entity, Column, PrimaryColumn, CreateDateColumn } from 'typeorm';

@Entity('payments')
export class Payment {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @Column('uuid')
  orderId: string;

  @Column('bigint', { default: 0 })
  amountInCents: number;

  @Column({ default: '' })
  note: string;

  @CreateDateColumn()
  createdAt: Date;
}
