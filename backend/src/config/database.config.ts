import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

/// Database configuration supporting both:
/// - DATABASE_URL (production — Neon.tech, Render, etc.)
/// - Individual DB_* env vars (local development)
export const getDatabaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => {
  const isProduction = configService.get<string>('NODE_ENV') === 'production';
  const databaseUrl = configService.get<string>('DATABASE_URL');

  const synchronize =
    configService.get<string>(
      'DB_SYNCHRONIZE',
      isProduction ? 'false' : 'true',
    ) === 'true';

  // If DATABASE_URL is provided (production/Neon.tech), use it
  if (databaseUrl) {
    return {
      type: 'postgres',
      url: databaseUrl,
      autoLoadEntities: true,
      synchronize,
      logging: !isProduction,
      ssl: isProduction ? { rejectUnauthorized: false } : false,
    };
  }

  // Fallback to individual env vars (local development)
  return {
    type: 'postgres',
    host: configService.get<string>('DB_HOST', 'localhost'),
    port: configService.get<number>('DB_PORT', 5432),
    username: configService.get<string>('DB_USERNAME', 'fishcash'),
    password: configService.get<string>('DB_PASSWORD', 'fishcash_secret'),
    database: configService.get<string>('DB_DATABASE', 'fishcash_pos'),
    autoLoadEntities: true,
    synchronize,
    logging: true,
  };
};
