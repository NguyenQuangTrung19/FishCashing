import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';

import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const isProduction = configService.get<string>('NODE_ENV') === 'production';
  const port = configService.get<number>('PORT', 3000);

  // ── Security ────────────────────────────────────────────
  // HTTP security headers (X-Content-Type-Options, X-Frame-Options, etc.)
  app.use(helmet());

  // CORS for Flutter app
  const corsOrigin = configService.get<string>('CORS_ORIGIN', '*');
  app.enableCors({
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    credentials: true,
  });

  // ── Validation ──────────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // ── Swagger (development only) ──────────────────────────
  if (!isProduction) {
    const config = new DocumentBuilder()
      .setTitle('FishCash POS API')
      .setDescription(
        'Backend API for FishCash POS — Multi-device sync & backup',
      )
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
    logger.log('📖 Swagger docs enabled at /api/docs');
  }

  // ── Graceful shutdown ───────────────────────────────────
  app.enableShutdownHooks();

  // ── Start server ────────────────────────────────────────
  await app.listen(port);

  logger.log(`🐟 FishCash API running on http://localhost:${port}`);
  logger.log(`🌍 Environment: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}`);
}
bootstrap();
