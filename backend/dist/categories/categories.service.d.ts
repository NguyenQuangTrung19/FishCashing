import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { Category } from './entities/category.entity';
export declare class CategoriesService extends BaseCrudService<Category> {
    constructor(repository: Repository<Category>);
}
