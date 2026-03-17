import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { TradingSession } from './entities/trading-session.entity';

@Injectable()
export class SessionsService extends BaseCrudService<TradingSession> {
  constructor(
    @InjectRepository(TradingSession) repository: Repository<TradingSession>,
  ) {
    super(repository);
  }
}
