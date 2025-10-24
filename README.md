# 🙏 Gosaign - NGO Attendance Management System

**A Flutter-based attendance management system with barcode scanning for NGO distribution tracking.**

Gosai Bhakt is a specialized attendance and distribution tracking system designed for NGO operations. It helps manage beneficiary records, track item distribution, and prevent duplicate entries through barcode-based verification.

## 🌟 Overview

Gosai Bhakt addresses critical challenges in NGO distribution management:
- **Manual Record Keeping**: Digitizing beneficiary data and attendance
- **Duplicate Distribution**: Preventing multiple claims through barcode verification
- **Data Accessibility**: Role-based access for administrators and members
- **Real-time Tracking**: Instant attendance marking and daily reports
- **Accountability**: Transparent record of distribution activities

## ✨ Key Features

### 👥 Dual Role System

#### 🔐 Admin Account
- **Complete Access**: Full control over system operations
- **Beneficiary Management**: Create, edit, and delete beneficiary records
- **Barcode Generation**: Automatic unique barcode creation for each beneficiary
- **Attendance Marking**: Scan barcodes to mark daily attendance
- **Data Management**: Add new women with all required details
- **Full Data Access**: View all beneficiary information including barcodes
- **Distribution Tracking**: Monitor daily distribution activities

#### 👤 Member Account
- **View-Only Access**: Access beneficiary information (limited)
- **Barcode Scanning**: Mark attendance by scanning barcodes
- **Data Viewing**: See name, husband name, address, and coupon code
- **Attendance Reports**: View daily attendance lists
- **Restricted Access**: Cannot view or generate barcodes
- **No Edit Rights**: Cannot modify beneficiary data

### 📊 Beneficiary Data Management
- **Comprehensive Records**: Store complete beneficiary information
    - Full name
    - Husband's name
    - Complete address
    - Unique coupon code
    - Unique barcode
- **Search & Filter**: Quick search functionality
- **Data Validation**: Prevent duplicate entries
- **Secure Storage**: Cloud-based data protection

### 📱 Barcode System
- **Unique Identification**: Each beneficiary gets a unique barcode
- **Quick Scanning**: Fast attendance marking through barcode
- **Duplicate Prevention**: System alerts if same barcode scanned twice
- **Daily Reset**: Fresh tracking for each distribution day
- **Visual Feedback**: Immediate confirmation of scan success

### 📋 Attendance Tracking
- **Daily Attendance**: Mark presence for each distribution day
- **Real-time Updates**: Instant sync across all devices
- **Attendance List**: View all present beneficiaries for the day
- **Historical Data**: Access past attendance records
- **Export Reports**: Generate attendance reports for documentation

### 🚨 Duplicate Detection
- **Same-Day Prevention**: Alert if beneficiary tries to claim twice
- **Visual Alerts**: Clear notification for duplicate attempts
- **Audit Trail**: Log all scanning activities
- **Reporting**: List of all present beneficiaries

## 🎯 Use Case

**NGO Distribution Scenario:**
1. Admin creates records for 600+ beneficiary women
2. Each woman receives a unique barcode card
3. On distribution day:
    - Women arrive with their barcode cards
    - Staff (admin/member) scans the barcode
    - System marks attendance instantly
    - If woman tries to return, system alerts duplicate entry
4. End of day: Generate complete attendance report
5. Transparent distribution management with accountability

## 🛠️ Tech Stack

### Frontend Framework
- **Framework**: Flutter SDK
- **Language**: Dart
- **IDE**: Android Studio
- **UI**: Material Design Components
- **State Management**: Provider / setState

### Backend & Database
- **Backend**: Firebase
- **Database**: Cloud Firestore
    - Collection: `Gosai_bhakt`
    - Fields: id, name, husband_name, address, coupon_code, barcode, password, role
- **Authentication**: Custom login with role-based access
- **Storage**: SharedPreferences for local session management

### Barcode System
- **Scanner**: flutter_barcode_scanner
- **Generator**: barcode_widget / barcode
- **Format**: Code128 / QR Code
- **Printing**: Integration with label printers

### Key Packages
```yaml