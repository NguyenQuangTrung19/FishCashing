import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { AuthService } from './auth.service';
import {
  RegisterDto,
  LoginDto,
  AuthResponseDto,
  SetupStoreDto,
  SetupResponseDto,
} from './dto/auth.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('auth')
@Controller('api/v1/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /// Quick store setup — no email/password needed.
  /// User enters store info and gets an API key.
  @Post('setup')
  @ApiOperation({ summary: 'Quick store setup — no login needed' })
  async setupStore(@Body() dto: SetupStoreDto): Promise<SetupResponseDto> {
    return this.authService.setupStore(dto);
  }

  @Post('register')
  @ApiOperation({ summary: 'Register a new user account' })
  async register(@Body() dto: RegisterDto): Promise<AuthResponseDto> {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  async login(@Body() dto: LoginDto): Promise<AuthResponseDto> {
    return this.authService.login(dto);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user profile' })
  async getProfile(@Request() req) {
    return this.authService.getProfile(req.user.id);
  }
}

