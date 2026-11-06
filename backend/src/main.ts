import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors();

  const port = Number(process.env.PORT || 3001);

  await app.listen(port, '0.0.0.0');

  console.log(`VEGAH backend running on port ${port}`);
}

bootstrap();
