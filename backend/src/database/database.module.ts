import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';

export const DATABASE_POOL = 'DATABASE_POOL';

@Global()
@Module({
  providers: [
    {
      provide: DATABASE_POOL,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const pool = new Pool({
          host: config.get<string>('DB_HOST', 'localhost'),
          port: config.get<number>('DB_PORT', 5432),
          user: config.get<string>('DB_USER', 'vegah'),
          password: config.get<string>('DB_PASSWORD'),
          database: config.get<string>('DB_NAME', 'vegah_db'),
        });

        pool.on('error', (error) => {
          console.error('Unexpected PostgreSQL error:', error);
        });

        return pool;
      },
    },
  ],
  exports: [DATABASE_POOL],
})
export class DatabaseModule {}
