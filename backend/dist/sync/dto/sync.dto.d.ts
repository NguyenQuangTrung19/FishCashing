export declare class SyncEntityDto {
    table: string;
    records: any[];
}
export declare class SyncPushDto {
    changes: SyncEntityDto[];
    lastSyncAt?: string;
}
export declare class SyncPullQueryDto {
    since?: string;
}
