import { Controller, Get, Post, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PaymentsService } from './payments.service';

@ApiTags('payments')
@Controller('api/v1/payments')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PaymentsController {
  constructor(private readonly service: PaymentsService) {}

  @Get()
  findAll(@Request() req) { return this.service.findAll(req.user.id); }

  @Get('order/:orderId')
  findByOrder(@Request() req, @Param('orderId') orderId: string) {
    return this.service.findByOrder(req.user.id, orderId);
  }

  @Post()
  create(@Request() req, @Body() data: any) { return this.service.create(req.user.id, data); }
}
