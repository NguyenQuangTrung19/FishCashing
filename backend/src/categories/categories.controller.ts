import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { CategoriesService } from './categories.service';
import { Category } from './entities/category.entity';

@ApiTags('categories')
@Controller('api/v1/categories')
export class CategoriesController extends BaseCrudController<Category> {
  constructor(private readonly categoriesService: CategoriesService) {
    super(categoriesService);
  }
}
