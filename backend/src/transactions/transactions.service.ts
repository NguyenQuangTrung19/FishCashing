import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan, FindOptionsWhere, DeepPartial } from 'typeorm';
import { Transaction as TransactionEntity } from './entities/transaction.entity';

@Injectable()
export class TransactionsService {
  constructor(
    @InjectRepository(TransactionEntity)
    private readonly repository: Repository<TransactionEntity>,
  ) {}

  async create(userId: string, data: any): Promise<TransactionEntity> {
    const entity = this.repository.create({ ...data, userId } as DeepPartial<TransactionEntity>);
    return this.repository.save(entity);
  }

  async findAll(userId: string): Promise<TransactionEntity[]> {
    return this.repository.find({
      where: { userId } as FindOptionsWhere<TransactionEntity>,
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(userId: string, id: string): Promise<TransactionEntity | null> {
    return this.repository.findOne({
      where: { id, userId } as FindOptionsWhere<TransactionEntity>,
    });
  }

  async getChangesSince(userId: string, since: Date): Promise<TransactionEntity[]> {
    return this.repository.find({
      where: { userId, createdAt: MoreThan(since) } as FindOptionsWhere<TransactionEntity>,
    });
  }
}
