import { Controller, Get, Post, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TransactionsService } from './transactions.service';

@ApiTags('transactions')
@Controller('api/v1/transactions')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class TransactionsController {
  constructor(private readonly service: TransactionsService) {}

  @Get()
  findAll(@Request() req) { return this.service.findAll(req.user.id); }

  @Get(':id')
  findOne(@Request() req, @Param('id') id: string) { return this.service.findOne(req.user.id, id); }

  @Post()
  create(@Request() req, @Body() data: any) { return this.service.create(req.user.id, data); }
}
