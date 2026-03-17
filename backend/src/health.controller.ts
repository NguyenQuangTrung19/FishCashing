import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DataSource } from 'typeorm';
import { SkipThrottle } from '@nestjs/throttler';

@ApiTags('health')
@Controller('api/v1')
export class HealthController {
  constructor(private readonly dataSource: DataSource) {}

  /// Simple health check — for UptimeRobot ping (keeps server alive)
  @Get('health')
  @SkipThrottle()
  @ApiOperation({ summary: 'Simple health check (for monitoring)' })
  async check() {
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
      database: dbStatus,
    };
  }

  /// Detailed health check — includes memory, DB latency, uptime
  @Get('health/detailed')
  @SkipThrottle()
  @ApiOperation({ summary: 'Detailed health check with metrics' })
  async detailedCheck() {
    // Measure DB latency
    let dbStatus = 'disconnected';
    let dbLatencyMs = -1;
    try {
      const start = Date.now();
      await this.dataSource.query('SELECT 1');
      dbLatencyMs = Date.now() - start;
      dbStatus = 'connected';
    } catch {
      dbStatus = 'error';
    }

    // Memory usage
    const mem = process.memoryUsage();

    return {
      status: dbStatus === 'connected' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      service: 'fishcash-api',
      version: '1.0.0',
      uptime: Math.floor(process.uptime()),
      database: {
        status: dbStatus,
        latencyMs: dbLatencyMs,
      },
      memory: {
        rss: `${Math.round(mem.rss / 1024 / 1024)}MB`,
        heapUsed: `${Math.round(mem.heapUsed / 1024 / 1024)}MB`,
        heapTotal: `${Math.round(mem.heapTotal / 1024 / 1024)}MB`,
      },
    };
  }
}
