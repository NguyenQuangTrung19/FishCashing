import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('partners')
export class Partner extends SyncableEntity {
  @Column({ length: 150 })
  name: string;

  @Column()
  type: string; // 'supplier' or 'buyer'

  @Column({ default: '' })
  phone: string;

  @Column({ default: '' })
  address: string;

  @Column({ default: '' })
  note: string;

  @Column({ default: true })
  isActive: boolean;
}
