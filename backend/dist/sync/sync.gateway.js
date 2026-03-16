"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var SyncGateway_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SyncGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const common_1 = require("@nestjs/common");
const socket_io_1 = require("socket.io");
const jwt_1 = require("@nestjs/jwt");
let SyncGateway = SyncGateway_1 = class SyncGateway {
    jwtService;
    server;
    logger = new common_1.Logger(SyncGateway_1.name);
    userSockets = new Map();
    constructor(jwtService) {
        this.jwtService = jwtService;
    }
    async handleConnection(client) {
        try {
            const token = client.handshake.query?.token ||
                client.handshake.auth?.token;
            if (!token) {
                this.logger.warn(`Client ${client.id} connected without token`);
                client.disconnect();
                return;
            }
            const payload = this.jwtService.verify(token);
            const userId = payload.sub;
            client.userId = userId;
            if (!this.userSockets.has(userId)) {
                this.userSockets.set(userId, new Set());
            }
            this.userSockets.get(userId).add(client.id);
            client.join(`user:${userId}`);
            this.logger.log(`User ${userId} connected (socket: ${client.id})`);
        }
        catch (error) {
            this.logger.warn(`Invalid token for client ${client.id}`);
            client.disconnect();
        }
    }
    handleDisconnect(client) {
        const userId = client.userId;
        if (userId && this.userSockets.has(userId)) {
            this.userSockets.get(userId).delete(client.id);
            if (this.userSockets.get(userId).size === 0) {
                this.userSockets.delete(userId);
            }
        }
        this.logger.log(`Client disconnected: ${client.id}`);
    }
    notifyUserSync(userId, sourceSocketId) {
        const room = `user:${userId}`;
        if (sourceSocketId) {
            this.server.to(room).except(sourceSocketId).emit('sync:updated', {
                message: 'New data available',
                timestamp: new Date().toISOString(),
            });
        }
        else {
            this.server.to(room).emit('sync:updated', {
                message: 'New data available',
                timestamp: new Date().toISOString(),
            });
        }
    }
    handlePing(client) {
        return { event: 'sync:pong', data: { timestamp: new Date().toISOString() } };
    }
    getOnlineDeviceCount(userId) {
        return this.userSockets.get(userId)?.size ?? 0;
    }
};
exports.SyncGateway = SyncGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], SyncGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('sync:ping'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket]),
    __metadata("design:returntype", void 0)
], SyncGateway.prototype, "handlePing", null);
exports.SyncGateway = SyncGateway = SyncGateway_1 = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: { origin: '*' },
        namespace: '/sync',
    }),
    __metadata("design:paramtypes", [jwt_1.JwtService])
], SyncGateway);
//# sourceMappingURL=sync.gateway.js.map