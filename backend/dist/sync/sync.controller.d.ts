import { SyncService } from './sync.service';
import { SyncGateway } from './sync.gateway';
import { SyncPushDto } from './dto/sync.dto';
export declare class SyncController {
    private readonly syncService;
    private readonly syncGateway;
    constructor(syncService: SyncService, syncGateway: SyncGateway);
    push(req: any, dto: SyncPushDto): Promise<{
        results: Record<string, {
            accepted: number;
            rejected: number;
        }>;
        serverTime: string;
    }>;
    pull(req: any, since?: string): Promise<{
        changes: Record<string, any[]>;
        serverTime: string;
    }>;
    status(req: any): Promise<{
        onlineDevices: number;
        status: Record<string, number>;
        serverTime: string;
    }>;
}
