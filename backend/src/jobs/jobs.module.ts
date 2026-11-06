import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { JobsController } from './jobs.controller.js';
import { JobsService } from './jobs.service.js';
import { DatabaseModule } from '../database/database.module.js';

@Module({
  imports: [
    DatabaseModule,
    BullModule.registerQueue({
      name: 'job-queue',
    }),
  ],
  controllers: [JobsController],
  providers: [JobsService],
})
export class JobsModule {}
