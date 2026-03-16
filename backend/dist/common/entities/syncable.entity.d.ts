export declare abstract class SyncableEntity {
    id: string;
    userId: string;
    createdAt: Date;
    updatedAt: Date;
    syncedAt: Date;
    isDeleted: boolean;
}
