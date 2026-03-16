import { Repository } from 'typeorm';
import { Payment } from './entities/payment.entity';
export declare class PaymentsService {
    private readonly repository;
    constructor(repository: Repository<Payment>);
    create(userId: string, data: any): Promise<Payment>;
    findAll(userId: string): Promise<Payment[]>;
    findByOrder(userId: string, orderId: string): Promise<Payment[]>;
}
