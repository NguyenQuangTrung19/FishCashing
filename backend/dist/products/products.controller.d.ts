import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { ProductsService } from './products.service';
import { Product } from './entities/product.entity';
export declare class ProductsController extends BaseCrudController<Product> {
    constructor(service: ProductsService);
}
