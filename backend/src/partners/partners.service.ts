import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { Partner } from './entities/partner.entity';

@Injectable()
export class PartnersService extends BaseCrudService<Partner> {
  constructor(@InjectRepository(Partner) repository: Repository<Partner>) {
    super(repository);
  }
}
