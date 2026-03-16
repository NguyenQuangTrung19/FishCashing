import { Entity, Column, PrimaryColumn } from 'typeorm';

@Entity('store_infos')
export class StoreInfo {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

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
