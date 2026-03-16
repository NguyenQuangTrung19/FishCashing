import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SyncService } from './sync.service';
import { SyncGateway } from './sync.gateway';
import { SyncPushDto } from './dto/sync.dto';

@ApiTags('sync')
@Controller('api/v1/sync')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SyncController {
  constructor(
    private readonly syncService: SyncService,
    private readonly syncGateway: SyncGateway,
  ) {}

  @Post('push')
  @ApiOperation({ summary: 'Push local changes to server' })
  async push(@Request() req: any, @Body() dto: SyncPushDto) {
    const result = await this.syncService.push(req.user.id, dto);

    // Notify other devices of this user to pull
    this.syncGateway.notifyUserSync(req.user.id);

    return result;
  }

  @Get('pull')
  @ApiOperation({ summary: 'Pull server changes since timestamp' })
  async pull(
    @Request() req: any,
    @Query('since') since?: string,
  ) {
    return this.syncService.pull(req.user.id, since);
  }

  @Get('status')
  @ApiOperation({ summary: 'Get sync status (record counts per table)' })
  async status(@Request() req: any) {
    const syncStatus = await this.syncService.getStatus(req.user.id);
    return {
      ...syncStatus,
      onlineDevices: this.syncGateway.getOnlineDeviceCount(req.user.id),
    };
  }
}
