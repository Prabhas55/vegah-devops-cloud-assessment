import {
  Controller,
  Get,
  Inject,
  ServiceUnavailableException,
} from '@nestjs/common';
import { Pool } from 'pg';
import { DATABASE_POOL } from './database/database.module.js';

@Controller()
export class AppController {
  constructor(
    @Inject(DATABASE_POOL)
    private readonly db: Pool,
  ) {}

  // Used by Docker, CI and the Route 53 health check (via /api/health).
  // Verifies the database is reachable so DNS failover reflects real health.
  @Get('health')
  async getHealth() {
    try {
      await this.db.query('SELECT 1');
    } catch {
      throw new ServiceUnavailableException({
        status: 'unhealthy',
        database: 'down',
        timestamp: new Date().toISOString(),
      });
    }

    return {
      status: 'healthy',
      database: 'up',
      application: 'VEGAH DevOps Job Manager',
      timestamp: new Date().toISOString(),
    };
  }
}
