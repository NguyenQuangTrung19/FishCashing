import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { InventoryService } from './inventory.service';

@ApiTags('inventory')
@Controller('api/v1/inventory-adjustments')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class InventoryController {
  constructor(private readonly service: InventoryService) {}

  @Get()
  findAll(@Request() req) {
    return this.service.findAll(req.user.id);
  }

  @Post()
  create(@Request() req, @Body() data: any) {
    return this.service.create(req.user.id, data);
  }
}
