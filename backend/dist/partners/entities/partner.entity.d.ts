import { SyncableEntity } from '../../common/entities/syncable.entity';
export declare class Partner extends SyncableEntity {
    name: string;
    type: string;
    phone: string;
    address: string;
    note: string;
    isActive: boolean;
}
