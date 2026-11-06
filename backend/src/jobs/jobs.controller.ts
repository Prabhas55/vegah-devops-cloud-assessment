import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  BadRequestException,
} from '@nestjs/common';

import { JobsService } from './jobs.service.js';

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Post()
  async createJob(@Body() body: { task: string }) {
    if (
      typeof body.task !== 'string' ||
      !body.task.trim() ||
      body.task.length > 500
    ) {
      throw new BadRequestException(
        'Task must contain between 1 and 500 characters',
      );
    }

    return this.jobsService.createJob(body.task.trim());
  }

  @Get()
  async getJobs() {
    return this.jobsService.getJobs();
  }

  @Get(':id')
  async getJob(@Param('id') id: string) {
    return this.jobsService.getJob(id);
  }
}
