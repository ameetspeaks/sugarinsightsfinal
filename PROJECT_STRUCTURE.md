# Sugar Insights - Project Structure & UI/UX Guidelines

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── screens/                     # All app screens
│   ├── auth/                   # Authentication screens
│   ├── dashboard/              # Dashboard screens
│   ├── glucose_tracking/       # Glucose tracking screens
│   ├── profile/                # Profile screens
│   └── ...
├── widgets/                    # Reusable components
│   ├── health_status_card.dart # Medical-grade status cards
│   ├── medical_button.dart     # Medical-grade buttons
│   ├── medical_input_field.dart # Medical-grade input fields
│   └── ...
├── models/                     # Data models
│   ├── user.dart              # User model with health data
│   ├── glucose_reading.dart   # Glucose reading model
│   └── ...
├── services/                   # API and database services
│   ├── api_service.dart       # REST API service
│   └── ...
├── utils/                      # Helper functions and constants
│   ├── date_utils.dart        # Date formatting utilities
│   └── ...
├── theme/                      # App theme configuration
│   └── app_theme.dart         # Medical-grade theme
└── core/                       # Core functionality
    ├── constants/              # App constants
    │   └── app_colors.dart    # Color scheme
    └── ...
```

## 🎨 UI/UX Guidelines

### Design Principles

1. **Clean, Medical-Grade Interface**
   - Professional appearance suitable for healthcare
   - Consistent spacing and typography
   - Clear visual hierarchy

2. **High Contrast for Accessibility**
   - WCAG AA compliance
   - Minimum 4.5:1 contrast ratio
   - Clear focus states for all interactive elements

3. **Intuitive Navigation**
   - Consistent navigation patterns
   - Clear call-to-action buttons
   - Logical information architecture

4. **Color-Coded Health Ranges**
   - Normal: Green (#7ED957)
   - Low: Orange (#FFA500)
   - High: Red (#E57373)
   - Critical: Dark Red

5. **Easy-to-Read Charts and Graphs**
   - Large, clear data points
   - High contrast colors
   - Accessible labels and legends

### Color Scheme

```dart
// Primary Colors
primaryColor: #147374 (Teal)
primaryLight: #D9ECFF (Light Blue)
primaryDark: #003B73 (Dark Blue)

// Status Colors
normalRange: #7ED957 (Green)
lowRange: #FFA500 (Orange)
highRange: #E57373 (Red)

// Background Colors
appBackground: #E8F0F9 (Light Gray)
cardBackground: #FFFFFF (White)
disabledPlaceholder: #B0B0B0 (Gray)

// Interactive Colors
activeButton: #4A90E2 (Blue)
mutedGrey: #D3D3D3 (Light Gray)
successColor: #28A745 (Green)

// Text Colors
textPrimary: #49454F (Dark Gray)
textSecondary: #6B7280 (Medium Gray)
```

### Typography

- **Font Family**: Lufga (Custom medical font)
- **Font Sizes**: 12px - 32px (Accessible range)
- **Line Height**: 1.4 - 1.5 (Optimal readability)
- **Letter Spacing**: 0.1 - 0.5 (Clear character separation)

### Component Guidelines

#### Buttons
- Minimum touch target: 48px height
- High contrast colors
- Clear hover/focus states
- Consistent padding and spacing

#### Input Fields
- Clear labels above fields
- Focus states with 2px border
- Error states with red borders
- Helpful placeholder text

#### Cards
- Subtle shadows (2px elevation)
- Rounded corners (12px radius)
- Proper spacing between elements
- Color-coded borders for status

#### Navigation
- Fixed bottom navigation
- Clear active states
- Consistent iconography
- Accessible labels

### Accessibility Features

1. **Screen Reader Support**
   - Semantic labels for all elements
   - Proper heading hierarchy
   - Descriptive alt text for images

2. **Keyboard Navigation**
   - Tab order follows visual layout
   - Clear focus indicators
   - Keyboard shortcuts for common actions

3. **Color Blindness Support**
   - Color-coded elements also use patterns/shapes
   - High contrast mode support
   - Alternative color schemes

4. **Touch Accessibility**
   - Minimum 44px touch targets
   - Adequate spacing between interactive elements
   - Haptic feedback for important actions

### Medical-Grade Standards

1. **Data Accuracy**
   - Clear units display (mg/dL, mmol/L)
   - Precise decimal places
   - Validation for medical ranges

2. **Privacy & Security**
   - Secure data transmission
   - HIPAA compliance considerations
   - Clear privacy policies

3. **Emergency Features**
   - Quick access to critical information
   - Clear emergency contact display
   - One-tap emergency actions

4. **Health Monitoring**
   - Real-time data updates
   - Trend analysis and alerts
   - Integration with health devices

## 🚀 Development Guidelines

### Code Organization
- Feature-based folder structure
- Reusable components in widgets/
- Clear separation of concerns
- Consistent naming conventions

### State Management
- Provider pattern for state management
- Centralized data models
- Proper error handling
- Loading states for all async operations

### Testing
- Unit tests for all models and services
- Widget tests for UI components
- Integration tests for critical flows
- Accessibility testing

### Performance
- Lazy loading for large datasets
- Efficient image caching
- Optimized network requests
- Smooth animations (60fps)

## 📱 Platform Considerations

### iOS
- Follow Apple Human Interface Guidelines
- Support for iOS accessibility features
- Proper safe area handling
- Native iOS animations

### Android
- Follow Material Design principles
- Support for Android accessibility features
- Proper back button handling
- Native Android animations

### Cross-Platform
- Consistent experience across platforms
- Platform-specific optimizations
- Shared codebase with platform-specific UI
- Responsive design for different screen sizes 