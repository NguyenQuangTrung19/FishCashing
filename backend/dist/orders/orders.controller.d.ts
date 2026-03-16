import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { OrdersService } from './orders.service';
import { TradeOrder } from './entities/trade-order.entity';
export declare class OrdersController extends BaseCrudController<TradeOrder> {
    private readonly ordersService;
    constructor(ordersService: OrdersService);
    getOrderItems(req: any, id: string): Promise<import("./entities/order-item.entity").OrderItem[]>;
}
