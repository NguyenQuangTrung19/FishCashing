import { BaseCrudController } from '../common/controllers/base-crud.controller';
import { SessionsService } from './sessions.service';
import { TradingSession } from './entities/trading-session.entity';
export declare class SessionsController extends BaseCrudController<TradingSession> {
    constructor(service: SessionsService);
}
