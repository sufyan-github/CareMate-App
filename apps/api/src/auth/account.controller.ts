import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "./access-session.guard.js";
import {
  RequestAccountDeletionDto,
  UpdateAccountPreferencesDto,
} from "./account.dto.js";
import { AccountService } from "./account.service.js";

@Controller("me")
@UseGuards(AccessSessionGuard)
export class AccountController {
  constructor(private readonly account: AccountService) {}

  @Get("preferences")
  getPreferences(@Req() request: AuthenticatedRequest) {
    return this.account.getPreferences(request.auth.userId);
  }

  @Patch("preferences")
  updatePreferences(
    @Req() request: AuthenticatedRequest,
    @Body() input: UpdateAccountPreferencesDto,
  ) {
    return this.account.updatePreferences(request.auth.userId, input);
  }

  @Post("deletion-requests")
  @HttpCode(HttpStatus.ACCEPTED)
  requestDeletion(
    @Req() request: AuthenticatedRequest,
    @Body() input: RequestAccountDeletionDto,
  ) {
    return this.account.requestDeletion(request.auth.userId, input);
  }
}
