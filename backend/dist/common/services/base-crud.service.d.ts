import { Repository } from 'typeorm';
export declare class BaseCrudService<T extends Record<string, any>> {
    protected readonly repository: Repository<T>;
    constructor(repository: Repository<T>);
    create(userId: string, data: any): Promise<T>;
    findAll(userId: string): Promise<T[]>;
    findOne(userId: string, id: string): Promise<T | null>;
    update(userId: string, id: string, data: any): Promise<T | null>;
    softDelete(userId: string, id: string): Promise<boolean>;
    getChangesSince(userId: string, since: Date): Promise<T[]>;
}
