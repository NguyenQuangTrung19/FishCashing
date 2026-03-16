import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DeepPartial, FindOptionsWhere } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { TradeOrder } from './entities/trade-order.entity';
import { OrderItem } from './entities/order-item.entity';

@Injectable()
export class OrdersService extends BaseCrudService<TradeOrder> {
  constructor(
    @InjectRepository(TradeOrder) repository: Repository<TradeOrder>,
    @InjectRepository(OrderItem)
    private readonly itemRepository: Repository<OrderItem>,
  ) {
    super(repository);
  }

  async findAllItems(userId: string, orderId: string): Promise<OrderItem[]> {
    return this.itemRepository.find({
      where: { userId, orderId } as FindOptionsWhere<OrderItem>,
    });
  }

  async saveItems(userId: string, items: any[]): Promise<OrderItem[]> {
    const entities = items.map((item) =>
      this.itemRepository.create({ ...item, userId } as DeepPartial<OrderItem>),
    );
    return this.itemRepository.save(entities);
  }
}
