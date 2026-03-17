import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

/// Logs every HTTP request with method, path, status, and duration.
/// Useful for debugging production issues.
@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    const { method, originalUrl } = req;

    res.on('finish', () => {
      const duration = Date.now() - start;
      const { statusCode } = res;

      // Color-code by status
      if (statusCode >= 400) {
        this.logger.warn(
          `${method} ${originalUrl} ${statusCode} ${duration}ms`,
        );
      } else {
        this.logger.log(`${method} ${originalUrl} ${statusCode} ${duration}ms`);
      }
    });

    next();
  }
}
