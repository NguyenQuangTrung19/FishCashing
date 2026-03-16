import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DataSource } from 'typeorm';
import { SkipThrottle } from '@nestjs/throttler';

@ApiTags('health')
@Controller('api/v1')
export class HealthController {
  constructor(private readonly dataSource: DataSource) {}

  @Get('health')
  @SkipThrottle()
  @ApiOperation({ summary: 'Health check endpoint' })
  async check() {
    // Check database connectivity
    let dbStatus = 'disconnected';
    try {
      await this.dataSource.query('SELECT 1');
      dbStatus = 'connected';
    } catch {
      dbStatus = 'error';
    }

    return {
      status: dbStatus === 'connected' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      service: 'fishcash-api',
      version: '1.0.0',
      database: dbStatus,
      uptime: Math.floor(process.uptime()),
    };
  }
}
