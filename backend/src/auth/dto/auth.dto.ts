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
