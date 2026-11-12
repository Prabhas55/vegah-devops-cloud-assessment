const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const { Worker } = require('bullmq');
const { Pool } = require('pg');

const connection = {
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: Number(process.env.REDIS_PORT || 6379),
  // Optional: required once Redis is exposed for cross-region replication.
  password: process.env.REDIS_PASSWORD || undefined,
};

const pool = new Pool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

const worker = new Worker(
  'job-queue',
  async (job) => {
    const { taskId, task } = job.data;

    console.log(`Processing job ${taskId}: ${task}`);

    try {
      await pool.query(
        `UPDATE jobs SET status = $1, updated_at = NOW() WHERE id = $2`,
        ['PROCESSING', taskId],
      );

      // Simulate background processing.
      await new Promise((resolve) => setTimeout(resolve, 5000));

      const result = `Successfully processed task: ${task}`;

      await pool.query(
        `UPDATE jobs SET status = $1, result = $2, updated_at = NOW() WHERE id = $3`,
        ['COMPLETED', result, taskId],
      );

      console.log(`Job ${taskId} completed`);

      return { taskId, result };
    } catch (error) {
      await pool.query(
        `UPDATE jobs SET status = $1, result = $2, updated_at = NOW() WHERE id = $3`,
        ['FAILED', error.message, taskId],
      );

      console.error(`Job ${taskId} failed:`, error.message);
      throw error;
    }
  },
  {
    connection,
    concurrency: 5,
  },
);

worker.on('completed', (job) => {
  console.log(`Queue job ${job.id} completed`);
});

worker.on('failed', (job, error) => {
  console.error(`Queue job ${job?.id} failed:`, error.message);
});

worker.on('error', (error) => {
  console.error('Worker error:', error);
});

console.log('VEGAH background worker started and listening for jobs');

async function shutdown() {
  console.log('Shutting down worker...');
  await worker.close();
  await pool.end();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
