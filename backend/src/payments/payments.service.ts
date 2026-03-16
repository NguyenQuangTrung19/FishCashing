import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DeepPartial, FindOptionsWhere } from 'typeorm';
import { Payment } from './entities/payment.entity';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(Payment)
    private readonly repository: Repository<Payment>,
  ) {}

  async create(userId: string, data: any): Promise<Payment> {
    return this.repository.save(
      this.repository.create({ ...data, userId } as DeepPartial<Payment>),
    );
  }

  async findAll(userId: string): Promise<Payment[]> {
    return this.repository.find({
      where: { userId } as FindOptionsWhere<Payment>,
      order: { createdAt: 'DESC' },
    });
  }

  async findByOrder(userId: string, orderId: string): Promise<Payment[]> {
    return this.repository.find({
      where: { userId, orderId } as FindOptionsWhere<Payment>,
    });
  }
}
