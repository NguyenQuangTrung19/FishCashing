import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

import { User } from './entities/user.entity';
import { StoreInfo } from '../store/entities/store-info.entity';
import {
  RegisterDto,
  LoginDto,
  AuthResponseDto,
  SetupStoreDto,
  SetupResponseDto,
} from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(StoreInfo)
    private readonly storeInfoRepository: Repository<StoreInfo>,
    private readonly jwtService: JwtService,
  ) {}

  /// Quick store setup — no email/password needed.
  /// Creates a hidden user + store, returns a long-lived API key.
  async setupStore(dto: SetupStoreDto): Promise<SetupResponseDto> {
    const storeId = uuidv4();
    const autoEmail = `store-${storeId}@fishcash.local`;

    // Create hidden user (no real email/password)
    const randomPassword = uuidv4();
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(randomPassword, salt);

    const user = this.userRepository.create({
      email: autoEmail,
      name: dto.storeName,
      passwordHash,
      storeName: dto.storeName,
    });
    await this.userRepository.save(user);

    // Create store info
    const storeInfo = this.storeInfoRepository.create({
      id: storeId,
      userId: user.id,
      name: dto.storeName,
      phone: dto.phone || '',
      address: dto.address || '',
    });
    await this.storeInfoRepository.save(storeInfo);

    // Generate long-lived API key (365 days)
    const apiKey = this.jwtService.sign(
      { sub: user.id, email: autoEmail, storeId },
      { expiresIn: '365d' },
    );

    return {
      apiKey,
      storeId,
      storeName: dto.storeName,
    };
  }

  /// Register a new user account.
  async register(dto: RegisterDto): Promise<AuthResponseDto> {
    // Check if email already exists
    const existing = await this.userRepository.findOne({
      where: { email: dto.email },
    });
    if (existing) {
      throw new ConflictException('Email đã được đăng ký');
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    // Create user
    const user = this.userRepository.create({
      email: dto.email,
      name: dto.name,
      passwordHash,
      storeName: dto.storeName || '',
    });
    await this.userRepository.save(user);

    // Generate JWT
    const token = this.generateToken(user);

    return {
      accessToken: token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        storeName: user.storeName,
      },
    };
  }

  /// Login with email and password.
  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.userRepository.findOne({
      where: { email: dto.email },
    });

    if (!user) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Tài khoản đã bị vô hiệu hóa');
    }

    const token = this.generateToken(user);

    return {
      accessToken: token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        storeName: user.storeName,
      },
    };
  }

  /// Get user profile by ID.
  async getProfile(userId: string): Promise<Omit<User, 'passwordHash'>> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const { passwordHash, ...result } = user;
    return result;
  }

  private generateToken(user: User): string {
    const payload = { sub: user.id, email: user.email };
    return this.jwtService.sign(payload);
  }
}

