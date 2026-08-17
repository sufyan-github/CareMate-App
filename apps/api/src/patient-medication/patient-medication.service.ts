import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { AuthError } from "../auth/auth-error.js";
import { DatabaseService } from "../database/database.service.js";
import type {
  CreateMedicationDto,
  CreatePatientProfileDto,
  UpdateMedicationDto,
  UpdatePatientProfileDto,
} from "./patient-medication.dto.js";

@Injectable()
export class PatientMedicationService {
  constructor(private readonly database: DatabaseService) {}

  async createProfile(userId: string, input: CreatePatientProfileDto) {
    this.validateTimezone(input.timezone);
    const existing = await this.database.patientProfile.findUnique({
      where: { ownerUserId: userId },
    });
    if (existing) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "PATIENT_PROFILE_EXISTS",
        "This account already has a patient profile.",
      );
    }
    const profile = await this.database.patientProfile.create({
      data: { id: ulid(), ownerUserId: userId, ...input },
    });
    return this.response(this.profileView(profile));
  }

  async listProfiles(userId: string) {
    const ownedProfiles = await this.database.patientProfile.findMany({
      orderBy: { createdAt: "asc" },
      where: { ownerUserId: userId },
    });
    const sharedInvitations = await this.database.careInvitation.findMany({
      include: { patientProfile: true },
      orderBy: { acceptedAt: "asc" },
      where: { acceptedByUserId: userId, status: "ACCEPTED" },
    });
    const sharedProfiles = sharedInvitations
      .filter((invitation) => this.canViewPlan(invitation.permissionsJson))
      .map((invitation) =>
        this.profileView(
          invitation.patientProfile,
          "CAREGIVER",
          JSON.parse(invitation.permissionsJson) as Record<string, boolean>,
        ),
      );
    return this.response([
      ...ownedProfiles.map((profile) => this.profileView(profile)),
      ...sharedProfiles,
    ]);
  }

  async getProfile(userId: string, profileId: string) {
    const access = await this.readableProfile(userId, profileId);
    return this.response(
      this.profileView(access.profile, access.role, access.permissions),
    );
  }

  async updateProfile(
    userId: string,
    profileId: string,
    input: UpdatePatientProfileDto,
  ) {
    await this.ownedProfile(userId, profileId);
    if (input.timezone) this.validateTimezone(input.timezone);
    const { expectedVersion, ...changes } = input;
    const updated = await this.database.patientProfile.updateMany({
      data: { ...changes, version: { increment: 1 } },
      where: { id: profileId, ownerUserId: userId, version: expectedVersion },
    });
    if (updated.count !== 1) this.versionConflict();
    return this.getProfile(userId, profileId);
  }

  async createMedication(
    userId: string,
    profileId: string,
    input: CreateMedicationDto,
  ) {
    await this.ownedProfile(userId, profileId);
    const { instructions, ...medication } = input;
    const created = await this.database.medication.create({
      data: {
        ...medication,
        id: ulid(),
        instructions: { create: { id: ulid(), ...instructions } },
        patientProfileId: profileId,
      },
      include: { instructions: true },
    });
    return this.response(this.medicationView(created));
  }

  async listMedications(userId: string, profileId: string) {
    await this.readableProfile(userId, profileId);
    const medications = await this.database.medication.findMany({
      include: {
        instructions: true,
        schedules: {
          orderBy: { updatedAt: "desc" },
          take: 1,
          where: { status: { in: ["ACTIVE", "PAUSED"] } },
        },
      },
      orderBy: { createdAt: "desc" },
      where: { patientProfileId: profileId },
    });
    return this.response(
      medications.map((medication) => this.medicationView(medication)),
    );
  }

  async getMedication(userId: string, medicationId: string) {
    const medication = await this.readableMedication(userId, medicationId);
    return this.response(this.medicationView(medication));
  }

  async updateMedication(
    userId: string,
    medicationId: string,
    input: UpdateMedicationDto,
  ) {
    await this.ownedMedication(userId, medicationId);
    const { expectedVersion, instructions, ...changes } = input;
    await this.database.$transaction(async (transaction) => {
      const updated = await transaction.medication.updateMany({
        data: { ...changes, version: { increment: 1 } },
        where: { id: medicationId, version: expectedVersion },
      });
      if (updated.count !== 1) this.versionConflict();
      if (instructions) {
        await transaction.doseInstruction.upsert({
          create: { id: ulid(), medicationId, ...instructions },
          update: instructions,
          where: { medicationId },
        });
      }
    });
    return this.getMedication(userId, medicationId);
  }

  private ownedProfile(userId: string, profileId: string) {
    return this.database.patientProfile
      .findFirst({ where: { id: profileId, ownerUserId: userId } })
      .then((profile) => profile ?? this.notFound());
  }

  private ownedMedication(userId: string, medicationId: string) {
    return this.database.medication
      .findFirst({
        include: {
          instructions: true,
          schedules: {
            orderBy: { updatedAt: "desc" },
            take: 1,
            where: { status: { in: ["ACTIVE", "PAUSED"] } },
          },
        },
        where: {
          id: medicationId,
          patientProfile: { ownerUserId: userId },
        },
      })
      .then((medication) => medication ?? this.notFound());
  }

  private async readableProfile(userId: string, profileId: string) {
    const profile = await this.database.patientProfile.findUnique({
      where: { id: profileId },
    });
    if (!profile) this.notFound();
    if (profile.ownerUserId === userId) {
      return {
        permissions: null,
        profile,
        role: "OWNER" as const,
      };
    }
    const invitation = await this.database.careInvitation.findFirst({
      where: {
        acceptedByUserId: userId,
        patientProfileId: profileId,
        status: "ACCEPTED",
      },
    });
    if (!invitation || !this.canViewPlan(invitation.permissionsJson)) {
      this.notFound();
    }
    return {
      permissions: JSON.parse(invitation.permissionsJson) as Record<
        string,
        boolean
      >,
      profile,
      role: "CAREGIVER" as const,
    };
  }

  private async readableMedication(userId: string, medicationId: string) {
    const medication = await this.database.medication.findUnique({
      include: {
        instructions: true,
        schedules: {
          orderBy: { updatedAt: "desc" },
          take: 1,
          where: { status: { in: ["ACTIVE", "PAUSED"] } },
        },
      },
      where: { id: medicationId },
    });
    if (!medication) this.notFound();
    await this.readableProfile(userId, medication.patientProfileId);
    return medication;
  }

  private profileView(
    profile: {
      createdAt: Date;
      displayName: string;
      id: string;
      status: string;
      timezone: string;
      updatedAt: Date;
      version: number;
    },
    accessRole: "OWNER" | "CAREGIVER" = "OWNER",
    permissions: Record<string, boolean> | null = null,
  ) {
    return {
      accessRole,
      canManage: accessRole === "OWNER",
      createdAt: profile.createdAt.toISOString(),
      displayName: profile.displayName,
      id: profile.id,
      permissions,
      status: profile.status,
      timezone: profile.timezone,
      updatedAt: profile.updatedAt.toISOString(),
      version: profile.version,
    };
  }

  private canViewPlan(permissionsJson: string): boolean {
    try {
      const permissions = JSON.parse(permissionsJson) as Record<
        string,
        unknown
      >;
      return permissions.canViewMedicationPlan === true;
    } catch {
      return false;
    }
  }

  private medicationView(medication: {
    createdAt: Date;
    displayName: string;
    form: string;
    id: string;
    instructions: {
      mealRelation: string;
      quantityUnit: string;
      quantityValue: number;
      route: string;
      sourceText: string | null;
    } | null;
    normalizedName: string | null;
    notes: string | null;
    patientProfileId: string;
    status: string;
    strengthUnit: string | null;
    strengthValue: number | null;
    schedules?: Array<{
      daysOfWeekJson: string;
      endDate: string | null;
      excludedDatesJson: string;
      generatedThroughDate: string;
      generationHorizonDays: number;
      id: string;
      revision: number;
      startDate: string;
      status: string;
      timesJson: string;
      timezone: string;
      version: number;
    }>;
    updatedAt: Date;
    version: number;
  }) {
    return {
      activeSchedule: medication.schedules?.[0]
        ? {
            daysOfWeek: JSON.parse(
              medication.schedules[0].daysOfWeekJson,
            ) as number[],
            endDate: medication.schedules[0].endDate,
            excludedDates: JSON.parse(
              medication.schedules[0].excludedDatesJson,
            ) as string[],
            generatedThroughDate: medication.schedules[0].generatedThroughDate,
            generationHorizonDays:
              medication.schedules[0].generationHorizonDays,
            id: medication.schedules[0].id,
            revision: medication.schedules[0].revision,
            startDate: medication.schedules[0].startDate,
            status: medication.schedules[0].status,
            times: JSON.parse(medication.schedules[0].timesJson) as string[],
            timezone: medication.schedules[0].timezone,
            version: medication.schedules[0].version,
          }
        : null,
      createdAt: medication.createdAt.toISOString(),
      displayName: medication.displayName,
      form: medication.form,
      id: medication.id,
      instructions: medication.instructions,
      normalizedName: medication.normalizedName,
      notes: medication.notes,
      patientProfileId: medication.patientProfileId,
      status: medication.status,
      strengthUnit: medication.strengthUnit,
      strengthValue: medication.strengthValue,
      updatedAt: medication.updatedAt.toISOString(),
      version: medication.version,
    };
  }

  private validateTimezone(timezone: string): void {
    try {
      Intl.DateTimeFormat("en", { timeZone: timezone }).format();
    } catch {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "TIMEZONE_INVALID",
        "Choose a valid timezone.",
      );
    }
  }

  private notFound(): never {
    throw new AuthError(
      HttpStatus.NOT_FOUND,
      "RESOURCE_NOT_FOUND",
      "The requested item was not found.",
    );
  }

  private versionConflict(): never {
    throw new AuthError(
      HttpStatus.CONFLICT,
      "VERSION_CONFLICT",
      "This item changed on another device. Refresh and try again.",
    );
  }

  private response(data: unknown) {
    return { data, meta: { requestId: `req_${ulid()}` } };
  }
}
