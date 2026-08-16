import "reflect-metadata";

import { NestFactory } from "@nestjs/core";

import { AppModule } from "./app.module.js";
import { configureApp } from "./configure-app.js";

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  configureApp(app);
  app.enableShutdownHooks();

  await app.listen(Number(process.env.PORT ?? 3000));
}

void bootstrap();
