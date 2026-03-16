import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { Product } from './entities/product.entity';
export declare class ProductsService extends BaseCrudService<Product> {
    constructor(repository: Repository<Product>);
}
