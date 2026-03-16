import { Repository } from 'typeorm';
import { BaseCrudService } from '../common/services/base-crud.service';
import { TradingSession } from './entities/trading-session.entity';
export declare class SessionsService extends BaseCrudService<TradingSession> {
    constructor(repository: Repository<TradingSession>);
}
