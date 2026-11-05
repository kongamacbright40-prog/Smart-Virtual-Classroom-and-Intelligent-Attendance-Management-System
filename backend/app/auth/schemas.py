from typing import Optional

from pydantic import BaseModel, EmailStr, Field, model_validator

from app.common.emails import Email

from app.auth.models import Role
from app.common.timeutils import UTCDateTime
from app.common.validation import (
    MIN_PASSWORD_LENGTH,
    FullName,
    InstitutionalEmail,
    Matricule,
    StrongPassword,
    check_matricule_for_role,
)
from app.courses.schemas import DepartmentOut

__all__ = ["MIN_PASSWORD_LENGTH"]


class ProfileCreate(BaseModel):
    full_name: FullName
    email: InstitutionalEmail
    phone_number: Optional[str] = None
    matricule_number: Matricule = None
    password: StrongPassword
    role: Role = Role.student
    department_id: Optional[int] = None
    # Required to register as admin once an admin exists (ADMIN_REGISTRATION_CODE).
    admin_code: Optional[str] = None

    @model_validator(mode="after")
    def matricule_required_for_students_and_lecturers(self):
        if self.role in (Role.student, Role.lecturer) and not self.matricule_number:
            raise ValueError("matricule_number is required for students and lecturers")
        check_matricule_for_role(self.matricule_number, self.role)
        return self



class ProfileOut(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone_number: Optional[str]
    matricule_number: Optional[str]
    role: Role
    department_id: Optional[int] = None
    department: Optional[DepartmentOut] = None
    is_active: bool = True
    pending_activation: bool = False
    created_at: Optional[UTCDateTime] = None
    last_login_at: Optional[UTCDateTime] = None

    class Config:
        from_attributes = True


class ProfileUpdate(BaseModel):
    full_name: Optional[FullName] = None
    phone_number: Optional[str] = None


class LoginRequest(BaseModel):
    """Sign in with an email or a matricule / admin ID (``identifier``).
    ``email`` is still accepted for older app versions."""

    identifier: Optional[str] = None
    email: Optional[str] = None
    password: str = Field(min_length=1)

    @model_validator(mode="after")
    def _identifier(self):
        value = (self.identifier or self.email or "").strip()
        if not value:
            raise ValueError("Enter your email or matricule")
        self.identifier = value.lower() if "@" in value else value.upper()
        return self


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: StrongPassword


class PasswordResetRequest(BaseModel):
    email: Email


class PasswordResetVerify(BaseModel):
    email: Email
    code: str


class PasswordResetConfirm(BaseModel):
    email: Email
    code: str
    new_password: StrongPassword
