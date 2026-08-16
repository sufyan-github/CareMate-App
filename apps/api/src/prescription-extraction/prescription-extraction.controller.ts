import {
  BadRequestException,
  Body,
  Controller,
  Param,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { ExtractPrescriptionDto } from "./prescription-extraction.dto.js";
import { PrescriptionExtractionService } from "./prescription-extraction.service.js";

type UploadedPrescription = {
  buffer: Buffer;
  mimetype: string;
  size: number;
};

@Controller("patient-profiles/:profileId/prescription-extractions")
@UseGuards(AccessSessionGuard)
export class PrescriptionExtractionController {
  constructor(private readonly service: PrescriptionExtractionService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor("image", {
      fileFilter: (_request, file, callback) => {
        const allowed = ["image/jpeg", "image/png", "image/webp"].includes(
          file.mimetype,
        );
        callback(
          allowed
            ? null
            : new BadRequestException(
                "Use a JPEG, PNG, or WebP prescription image.",
              ),
          allowed,
        );
      },
      limits: { fileSize: 6 * 1024 * 1024, files: 1 },
    }),
  )
  extract(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @UploadedFile() file: UploadedPrescription | undefined,
    @Body() input: ExtractPrescriptionDto,
  ) {
    if (!file) {
      throw new BadRequestException("Choose a prescription image.");
    }
    if (!this.hasValidImageSignature(file)) {
      throw new BadRequestException(
        "The uploaded file does not match its JPEG, PNG, or WebP image type.",
      );
    }
    return this.service.extract(
      request.auth.userId,
      profileId,
      file,
      input.localOcrText,
    );
  }

  private hasValidImageSignature(file: UploadedPrescription): boolean {
    const bytes = file.buffer;
    if (file.mimetype === "image/jpeg") {
      return (
        bytes.length >= 3 &&
        bytes[0] === 0xff &&
        bytes[1] === 0xd8 &&
        bytes[2] === 0xff
      );
    }
    if (file.mimetype === "image/png") {
      return (
        bytes.length >= 8 &&
        bytes
          .subarray(0, 8)
          .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
      );
    }
    return (
      bytes.length >= 12 &&
      bytes.subarray(0, 4).toString("ascii") === "RIFF" &&
      bytes.subarray(8, 12).toString("ascii") === "WEBP"
    );
  }
}
