import { BaseCrudService } from '../services/base-crud.service';
export declare abstract class BaseCrudController<T extends Record<string, any>> {
    protected readonly service: BaseCrudService<T>;
    constructor(service: BaseCrudService<T>);
    findAll(req: any): Promise<T[]>;
    findOne(req: any, id: string): Promise<T>;
    create(req: any, data: any): Promise<T>;
    update(req: any, id: string, data: any): Promise<T>;
    remove(req: any, id: string): Promise<{
        deleted: boolean;
    }>;
}
