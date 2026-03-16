import { Repository } from 'typeorm';
import { StoreInfo } from './entities/store-info.entity';
export declare class StoreService {
    private readonly repository;
    constructor(repository: Repository<StoreInfo>);
    getOrCreate(userId: string): Promise<StoreInfo>;
    update(userId: string, data: any): Promise<StoreInfo>;
}
