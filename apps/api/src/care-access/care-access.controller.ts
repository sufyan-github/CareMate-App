import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { CreateCareInvitationDto } from "./care-access.dto.js";
import { CareAccessService } from "./care-access.service.js";

@Controller()
@UseGuards(AccessSessionGuard)
export class CareAccessController {
  constructor(private readonly service: CareAccessService) {}

  @Post("patient-profiles/:profileId/care-invitations")
  create(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @Body() input: CreateCareInvitationDto,
  ) {
    return this.service.createInvitation(request.auth.userId, profileId, input);
  }

  @Get("patient-profiles/:profileId/care-invitations")
  list(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
  ) {
    return this.service.listForProfile(request.auth.userId, profileId);
  }

  @Get("care-invitations/incoming")
  incoming(@Req() request: AuthenticatedRequest) {
    return this.service.listIncoming(request.auth.userId);
  }

  @Patch("care-invitations/:invitationId/accept")
  accept(
    @Req() request: AuthenticatedRequest,
    @Param("invitationId") invitationId: string,
  ) {
    return this.service.accept(request.auth.userId, invitationId);
  }

  @Patch("care-invitations/:invitationId/decline")
  decline(
    @Req() request: AuthenticatedRequest,
    @Param("invitationId") invitationId: string,
  ) {
    return this.service.decline(request.auth.userId, invitationId);
  }

  @Patch("care-invitations/:invitationId/revoke")
  revoke(
    @Req() request: AuthenticatedRequest,
    @Param("invitationId") invitationId: string,
  ) {
    return this.service.revoke(request.auth.userId, invitationId);
  }

  @Get("care-invitations/:invitationId/audit")
  audit(
    @Req() request: AuthenticatedRequest,
    @Param("invitationId") invitationId: string,
  ) {
    return this.service.audit(request.auth.userId, invitationId);
  }
}
