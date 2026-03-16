import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('products')
export class Product extends SyncableEntity {
  @Column('uuid')
  categoryId: string;

  @Column({ length: 150 })
  name: string;

  @Column('bigint')
  priceInCents: number;

  @Column({ default: 'kg' })
  unit: string;

  @Column({ default: '' })
  imagePath: string;

  @Column({ default: true })
  isActive: boolean;
}
