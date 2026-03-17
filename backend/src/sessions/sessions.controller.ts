import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { SessionsService } from './sessions.service';
import { TradingSession } from './entities/trading-session.entity';

@ApiTags('sessions')
@Controller('api/v1/sessions')
export class SessionsController extends BaseCrudController<TradingSession> {
  constructor(service: SessionsService) {
    super(service);
  }
}
