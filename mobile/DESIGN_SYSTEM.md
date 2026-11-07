# Tadreeb – Design System

## 1. Introduction

This document defines the official design system for the Tadreeb application.

It is the single source of truth for colors, typography, spacing, and shared visual styles across the application.

All screens and widgets must follow these guidelines to maintain a consistent user experience.

---

## 2. Brand Colors

The application uses purple as its primary brand color and orange as its accent color.

| Color Name | Hex Code | Usage |
|---|---|---|
| Primary | `#8A2BE2` | Main brand color, primary buttons, selected elements |
| Primary Light | `#F1E5FF` | Light backgrounds and selected states |
| Primary Dark | `#6F1BC0` | Dark primary states |
| Accent | `#FF9800` | Secondary highlights and important actions |
| Accent Light | `#FFF3E0` | Light accent backgrounds |
| Accent Dark | `#E68900` | Dark accent states |

### Color Usage Rules

- Use `AppColors.primary` for the main brand identity.
- Use `AppColors.accent` for secondary highlights.
- Use light variants for backgrounds and subtle emphasis.
- Avoid introducing new brand colors inside individual screens.
- Always use centralized color definitions.

---

## 3. Background Colors

| Color Name | Hex Code | Usage |
|---|---|---|
| Background | `#FEF7FF` | Main application background |
| Surface | `#FFFFFF` | Cards, dialogs, and surfaces |
| Field | `#F5F5F5` | Input field backgrounds |

---

## 4. Text Colors

| Color Name | Hex Code | Usage |
|---|---|---|
| Text Primary | `#25212A` | Headings and important content |
| Text Secondary | `#6B6872` | Descriptions and secondary information |
| Text Hint | `#99949F` | Placeholder text |
| Text On Primary | `#FFFFFF` | Text displayed on primary backgrounds |

---

## 5. Status Colors

These colors communicate the state of operations and information.

### Success

- Success: `#16A34A`
- Success Light: `#DCFCE7`

### Error

- Error: `#DC2626`
- Error Light: `#FEE2E2`

### Warning

- Warning: `#F59E0B`
- Warning Light: `#FEF3C7`

### Usage

- Success: completed operations and approved requests.
- Error: failed operations and rejected requests.
- Warning: pending actions and important alerts.

---

## 6. Borders and Dividers

| Color Name | Hex Code | Usage |
|---|---|---|
| Border | `#EAE6EE` | Card and input borders |
| Divider | `#F0ECF2` | Separating content sections |

---

## 7. Bottom Navigation Colors

| Color Name | Hex Code | Usage |
|---|---|---|
| Navigation Background | `#FFF9FF` | Navigation bar background |
| Navigation Selected | `#8A2BE2` | Active navigation item |
| Navigation Unselected | `#9E9AA3` | Inactive navigation item |

---

## 8. Typography

The application supports Arabic and English typography.

| Language | Font |
|---|---|
| Arabic | Cairo |
| English | Poppins |

Font definitions are centralized in `AppFonts`.

```dart
abstract final class AppFonts {
  static final arabic = GoogleFonts.cairo().fontFamily!;
  static final english = GoogleFonts.poppins().fontFamily!;
}
```

### Text Styles

Use `AppTypography` instead of defining repeated text styles inside screens.

| Style | Font Size |
|---|---:|
| display | 32 |
| headlineLarge | 28 |
| headlineMedium | 24 |
| headlineSmall | 20 |
| titleLarge | 18 |
| titleMedium | 16 |
| titleSmall | 14 |
| bodyLarge | 16 |
| bodyMedium | 14 |
| bodySmall | 12 |
| labelLarge | 14 |
| labelMedium | 12 |
| labelSmall | 10 |

---

## 9. Spacing System

All spacing values must come from `AppSpacing`.

| Name | Value |
|---|---:|
| xxs | 4 |
| xs | 8 |
| sm | 12 |
| md | 16 |
| lg | 20 |
| xl | 24 |
| xxl | 32 |
| xxxl | 40 |
| section | 48 |

### Standard Layout Spacing

| Property | Value |
|---|---:|
| Screen Horizontal Padding | 16 |
| Screen Vertical Padding | 16 |
| Card Padding | 12 |
| Card Gap | 12 |
| Section Gap | 24 |

### Spacing Rules

- Use `AppSpacing` for margins and padding.
- Avoid arbitrary spacing values.
- Maintain consistent spacing between sections.
- Keep card spacing consistent across screens.

---

## 10. Component Styling

The application uses centralized `AppTheme` configuration.

### Standard Border Radius

| Component | Radius |
|---|---:|
| Input Fields | 14 |
| Cards | 16 |
| Buttons | 14 |

### Component Rules

- Use the application theme for buttons.
- Use the application theme for input fields.
- Use the application theme for cards.
- Reuse shared widgets whenever possible.
- Avoid repeating component styling in individual screens.

---

## 11. RTL and Language Support

The application primarily supports Arabic.

Development rules:

1. Use RTL layout where appropriate.
2. Use `Directionality` only when necessary.
3. Ensure Arabic and English text display correctly together.
4. Use the correct font for each language.
5. Avoid hardcoded text alignment when directional alignment is more appropriate.

---

## 12. Flutter Imports

Use the centralized design system files.

```dart
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
```

Adjust relative import paths according to the location of the widget or screen.

---

## 13. Development Guidelines

Every new screen or widget must follow these rules:

1. Use `AppColors` for all application colors.
2. Use `AppSpacing` for spacing and layout dimensions.
3. Use `AppTypography` for text styles.
4. Use `AppFonts` for font definitions.
5. Follow `AppTheme` for standard component styling.
6. Reuse shared components instead of duplicating code.
7. Support Arabic RTL layouts.
8. Maintain consistent UI across Student, Institute, and Admin sections.
9. Avoid creating random design values inside screens.
10. Update centralized design tokens when a global design change is needed.

---

## 14. Single Source of Truth

The following files are the official design system:

- `app_colors.dart`
- `app_fonts.dart`
- `app_spacing.dart`
- `app_typography.dart`
- `app_theme.dart`

These files are the single source of truth for the visual identity of Tadreeb.

**Important:** Any future UI development must follow this document and these centralized files.