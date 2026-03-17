import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { PartnersService } from './partners.service';
import { Partner } from './entities/partner.entity';

@ApiTags('partners')
@Controller('api/v1/partners')
export class PartnersController extends BaseCrudController<Partner> {
  constructor(service: PartnersService) {
    super(service);
  }
}
