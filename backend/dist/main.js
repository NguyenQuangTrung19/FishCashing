"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const config_1 = require("@nestjs/config");
const helmet_1 = __importDefault(require("helmet"));
const app_module_1 = require("./app.module");
async function bootstrap() {
    const logger = new common_1.Logger('Bootstrap');
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    const configService = app.get(config_1.ConfigService);
    const isProduction = configService.get('NODE_ENV') === 'production';
    const port = configService.get('PORT', 3000);
    app.use((0, helmet_1.default)());
    const corsOrigin = configService.get('CORS_ORIGIN', '*');
    app.enableCors({
        origin: corsOrigin === '*' ? true : corsOrigin.split(','),
        credentials: true,
    });
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
    }));
    if (!isProduction) {
        const config = new swagger_1.DocumentBuilder()
            .setTitle('FishCash POS API')
            .setDescription('Backend API for FishCash POS — Multi-device sync & backup')
            .setVersion('1.0')
            .addBearerAuth()
            .build();
        const document = swagger_1.SwaggerModule.createDocument(app, config);
        swagger_1.SwaggerModule.setup('api/docs', app, document);
        logger.log('📖 Swagger docs enabled at /api/docs');
    }
    app.enableShutdownHooks();
    await app.listen(port);
    logger.log(`🐟 FishCash API running on http://localhost:${port}`);
    logger.log(`🌍 Environment: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}`);
}
bootstrap();
//# sourceMappingURL=main.js.map