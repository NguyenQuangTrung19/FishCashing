import { Repository } from 'typeorm';
import { Transaction as TransactionEntity } from './entities/transaction.entity';
export declare class TransactionsService {
    private readonly repository;
    constructor(repository: Repository<TransactionEntity>);
    create(userId: string, data: any): Promise<TransactionEntity>;
    findAll(userId: string): Promise<TransactionEntity[]>;
    findOne(userId: string, id: string): Promise<TransactionEntity | null>;
    getChangesSince(userId: string, since: Date): Promise<TransactionEntity[]>;
}
