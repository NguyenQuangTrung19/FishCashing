import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { TradeOrder } from './entities/trade-order.entity';
import { OrderItem } from './entities/order-item.entity';
export declare class OrdersService extends BaseCrudService<TradeOrder> {
    private readonly itemRepository;
    constructor(repository: Repository<TradeOrder>, itemRepository: Repository<OrderItem>);
    findAllItems(userId: string, orderId: string): Promise<OrderItem[]>;
    saveItems(userId: string, items: any[]): Promise<OrderItem[]>;
}
