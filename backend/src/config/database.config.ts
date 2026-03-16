import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getDatabaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get<string>('DB_HOST', 'localhost'),
  port: configService.get<number>('DB_PORT', 5432),
  username: configService.get<string>('DB_USERNAME', 'fishcash'),
  password: configService.get<string>('DB_PASSWORD', 'fishcash_secret'),
  database: configService.get<string>('DB_DATABASE', 'fishcash_pos'),
  autoLoadEntities: true,
  // DB_SYNCHRONIZE=true to auto-create tables (use for initial setup only!)
  synchronize:
    configService.get<string>('DB_SYNCHRONIZE', 
      configService.get<string>('NODE_ENV') === 'development' ? 'true' : 'false'
    ) === 'true',
  logging: configService.get<string>('NODE_ENV') === 'development',
});
