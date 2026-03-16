import { StoreService } from './store.service';
export declare class StoreController {
    private readonly service;
    constructor(service: StoreService);
    get(req: any): Promise<import("./entities/store-info.entity").StoreInfo>;
    update(req: any, data: any): Promise<import("./entities/store-info.entity").StoreInfo>;
}
