import { Controller, Get, Param, Request, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { OrdersService } from './orders.service';
import { TradeOrder } from './entities/trade-order.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('orders')
@Controller('api/v1/orders')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class OrdersController extends BaseCrudController<TradeOrder> {
  constructor(private readonly ordersService: OrdersService) {
    super(ordersService);
  }

  @Get(':id/items')
  async getOrderItems(@Request() req, @Param('id') id: string) {
    return this.ordersService.findAllItems(req.user.id, id);
  }
}
