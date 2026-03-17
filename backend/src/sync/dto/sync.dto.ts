import { IsString, IsArray, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class SyncEntityDto {
  @ApiProperty()
  @IsString()
  table: string;

  @ApiProperty({ description: 'Array of records to push' })
  @IsArray()
  records: any[];
}

export class SyncPushDto {
  @ApiProperty({ type: [SyncEntityDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncEntityDto)
  changes: SyncEntityDto[];

  @ApiProperty({
    description: 'Client last sync timestamp (ISO string)',
    required: false,
  })
  @IsOptional()
  @IsString()
  lastSyncAt?: string;
}

export class SyncPullQueryDto {
  @ApiProperty({
    description: 'Last sync timestamp (ISO string)',
    required: false,
  })
  @IsOptional()
  @IsString()
  since?: string;
}
