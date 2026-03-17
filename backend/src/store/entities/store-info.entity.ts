import { Entity, Column } from 'typeorm';
import { SyncableEntity } from '../../common/entities/syncable.entity';

@Entity('store_infos')
export class StoreInfo extends SyncableEntity {
  @Column({ default: '' })
  name: string;

  @Column({ default: '' })
  address: string;

  @Column({ default: '' })
  phone: string;

  @Column({ default: '' })
  logoPath: string;

  @Column({ default: '' })
  qrImagePath: string;
}
