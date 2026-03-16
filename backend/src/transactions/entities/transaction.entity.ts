import { Entity, Column, PrimaryColumn, CreateDateColumn } from 'typeorm';

@Entity('transactions')
export class Transaction {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @Column('uuid', { nullable: true })
  orderId: string;

  @Column()
  type: string; // 'income' or 'expense'

  @Column('integer')
  amountInCents: number;

  @Column({ default: '' })
  description: string;

  @Column({ default: 'cash' })
  paymentMethod: string;

  @CreateDateColumn()
  createdAt: Date;
}
