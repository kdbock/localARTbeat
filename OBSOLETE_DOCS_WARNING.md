# Obsolete Documentation - DO NOT USE

**Last Updated**: January 23, 2026

The following documentation files are **OBSOLETE** and should not be referenced for the current boost implementation. They contain language and concepts that violate App Store compliance requirements.

---

## ⛔ Obsolete Files

### 1. `ARTIST_BOOST_CONCEPT.md`
**Status**: OUTDATED CONCEPT DOC  
**Issue**: Contains prohibited language including:
- "Supporter" terminology throughout
- "Patron" and "supporter rewards" framing
- Direct financial benefit implications
- External benefits (early drop access described as reward, not in-app feature)

**Replacement**: See `BOOST_USER_GUIDE.md` (top section only) and `BOOST_IMPLEMENTATION_TRACKING.md`

---

### 2. `GIFT_IAP_SETUP_CHECKLIST.md`
**Status**: OUTDATED GIFT SYSTEM DOC  
**Issue**: References old "Gift/Token" system that was replaced by Boost system
- Product IDs may be outdated
- Setup instructions for deprecated system
- Does not reflect current boost tier structure

**Replacement**: Current boost products use:
- `artbeat_boost_spark` ($4.99)
- `artbeat_boost_surge` ($9.99)
- `artbeat_boost_overdrive` ($24.99)

---

## ✅ Current Active Documentation

For boost implementation, use ONLY these files:

1. **`BOOST_USER_GUIDE.md`** - Official compliance-approved user guide (top section only)
2. **`BOOST_IMPLEMENTATION_TRACKING.md`** - Implementation checklist and compliance requirements
3. **Code comments in boost service files** - For technical implementation details

---

## Why These Docs Are Obsolete

### Compliance Issues
The old documentation uses language that Apple explicitly prohibits:
- "Support artists financially"
- "Patron" / "Supporter" framing
- Direct payment implications
- External benefits as rewards
- Mandatory streak progression

### Model Change
The system evolved from:
- **Old**: Gift/Token system with direct artist payment model
- **New**: Boost system with platform-mediated creator earnings

---

## What to Do

### If You're Implementing Boosts:
❌ **Don't**: Reference `ARTIST_BOOST_CONCEPT.md` or `GIFT_IAP_SETUP_CHECKLIST.md`  
✅ **Do**: Use `BOOST_IMPLEMENTATION_TRACKING.md` as your checklist

### If You Find Prohibited Language:
1. Check if it references these obsolete docs
2. Replace with compliant terminology from `BOOST_USER_GUIDE.md`
3. Update `BOOST_IMPLEMENTATION_TRACKING.md` progress tracker

### If You're Creating New Features:
- Always frame IAPs as "digital items" that trigger "in-app effects"
- Never imply direct payment to creators
- Focus on platform visibility and momentum, not financial support

---

## Deletion Recommendation

Consider renaming these files to clearly mark them as obsolete:
```bash
mv ARTIST_BOOST_CONCEPT.md _OBSOLETE_ARTIST_BOOST_CONCEPT.md
mv GIFT_IAP_SETUP_CHECKLIST.md _OBSOLETE_GIFT_IAP_SETUP_CHECKLIST.md
```

Or moving them to an archive folder:
```bash
mkdir -p docs/obsolete
mv ARTIST_BOOST_CONCEPT.md docs/obsolete/
mv GIFT_IAP_SETUP_CHECKLIST.md docs/obsolete/
```

---

## Questions?

If you're unsure whether documentation is current:
1. Check the date at top of file
2. Search for prohibited terms: "support financially", "donate", "tip", "patron rewards"
3. Check if it references the Gift/Token system vs Boost system
4. When in doubt, use `BOOST_IMPLEMENTATION_TRACKING.md` as source of truth

---

**Remember**: App Store rejection can happen from a single sentence in your UI. Using outdated documentation with prohibited language is a critical risk.
