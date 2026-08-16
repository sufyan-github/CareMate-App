import { ValidationPipe, type INestApplication } from "@nestjs/common";

export function configureApp(app: INestApplication): void {
  const basePath = process.env.API_BASE_PATH ?? "/api/v1";

  app.setGlobalPrefix(basePath);
  app.useGlobalPipes(
    new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    }),
  );
}
