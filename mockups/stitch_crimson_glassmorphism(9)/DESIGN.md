---
name: Lumina Glass
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#424656'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737687'
  outline-variant: '#c2c6d9'
  surface-tint: '#0052dc'
  primary: '#004bca'
  on-primary: '#ffffff'
  primary-container: '#0061ff'
  on-primary-container: '#f1f2ff'
  inverse-primary: '#b4c5ff'
  secondary: '#00677d'
  on-secondary: '#ffffff'
  secondary-container: '#50d9fe'
  on-secondary-container: '#005c70'
  tertiary: '#535759'
  on-tertiary: '#ffffff'
  tertiary-container: '#6c6f71'
  on-tertiary-container: '#f1f3f5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#b3ebff'
  secondary-fixed-dim: '#4cd6fb'
  on-secondary-fixed: '#001f27'
  on-secondary-fixed-variant: '#004e5f'
  tertiary-fixed: '#e0e3e5'
  tertiary-fixed-dim: '#c4c7c9'
  on-tertiary-fixed: '#191c1e'
  on-tertiary-fixed-variant: '#444749'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '600'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 0.5rem
  sm: 1rem
  md: 1.5rem
  lg: 2.5rem
  xl: 4rem
  gutter: 24px
  margin: 32px
---

## Brand & Style

This design system is defined by a "Material Light Glass" aesthetic, merging the structural logic of Material Design with the ethereal quality of modern glassmorphism. It targets high-end productivity tools and professional environments where clarity and focus are paramount. 

The personality is approachable yet precise. By utilizing generous whitespace and a "light-first" philosophy, the UI feels breathable and premium. The visual language avoids heavy ornamentation, opting instead for subtle depth through translucent layers and high-quality typography. The goal is to evoke a sense of calm efficiency, making complex tasks feel lightweight and manageable.

## Colors

The palette is anchored in a pristine white and cool-gray foundation to maintain a high-end, clinical cleanliness. 

- **Primary:** A vibrant, professional blue serves as the main interactive anchor, used for key actions and progress indicators.
- **Secondary:** A soft teal is used for secondary accents, data visualization, and supportive highlights, providing a refreshing shift from traditional red/orange alerts.
- **Surfaces:** Backgrounds utilize a mix of pure white (`#FFFFFF`) and a very light gray (`#F8FAFC`) to create subtle tonal separation without relying on harsh lines.
- **Glass Effects:** Transparent layers use white with 40-70% opacity, paired with high-radius background blurs (20px-40px) to simulate frosted glass.

## Typography

This design system utilizes **Inter** for its neutral, systematic utility and excellent legibility at all scales. The hierarchy is established through significant size shifts and purposeful use of font weights rather than color.

- **Headlines:** Use a semi-bold weight with tighter letter spacing to create a grounded, authoritative feel.
- **Body:** Standardized at 16px for optimal readability with generous line height (1.5x) to prevent visual crowding.
- **Labels:** Small caps or medium weights are used for metadata and utility text to ensure they are distinct from body copy without requiring increased contrast.

## Layout & Spacing

The layout philosophy follows a **fluid grid** model with strict adherence to an 8px spacing rhythm (4px increments for micro-adjustments). 

- **Grid:** A 12-column grid is standard for desktop, transitioning to 4 columns for mobile.
- **Whitespace:** Emphasize "macro-white space" between logical sections to reinforce the high-end tool feel. Padding within containers should be generous (typically `lg` or 40px) to allow the glassmorphic backgrounds to feel airy.
- **Alignment:** All elements should align to the soft grid, but visual weight is balanced optically to ensure the UI doesn't feel "boxy."

## Elevation & Depth

Depth in this design system is achieved through **Glassmorphism** and **Ambient Shadows** rather than traditional "stacking."

- **Glassmorphism:** Use `backdrop-filter: blur(24px)` on surface containers. The background color of these containers should be a white tint with 60% opacity. 
- **Shadows:** Use extremely diffused, low-opacity shadows. Avoid pure black shadows; instead, use a soft blue-tinted gray (e.g., `rgba(0, 40, 100, 0.04)`). The blur radius should be high (30px+) with minimal offset to simulate an ambient, floating effect.
- **Layering:** Primary content resides on the base layer. Modals and popovers use the glass effect to maintain a sense of context with the underlying content.

## Shapes

The shape language is consistently **Rounded**, promoting an approachable and modern aesthetic. 

- **Base Radius:** Standard buttons and input fields use a `0.5rem` (8px) corner radius.
- **Large Radius:** Cards and glass panels use `1rem` (16px) or `1.5rem` (24px) for a softer, more organic containment.
- **Interactive States:** When hovered, elements should not significantly change shape, but may subtly increase their corner radius or surface opacity to indicate tactility.

## Components

- **Buttons:** Primary buttons use a solid primary blue with white text. Secondary buttons are "ghost" style with a glass background and a very subtle 1px border at 10% opacity.
- **Input Fields:** Use a light-gray fill (`#F1F5F9`) with no border. On focus, they transition to a white background with a subtle primary-colored glow (shadow) and a 1px primary-colored bottom stroke.
- **Cards:** These are the primary expression of the glass style. Use the standard backdrop blur and a thin, 1px white border at 20% opacity to define the edge against light backgrounds.
- **Chips/Badges:** Pill-shaped with low-saturation backgrounds (e.g., light teal or light blue) and high-saturation text to maintain readability while appearing soft.
- **Lists:** Use generous vertical padding (16px+) between list items. Dividers should be avoided; use whitespace or very subtle tonal shifts to separate items.
- **Navigation:** Sidebars should utilize the full-height glassmorphic panel effect, allowing the main content colors to softly bleed through the navigation area.