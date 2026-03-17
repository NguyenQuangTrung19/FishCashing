import { IsEmail, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'user@fishcash.vn' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Nguyễn Văn A' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'securepassword123', minLength: 6 })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'Cửa hàng cá tươi', required: false })
  @IsOptional()
  @IsString()
  storeName?: string;
}

export class LoginDto {
  @ApiProperty({ example: 'user@fishcash.vn' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'securepassword123' })
  @IsString()
  @IsNotEmpty()
  password: string;
}

export class AuthResponseDto {
  @ApiProperty()
  accessToken: string;

  @ApiProperty()
  user: {
    id: string;
    email: string;
    name: string;
    storeName: string;
  };
}

/// DTO for quick store setup — no email/password needed.
/// User just enters store info and starts using the app.
export class SetupStoreDto {
  @ApiProperty({ example: 'Cá Tươi Sài Gòn' })
  @IsString()
  @IsNotEmpty()
  storeName: string;

  @ApiProperty({ example: '0901234567', required: false })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({ example: '123 Nguyễn Huệ, Q1, TP.HCM', required: false })
  @IsOptional()
  @IsString()
  address?: string;
}

export class SetupResponseDto {
  @ApiProperty({ description: 'API key (JWT) for all subsequent requests' })
  apiKey: string;

  @ApiProperty({ description: 'Unique store identifier' })
  storeId: string;

  @ApiProperty({ description: 'Store name as provided' })
  storeName: string;
}

