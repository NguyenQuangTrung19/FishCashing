import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';

/// WebSocket gateway for real-time sync notifications.
///
/// When a client pushes data, the server broadcasts a 'sync:updated'
/// event to all other devices of the same user, prompting them to pull.
@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/sync',
})
export class SyncGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(SyncGateway.name);

  // userId -> Set of socket IDs
  private userSockets = new Map<string, Set<string>>();

  constructor(private readonly jwtService: JwtService) {}

  async handleConnection(client: Socket) {
    try {
      // Extract JWT from query or auth header
      const token =
        (client.handshake.query?.token as string) ||
        client.handshake.auth?.token;

      if (!token) {
        this.logger.warn(`Client ${client.id} connected without token`);
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      const userId = payload.sub;

      // Store connection
      (client as any).userId = userId;
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);

      // Join user-specific room
      void client.join(`user:${userId}`);

      this.logger.log(`User ${userId} connected (socket: ${client.id})`);
    } catch (_error) {
      this.logger.warn(`Invalid token for client ${client.id}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = (client as any).userId;
    if (userId && this.userSockets.has(userId)) {
      this.userSockets.get(userId)!.delete(client.id);
      if (this.userSockets.get(userId)!.size === 0) {
        this.userSockets.delete(userId);
      }
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /// Called by SyncService after successful push.
  /// Notifies all OTHER devices of the same user to pull changes.
  notifyUserSync(userId: string, sourceSocketId?: string) {
    const room = `user:${userId}`;
    if (sourceSocketId) {
      // Broadcast to all sockets in the room EXCEPT the source
      this.server.to(room).except(sourceSocketId).emit('sync:updated', {
        message: 'New data available',
        timestamp: new Date().toISOString(),
      });
    } else {
      this.server.to(room).emit('sync:updated', {
        message: 'New data available',
        timestamp: new Date().toISOString(),
      });
    }
  }

  @SubscribeMessage('sync:ping')
  handlePing(_client: Socket) {
    return {
      event: 'sync:pong',
      data: { timestamp: new Date().toISOString() },
    };
  }

  /// Get count of online devices for a user.
  getOnlineDeviceCount(userId: string): number {
    return this.userSockets.get(userId)?.size ?? 0;
  }
}
