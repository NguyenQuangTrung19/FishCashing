import { Controller, Get, Put, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { StoreService } from './store.service';

@ApiTags('store')
@Controller('api/v1/store-info')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class StoreController {
  constructor(private readonly service: StoreService) {}

  @Get()
  get(@Request() req) { return this.service.getOrCreate(req.user.id); }

  @Put()
  update(@Request() req, @Body() data: any) { return this.service.update(req.user.id, data); }
}
