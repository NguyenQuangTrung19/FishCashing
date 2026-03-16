import {
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

/// Base entity with common sync columns.
/// All data entities extend this for multi-tenant + sync support.
export abstract class SyncableEntity {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  syncedAt: Date;

  @Column({ default: false })
  isDeleted: boolean;
}
