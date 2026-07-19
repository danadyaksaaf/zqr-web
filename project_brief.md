# Project Brief & PRD: QR Pulse Generator

## 1. Project Overview
**Product Name:** QR Pulse
**Concept:** A high-fidelity web application for generating various types of QR codes, designed with Material Design 3 principles to ensure seamless portability to a Flutter mobile/web application.
**Primary Objective:** Provide a clean, intuitive, and professional interface for users to create, customize, and download QR codes for different data types.

## 2. Target Audience
- **General Users:** Individuals needing quick QR codes for personal links or Wi-Fi sharing.
- **Professionals:** Business users creating digital vCards or marketing links.
- **Developers:** Users looking for a reliable API-ready generation tool with precise output.

## 3. Design System (Luminous Material)
- **Primary Color:** White (#FFFFFF) - Used for surfaces and background clarity.
- **Secondary Color:** Light Purple - Used for accents, primary actions, and brand identity.
- **Typography:** Hanken Grotesk (Clean, modern sans-serif).
- **Design Philosophy:** Material Design 3 (MD3).
    - **Roundness:** 8px (Round Eight).
    - **Layout:** Responsive grid with a fixed side navigation rail for desktop.
    - **Components:** Cards, Text Fields, Segmented Buttons, and Elevation-based surfaces.

## 4. Feature Requirements

### 4.1. Core Generator Types
1.  **URL Generator:**
    - Input field for destination URL.
    - Toggle for "Dynamic Short Link" (tracking enabled).
    - Quick actions: Download PNG, Copy Link.
2.  **vCard Generator:**
    - Structured fields: Full Name, Phone, Email, Organization, Website.
    - Real-time preview of the contact card layout.
3.  **Wi-Fi Generator:**
    - SSID input, Password input (with visibility toggle).
    - Encryption type dropdown (WPA/WPA2, WEP, None).
    - "Hidden Network" toggle.
4.  **Text Generator:**
    - Multi-line text area for raw data or notes (up to 2500 characters).
    - Character counter.

### 4.2. Customization Engine
- **Colors:** Ability to change the QR code's foreground and background colors.
- **Logo Integration:** Upload brand logos to be placed in the center of the QR code.
- **Frame Styles:** Choice of frames with custom CTA text (e.g., "Scan Me").
- **Correction Levels:** Adjustable error correction (Standard 7% to High 30%).

### 4.3. Output & Export
- **Formats:** PNG (Raster) and SVG (Vector) exports.
- **Print Optimization:** High-contrast settings for physical media.
- **History:** A dedicated view to manage previously generated designs.

## 5. Technical Considerations for Flutter Slicing
- **Component Mapping:**
    - Side Navigation Rail -> `NavigationRail`.
    - Main Content Area -> `Card` with `Column` layout.
    - Input Fields -> `TextFormField` with MD3 styling.
- **State Management:** Real-time updates to the QR preview widget as the user types.
- **Responsive Design:** Transition from a `NavigationRail` (Desktop) to a `BottomNavigationBar` (Mobile).

## 6. Success Metrics
- **Time-to-Generate:** Users should be able to create a code in under 30 seconds.
- **Export Quality:** 100% scannability across standard mobile devices.
- **Design Consistency:** Strict adherence to the Luminous Material design tokens.
