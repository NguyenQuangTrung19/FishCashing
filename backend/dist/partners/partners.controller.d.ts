import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { PartnersService } from './partners.service';
import { Partner } from './entities/partner.entity';
export declare class PartnersController extends BaseCrudController<Partner> {
    constructor(service: PartnersService);
}
