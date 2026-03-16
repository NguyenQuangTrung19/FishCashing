import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { Product } from './entities/product.entity';

@Injectable()
export class ProductsService extends BaseCrudService<Product> {
  constructor(@InjectRepository(Product) repository: Repository<Product>) {
    super(repository);
  }
}
