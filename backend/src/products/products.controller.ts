import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { ProductsService } from './products.service';
import { Product } from './entities/product.entity';

@ApiTags('products')
@Controller('api/v1/products')
export class ProductsController extends BaseCrudController<Product> {
  constructor(service: ProductsService) {
    super(service);
  }
}
