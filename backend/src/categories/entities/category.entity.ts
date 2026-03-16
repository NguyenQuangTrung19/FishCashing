import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('categories')
export class Category extends SyncableEntity {
  @Column({ length: 100 })
  name: string;

  @Column({ default: '' })
  description: string;

  @Column({ default: true })
  isActive: boolean;
}
