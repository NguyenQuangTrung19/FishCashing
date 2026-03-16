import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { CategoriesService } from './categories.service';
import { Category } from './entities/category.entity';
export declare class CategoriesController extends BaseCrudController<Category> {
    private readonly categoriesService;
    constructor(categoriesService: CategoriesService);
}
