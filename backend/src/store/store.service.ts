import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DeepPartial, FindOptionsWhere } from 'typeorm';
import { StoreInfo } from './entities/store-info.entity';

@Injectable()
export class StoreService {
  constructor(
    @InjectRepository(StoreInfo)
    private readonly repository: Repository<StoreInfo>,
  ) {}

  async getOrCreate(userId: string): Promise<StoreInfo> {
    let info = await this.repository.findOne({
      where: { userId } as FindOptionsWhere<StoreInfo>,
    });
    if (!info) {
      info = this.repository.create({
        id: userId,
        userId,
        name: 'FishCash POS',
      } as DeepPartial<StoreInfo>);
      info = await this.repository.save(info);
    }
    return info;
  }

  async update(userId: string, data: any): Promise<StoreInfo> {
    const info = await this.getOrCreate(userId);
    Object.assign(info, data);
    return this.repository.save(info);
  }
}
