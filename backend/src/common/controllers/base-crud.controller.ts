import {
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { BaseCrudService } from '../services/base-crud.service';

/// Generic CRUD controller base class.
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export abstract class BaseCrudController<T extends Record<string, any>> {
  constructor(protected readonly service: BaseCrudService<T>) {}

  @Get()
  async findAll(@Request() req: any) {
    return this.service.findAll(req.user.id);
  }

  @Get(':id')
  async findOne(@Request() req: any, @Param('id') id: string) {
    const entity = await this.service.findOne(req.user.id, id);
    if (!entity) throw new NotFoundException();
    return entity;
  }

  @Post()
  async create(@Request() req: any, @Body() data: any) {
    return this.service.create(req.user.id, data);
  }

  @Put(':id')
  async update(
    @Request() req: any,
    @Param('id') id: string,
    @Body() data: any,
  ) {
    const entity = await this.service.update(req.user.id, id, data);
    if (!entity) throw new NotFoundException();
    return entity;
  }

  @Delete(':id')
  async remove(@Request() req: any, @Param('id') id: string) {
    const result = await this.service.softDelete(req.user.id, id);
    if (!result) throw new NotFoundException();
    return { deleted: true };
  }
}
