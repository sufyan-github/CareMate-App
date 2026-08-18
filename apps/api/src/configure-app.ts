import { ValidationPipe, type INestApplication } from "@nestjs/common";

import { OperationalMetricsInterceptor } from "./observability/operational-metrics.interceptor.js";
import { requestContext } from "./observability/request-context.js";

export function configureApp(app: INestApplication): void {
  const basePath = process.env.API_BASE_PATH ?? "/api/v1";

  app.setGlobalPrefix(basePath);
  app.use(requestContext);
  app.useGlobalInterceptors(new OperationalMetricsInterceptor());
  app.useGlobalPipes(
    new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    }),
  );
}
