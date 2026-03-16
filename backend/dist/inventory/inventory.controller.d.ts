import { InventoryService } from './inventory.service';
export declare class InventoryController {
    private readonly service;
    constructor(service: InventoryService);
    findAll(req: any): Promise<import("./entities/inventory-adjustment.entity").InventoryAdjustment[]>;
    create(req: any, data: any): Promise<import("./entities/inventory-adjustment.entity").InventoryAdjustment>;
}
