"""
Receipt parsing utilities for extracting structured data from OCR text.
"""
import re
from datetime import datetime, date
from typing import Optional, Dict, List, Tuple


# Date patterns - common receipt date formats
DATE_PATTERNS = [
    re.compile(r"(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})"),  # MM/DD/YYYY or MM-DD-YYYY
    re.compile(r"(\d{4})[/-](\d{1,2})[/-](\d{1,2})"),  # YYYY/MM/DD
    re.compile(r"([A-Za-z]{3})\s+(\d{1,2}),?\s+(\d{4})"),  # Jan 15, 2024
    re.compile(r"(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})"),  # 15 Jan 2024
]

# Total patterns - prioritize larger amounts near end of receipt
TOTAL_PATTERNS = [
    re.compile(r"total\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"amount due\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"grand total\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"balance\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
]

# Tax patterns
TAX_PATTERNS = [
    re.compile(r"tax\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"sales tax\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"tax amount\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
]

# Tip patterns
TIP_PATTERNS = [
    re.compile(r"tip\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"gratuity\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
]

# Subtotal patterns (to help identify where line items end)
SUBTOTAL_PATTERNS = [
    re.compile(r"subtotal\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
    re.compile(r"sub-total\s*[:\-]?\s*\$?\s*([0-9]+[\.,][0-9]{2})", re.I),
]

# Line item patterns - look for price at end of line
LINE_ITEM_PATTERN = re.compile(r"^(.+?)\s+\$?\s*([0-9]+[\.,][0-9]{2})\s*$", re.MULTILINE)


def parse_amount(amount_str: str) -> Optional[int]:
    """Convert amount string to cents (integer)."""
    try:
        cleaned = amount_str.replace(",", "").replace("$", "").strip()
        return int(round(float(cleaned) * 100))
    except (ValueError, AttributeError):
        return None


def parse_date(text_blob: str) -> Optional[date]:
    """Extract date from receipt text. Returns None if not found."""
    lines = text_blob.split("\n")
    
    # Check first 10 lines for date (usually at top)
    for line in lines[:10]:
        for pattern in DATE_PATTERNS:
            match = pattern.search(line)
            if match:
                try:
                    groups = match.groups()
                    if len(groups) == 3:
                        # Handle different formats
                        if pattern == DATE_PATTERNS[0] or pattern == DATE_PATTERNS[1]:  # Numeric dates
                            if len(groups[2]) == 4:  # YYYY format
                                if int(groups[0]) > 12:  # YYYY/MM/DD
                                    year, month, day = int(groups[0]), int(groups[1]), int(groups[2])
                                else:  # MM/DD/YYYY
                                    month, day, year = int(groups[0]), int(groups[1]), int(groups[2])
                            else:  # YY format
                                month, day, year = int(groups[0]), int(groups[1]), int(groups[2])
                                year = 2000 + year if year < 100 else year
                            return date(year, month, day)
                        elif pattern == DATE_PATTERNS[2]:  # "Jan 15, 2024"
                            month_names = {
                                "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
                                "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12
                            }
                            month = month_names.get(groups[0].lower()[:3])
                            if month:
                                return date(int(groups[2]), month, int(groups[1]))
                        elif pattern == DATE_PATTERNS[3]:  # "15 Jan 2024"
                            month_names = {
                                "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
                                "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12
                            }
                            month = month_names.get(groups[1].lower()[:3])
                            if month:
                                return date(int(groups[2]), month, int(groups[0]))
                except (ValueError, IndexError):
                    continue
    
    # Fallback: check entire text
    for pattern in DATE_PATTERNS:
        match = pattern.search(text_blob)
        if match:
            try:
                groups = match.groups()
                if len(groups) == 3:
                    if len(groups[2]) == 4:
                        if int(groups[0]) > 12:
                            year, month, day = int(groups[0]), int(groups[1]), int(groups[2])
                        else:
                            month, day, year = int(groups[0]), int(groups[1]), int(groups[2])
                    else:
                        month, day, year = int(groups[0]), int(groups[1]), int(groups[2])
                        year = 2000 + year if year < 100 else year
                    return date(year, month, day)
            except (ValueError, IndexError):
                continue
    
    return None


def parse_merchant(text_blob: str) -> Optional[str]:
    """Extract merchant name from receipt (usually first few lines)."""
    lines = [line.strip() for line in text_blob.split("\n") if line.strip()]
    
    if not lines:
        return None
    
    # Common patterns: merchant name is usually:
    # 1. First non-empty line
    # 2. Or first line that doesn't look like a date/address/phone
    
    # Skip common header patterns
    skip_patterns = [
        re.compile(r"^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"),  # Date
        re.compile(r"^\d{3}[-.]?\d{3}[-.]?\d{4}"),  # Phone
        re.compile(r"^.*@.*\..*$"),  # Email
        re.compile(r"^receipt$", re.I),
        re.compile(r"^thank you", re.I),
    ]
    
    for line in lines[:5]:  # Check first 5 lines
        # Skip if matches skip patterns
        if any(pattern.match(line) for pattern in skip_patterns):
            continue
        
        # Skip if it's all numbers or very short
        if len(line) < 2 or line.replace(" ", "").isdigit():
            continue
        
        # Skip if it's clearly an address (contains common address words)
        address_words = ["street", "st", "avenue", "ave", "road", "rd", "boulevard", "blvd", "drive", "dr"]
        if any(word in line.lower() for word in address_words):
            continue
        
        # Likely merchant name
        # Clean up common prefixes/suffixes
        cleaned = line.strip()
        if cleaned:
            # Remove common receipt prefixes
            cleaned = re.sub(r"^(receipt|invoice|bill)\s*:?\s*", "", cleaned, flags=re.I)
            return cleaned[:100]  # Limit length
    
    return None


def parse_total(text_blob: str) -> Optional[int]:
    """Extract total amount from receipt text."""
    # Try to find total near the end (last 20 lines)
    lines = text_blob.split("\n")
    search_text = "\n".join(lines[-20:])
    
    # Try patterns in order of specificity
    for pattern in TOTAL_PATTERNS:
        matches = list(pattern.finditer(search_text))
        if matches:
            # Take the last match (most likely the final total)
            match = matches[-1]
            amount = parse_amount(match.group(1))
            if amount:
                return amount
    
    # Fallback: search entire text
    for pattern in TOTAL_PATTERNS:
        matches = list(pattern.finditer(text_blob))
        if matches:
            match = matches[-1]
            amount = parse_amount(match.group(1))
            if amount:
                return amount
    
    return None


def parse_tax(text_blob: str) -> Optional[int]:
    """Extract tax amount from receipt text."""
    lines = text_blob.split("\n")
    search_text = "\n".join(lines[-15:])  # Tax usually near bottom
    
    for pattern in TAX_PATTERNS:
        match = pattern.search(search_text)
        if match:
            amount = parse_amount(match.group(1))
            if amount:
                return amount
    
    return None


def parse_tip(text_blob: str) -> Optional[int]:
    """Extract tip amount from receipt text."""
    lines = text_blob.split("\n")
    search_text = "\n".join(lines[-15:])  # Tip usually near bottom
    
    for pattern in TIP_PATTERNS:
        match = pattern.search(search_text)
        if match:
            amount = parse_amount(match.group(1))
            if amount:
                return amount
    
    return None


def parse_line_items(text_blob: str) -> List[Dict[str, any]]:
    """
    Extract line items from receipt.
    Returns list of dicts with: description, quantity, unit_price_cents, total_cents
    """
    lines = text_blob.split("\n")
    items = []
    
    # Find where line items start and end
    # Usually between merchant header and subtotal/tax section
    start_idx = 0
    end_idx = len(lines)
    
    # Find subtotal to mark end of items
    for i, line in enumerate(lines):
        if any(pattern.search(line) for pattern in SUBTOTAL_PATTERNS):
            end_idx = i
            break
        if any(pattern.search(line) for pattern in TAX_PATTERNS):
            end_idx = i
            break
    
    # Extract items from middle section
    item_lines = lines[start_idx:end_idx]
    
    for line in item_lines:
        line = line.strip()
        if not line or len(line) < 3:
            continue
        
        # Skip header-like lines
        if any(pattern.search(line) for pattern in TOTAL_PATTERNS + TAX_PATTERNS + TIP_PATTERNS):
            continue
        
        # Try to match line item pattern: description $XX.XX
        match = LINE_ITEM_PATTERN.match(line)
        if match:
            description = match.group(1).strip()
            price_str = match.group(2)
            total_cents = parse_amount(price_str)
            
            if total_cents and description:
                items.append({
                    "description": description[:200],  # Limit length
                    "quantity": None,  # Hard to parse from OCR
                    "unit_price_cents": None,
                    "total_cents": total_cents,
                })
    
    return items


def parse_receipt(text_blob: str) -> Dict[str, any]:
    """
    Parse receipt OCR text and extract structured data.
    
    Returns dict with:
    - merchant: str | None
    - txn_date: date | None
    - total_cents: int | None
    - tax_cents: int | None
    - tip_cents: int | None
    - line_items: List[Dict]
    """
    return {
        "merchant": parse_merchant(text_blob),
        "txn_date": parse_date(text_blob),
        "total_cents": parse_total(text_blob),
        "tax_cents": parse_tax(text_blob),
        "tip_cents": parse_tip(text_blob),
        "line_items": parse_line_items(text_blob),
    }

