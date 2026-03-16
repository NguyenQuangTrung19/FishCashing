import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { Partner } from './entities/partner.entity';
export declare class PartnersService extends BaseCrudService<Partner> {
    constructor(repository: Repository<Partner>);
}
