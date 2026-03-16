import { DataSource } from 'typeorm';
import { SyncPushDto } from './dto/sync.dto';
export declare class SyncService {
    private readonly dataSource;
    private readonly logger;
    constructor(dataSource: DataSource);
    push(userId: string, dto: SyncPushDto): Promise<{
        results: Record<string, {
            accepted: number;
            rejected: number;
        }>;
        serverTime: string;
    }>;
    pull(userId: string, since?: string): Promise<{
        changes: Record<string, any[]>;
        serverTime: string;
    }>;
    getStatus(userId: string): Promise<{
        status: Record<string, number>;
        serverTime: string;
    }>;
}
