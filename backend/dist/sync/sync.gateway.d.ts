import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
export declare class SyncGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private readonly jwtService;
    server: Server;
    private readonly logger;
    private userSockets;
    constructor(jwtService: JwtService);
    handleConnection(client: Socket): Promise<void>;
    handleDisconnect(client: Socket): void;
    notifyUserSync(userId: string, sourceSocketId?: string): void;
    handlePing(client: Socket): {
        event: string;
        data: {
            timestamp: string;
        };
    };
    getOnlineDeviceCount(userId: string): number;
}
