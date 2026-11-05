from typing import Optional

from pydantic import BaseModel, EmailStr, model_validator

from app.common.emails import Email
from app.auth.models import Role
from app.common.timeutils import UTCDateTime
from app.common.validation import (
    FullName,
    InstitutionalEmail,
    Matricule,
    StrongPassword,
    check_matricule_for_role,
)
from app.courses.schemas import DepartmentOut


class AdminUserOut(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone_number: Optional[str]
    matricule_number: Optional[str]
    role: Role
    department: Optional[DepartmentOut]
    is_active: bool = True
    pending_activation: bool = False
    created_at: Optional[UTCDateTime] = None
    last_login_at: Optional[UTCDateTime] = None

    class Config:
        from_attributes = True


class AdminUserCreate(BaseModel):
    """Without a password the account is created pending activation: the
    owner sets a password via student activation / lecturer registration."""

    full_name: FullName
    email: InstitutionalEmail
    role: Role = Role.student
    phone_number: Optional[str] = None
    matricule_number: Matricule = None
    department_id: Optional[int] = None
    password: Optional[StrongPassword] = None

    @model_validator(mode="after")
    def _matricule_format(self):
        check_matricule_for_role(self.matricule_number, self.role)
        return self


class AdminUserUpdate(BaseModel):
    """The matricule format depends on the user's role and the email domain is
    only enforced when the email changes; the router checks both."""

    full_name: Optional[FullName] = None
    email: Optional[Email] = None
    phone_number: Optional[str] = None
    matricule_number: Matricule = None
    department_id: Optional[int] = None


class UserStatusUpdate(BaseModel):
    is_active: bool


class AssignDepartment(BaseModel):
    department_id: int


class TeachingHoursRow(BaseModel):
    lecturer_id: int
    full_name: str
    sessions_count: int
    total_hours: float


class AttendanceHoursRow(BaseModel):
    profile_id: int
    full_name: str
    matricule_number: Optional[str]
    role: Role
    sessions_attended: int
    total_hours: float
