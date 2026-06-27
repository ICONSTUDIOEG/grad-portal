#!/usr/bin/env python3
"""Import staff contacts from contactStuff.xlsx into data/contacts.json."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import pandas as pd

SOURCE = Path("/Users/ai-unit/Downloads/contactStuff.xlsx")
OUT = Path(__file__).resolve().parent.parent / "data" / "contacts.json"

# Arabic display names aligned with grad portal
NAME_AR = {
    "سلمي الباروني": "سلمى الباروني",
    "Salma Elbaroni": "سلمى الباروني",
    "Ihab Amin": "إيهاب أمين",
    "Dareen": "دارين",
    "Fayrouz Tarek": "فيروز طارق",
}


def norm_phone(raw: str) -> tuple[str, str]:
    s = re.sub(r"[^\d+]", "", str(raw).strip())
    if s.startswith("+"):
        digits = s
    elif s.startswith("20"):
        digits = "+" + s
    else:
        digits = "+20" + s.lstrip("0")
    display = digits
    if digits.startswith("+20") and len(digits) >= 12:
        display = f"+20 {digits[3:5]} {digits[5:8]} {digits[8:]}"
    return digits, display


def main() -> None:
    if not SOURCE.exists():
        print(f"Source not found: {SOURCE}", file=sys.stderr)
        sys.exit(1)

    df = pd.read_excel(SOURCE, header=None)
    staff = []
    for _, row in df.iterrows():
        name_raw = str(row.iloc[0]).strip()
        phone_raw = row.iloc[1]
        email = str(row.iloc[2]).strip() if pd.notna(row.iloc[2]) else ""
        phone, _ = norm_phone(phone_raw)
        phone_display = str(phone_raw).strip() if pd.notna(phone_raw) else phone
        staff.append(
            {
                "name": NAME_AR.get(name_raw, name_raw),
                "nameSource": name_raw,
                "phone": phone,
                "phoneDisplay": phone_display,
                "email": email,
                "role": "لجنة الإشراف على مشروعات التخرج",
            }
        )

    payload = {
        "title": "تواصل فريق اللجنة",
        "subtitle": "للاستفسار والإشراف على مراحل ما بعد الإنتاج",
        "staff": staff,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {OUT} ({len(staff)} contacts)")


if __name__ == "__main__":
    main()
