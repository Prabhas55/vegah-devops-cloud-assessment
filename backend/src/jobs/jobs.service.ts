import {
  Injectable,
  Inject,
  NotFoundException,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Pool } from 'pg';
import { randomUUID } from 'crypto';
import { DATABASE_POOL } from '../database/database.module.js';

@Injectable()
export class JobsService {
  constructor(
    @Inject(DATABASE_POOL)
    private readonly db: Pool,

    @InjectQueue('job-queue')
    private readonly jobQueue: Queue,
  ) {}

  async createJob(task: string) {
    const id = randomUUID();

    // First persist the job in PostgreSQL.
    await this.db.query(
      `INSERT INTO jobs (id, task, status)
       VALUES ($1, $2, $3)`,
      [id, task, 'WAITING'],
    );

    try {
      // Then add the job to Redis through BullMQ.
      await this.jobQueue.add(
        'process-task',
        {
          taskId: id,
          task,
        },
        {
          attempts: 2,
          backoff: {
            type: 'exponential',
            delay: 2000,
          },
          removeOnComplete: 100,
          removeOnFail: 100,
        },
      );
    } catch (error) {
      await this.db.query(
        `UPDATE jobs SET status = $1, updated_at = NOW()
         WHERE id = $2`,
        ['FAILED', id],
      );

      throw error;
    }

    return {
      id,
      task,
      status: 'WAITING',
      message: 'Job submitted successfully',
    };
  }

  async getJobs() {
    const result = await this.db.query(
      `SELECT * FROM jobs ORDER BY created_at DESC`,
    );

    return result.rows;
  }

  async getJob(id: string) {
    const result = await this.db.query(
      `SELECT * FROM jobs WHERE id = $1`,
      [id],
    );

    if (result.rows.length === 0) {
      throw new NotFoundException('Job not found');
    }

    return result.rows[0];
  }
}
