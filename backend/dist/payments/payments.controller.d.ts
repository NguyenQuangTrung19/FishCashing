import { PaymentsService } from './payments.service';
export declare class PaymentsController {
    private readonly service;
    constructor(service: PaymentsService);
    findAll(req: any): Promise<import("./entities/payment.entity").Payment[]>;
    findByOrder(req: any, orderId: string): Promise<import("./entities/payment.entity").Payment[]>;
    create(req: any, data: any): Promise<import("./entities/payment.entity").Payment>;
}
