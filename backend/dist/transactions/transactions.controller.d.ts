import { TransactionsService } from './transactions.service';
export declare class TransactionsController {
    private readonly service;
    constructor(service: TransactionsService);
    findAll(req: any): Promise<import("./entities/transaction.entity").Transaction[]>;
    findOne(req: any, id: string): Promise<import("./entities/transaction.entity").Transaction | null>;
    create(req: any, data: any): Promise<import("./entities/transaction.entity").Transaction>;
}
