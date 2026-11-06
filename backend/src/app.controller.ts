import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  getHealth() {
    return {
      status: 'healthy',
      application: 'VEGAH DevOps Job Manager',
      timestamp: new Date().toISOString(),
    };
  }
}
