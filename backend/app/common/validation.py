"""Input rules shared by registration, admin user management and profile
updates. They mirror the app's ``Validators`` (lib/core/utils/validators.dart).
"""

import re
from typing import Annotated, Optional

from pydantic import AfterValidator, BeforeValidator

from app.common.emails import Email
from app.config import settings

# Unicode letters: "\w" minus digits and underscore.
_LETTERS = r"[^\W\d_]"
# A name word: letters, optionally joined by a hyphen or apostrophe
# (e.g. "Jean-Paul", "O'Neil", "Ngô").
_NAME_WORD = re.compile(rf"^{_LETTERS}+(?:['’-]{_LETTERS}+)*$")
# Student / lecturer matricule: ICTU + 4-digit year + 4 digits (ICTU20233736).
MATRICULE_RE = re.compile(r"^ICTU(?:19|20)\d{2}\d{4}$")
# Administrator ID, e.g. ADM-001 or ADM-0001-IT.
ADMIN_ID_RE = re.compile(r"^[A-Z]{3}-\d{3,6}(?:-[A-Z]{2,5})?$")

MIN_PASSWORD_LENGTH = 8
_SPECIAL = re.compile(r"[^A-Za-z0-9\s]")


def clean_full_name(value: str) -> str:
    """At least two words of letters (2+ letters each); spaces collapsed."""
    name = " ".join((value or "").split())
    words = name.split(" ") if name else []
    if len(words) < 2:
        raise ValueError("Enter at least two names (first and last name)")
    for word in words:
        if not _NAME_WORD.match(word):
            raise ValueError("Names may only contain letters, hyphens and apostrophes")
        if len(re.sub(r"['’-]", "", word)) < 2:
            raise ValueError("Each name must have at least 2 letters")
    return name


def allowed_email_domains() -> list[str]:
    return [
        d.strip().lower().lstrip("@")
        for d in settings.allowed_email_domains.split(",")
        if d.strip()
    ]


def check_email_domain(email: str) -> str:
    """Rejects emails outside ALLOWED_EMAIL_DOMAINS (empty setting = any)."""
    domains = allowed_email_domains()
    if domains and email.rsplit("@", 1)[-1].lower() not in domains:
        raise ValueError("Use your institutional email (" + ", ".join(f"@{d}" for d in domains) + ")")
    return email


def clean_matricule(value: Optional[str]) -> Optional[str]:
    """Upper-cased, trimmed matricule, or None when empty."""
    v = (value or "").strip().upper()
    return v or None


def check_matricule_for_role(matricule: Optional[str], role) -> Optional[str]:
    """Students/lecturers: ICTU + year + 4 digits. Admins: ADM-001 style."""
    if matricule is None:
        return None
    if getattr(role, "value", role) == "admin":
        if not ADMIN_ID_RE.match(matricule):
            raise ValueError("Administrator ID must look like ADM-001")
    elif not MATRICULE_RE.match(matricule):
        raise ValueError("Matricule must look like ICTU20233736 (ICTU + year + 4 digits)")
    return matricule


def check_strong_password(value: str) -> str:
    if (
        len(value) < MIN_PASSWORD_LENGTH
        or not re.search(r"[A-Z]", value)
        or not re.search(r"[a-z]", value)
        or not re.search(r"\d", value)
        or not _SPECIAL.search(value)
    ):
        raise ValueError(
            f"Password needs at least {MIN_PASSWORD_LENGTH} characters with an uppercase "
            "letter, a lowercase letter, a number and a special character"
        )
    return value


FullName = Annotated[str, AfterValidator(clean_full_name)]
StrongPassword = Annotated[str, AfterValidator(check_strong_password)]
Matricule = Annotated[Optional[str], BeforeValidator(clean_matricule)]
InstitutionalEmail = Annotated[Email, AfterValidator(check_email_domain)]
