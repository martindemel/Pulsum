# Pulsum iOS App - Liquid Glass Design Implementation Guide

**Target:** iOS 26+ | **Design Language:** Liquid Glass | **Date:** September 30, 2025  
**Purpose:** Complete reference for Claude Code to rework Pulsum app with Apple's Liquid Glass design system

---

## Table of Contents

1. [Overview: Liquid Glass Design Philosophy](#overview)
2. [Core Principles & Visual Language](#core-principles)
3. [Technical Implementation: SwiftUI APIs](#technical-implementation)
4. [App Structure & Navigation](#app-structure)
5. [Component-by-Component Breakdown](#components)
6. [Color System & Materials](#color-system)
7. [Typography & Hierarchy](#typography)
8. [Animation & Motion Design](#animation)
9. [Accessibility & Performance](#accessibility)
10. [Pulsum-Specific Implementation](#pulsum-specific)
11. [Testing & Quality Checklist](#testing)

---

## 1. Overview: Liquid Glass Design Philosophy {#overview}

### What is Liquid Glass?

Liquid Glass is Apple's new translucent material that reflects and refracts its surroundings, while dynamically transforming to help bring greater focus to content across system controls, navigation elements, app icons, and widgets.

**Key Characteristics:**
- **Translucency with Purpose** - Not decorative; creates visual hierarchy
- **Real-time Rendering** - Dynamically reacts to movement with reflective highlights
- **Layered Depth** - Elements exist in physical space with separation
- **Adaptive Context** - Color informed by surrounding content and environment
- **Optical Realism** - Combines the clarity and translucency of glass with fluid, dynamic motion

### Design Goals for iOS 26

Driven by the goal of bringing greater focus to content that's instantly familiar, Apple's design team considered every aspect of Apple's platforms to identify improvements that could be made across the board.

**Focus Areas:**
1. **Content First** - Controls recede when not needed
2. **Spatial Hierarchy** - Clear visual layers for importance
3. **Unified Experience** - Consistency across Apple platforms
4. **Tactile Interaction** - Physical response to user actions
5. **Elegant Simplicity** - Clean, minimalistic, purposeful

### Why This Matters for Pulsum

Your health coaching app deals with **sensitive personal data** and **complex health metrics**. Liquid Glass helps by:

1. **Creating Trust** - Premium, polished feel signals professionalism
2. **Reducing Cognitive Load** - Clear hierarchy guides attention
3. **Enhancing Focus** - Health data stands out, UI recedes
4. **Modernizing Perception** - Matches cutting-edge Apple Intelligence branding
5. **Improving Legibility** - Better contrast and depth for dense information

---

## 2. Core Principles & Visual Language {#core-principles}

### The Three Pillars of Liquid Glass Design

#### 1. Layered Architecture

Liquid Glass elements should always be designed as sitting "on top" of something. They don't stack, they're not part of your main UI, they're always on their own layer when you're designing.

**Layer Hierarchy (Bottom to Top):**
```
┌─────────────────────────────────────┐
│ Layer 4: Modal Sheets (Deepest Glass)
├─────────────────────────────────────┤
│ Layer 3: Navigation/Tab Bars (Glass)
├─────────────────────────────────────┤
│ Layer 2: Interactive Controls (Glass)
├─────────────────────────────────────┤
│ Layer 1: Content (NO Glass, Solid)
└─────────────────────────────────────┘
```

**CRITICAL RULE:** 
- ✅ **DO** apply Liquid Glass to navigation, controls, overlays
- ❌ **DON'T** apply Liquid Glass to main content (lists, text, charts)
- ❌ **DON'T** stack glass layers on top of each other

#### 2. Dynamic Transformation

Controls are crafted out of Liquid Glass and act as a distinct functional layer that sits above apps. They give way to content and dynamically morph as users need more options or move between different parts of an app.

**Behavior Patterns:**
- **Scroll Collapse** - Tab bars shrink when scrolling down, expand when scrolling up
- **Context Adaptation** - Navigation items appear/disappear based on view state
- **Interactive Response** - Elements shimmer, scale, highlight on touch
- **Focus Shift** - Non-essential UI fades when user is engaged

#### 3. Optical Authenticity

Elements in Liquid Glass feel like panes of polished glass that reflect light, cast subtle shadows, and interact with their environment in believable ways.

**Visual Properties:**
- **Specular Highlights** - Bright reflections along edges and corners
- **Refraction** - Background content distorts through glass
- **Soft Shadows** - Floating elements cast realistic depth shadows
- **Color Bleeding** - Vibrant background colors tint glass surfaces
- **Motion Parallax** - Subtle depth perception during scrolling/gestures

---

## 3. Technical Implementation: SwiftUI APIs {#technical-implementation}

### Primary API: `.glassEffect()` Modifier

To make buttons look like Liquid Glass, you apply the glassEffect view modifier to them.

**Basic Usage:**
```swift
Button("Action") {
    // action
}
.glassEffect()
```

**IMPORTANT:** 
- Remove any existing `.background()` modifiers before applying `.glassEffect()`
- Glass creates its own rounded shape automatically
- You'll always get a shape that has rounded corners that fit nicely with the rest of your app's UI and the context where the effect is applied

### Advanced Configuration

#### Glass Intensity & Tinting

```swift
// Basic glass with color tint
.glassEffect(.regular.tint(.blue))

// Reduced opacity for subtle effect
.glassEffect(.regular.tint(.purple.opacity(0.8)))

// Different blur levels
.glassEffect(.ultraThin)     // Lightest blur
.glassEffect(.thin)          // Light blur
.glassEffect(.regular)       // Standard blur (default)
.glassEffect(.thick)         // Heavy blur
.glassEffect(.ultraThick)    // Deepest blur
```

**Blur Level Guidelines:**
- **Navigation/Tab Bars**: `.regular` or `.thick`
- **Floating Buttons**: `.regular.tint(color.opacity(0.8))`
- **Modal Sheets**: `.thick` for primary, `.regular` for secondary
- **Toolbars**: `.thin` to `.regular`

#### Interactive Glass Effects

To make our glass buttons respond to user input by growing a bit and applying a sort of shimmer effect, we apply the interactive modifier to the glass effect.

```swift
Button("Action") {
    // action
}
.glassEffect(.regular.tint(.blue).interactive())
```

**Interaction Behaviors:**
- Slight scale increase on press
- Shimmer/highlight effect during touch
- Smooth spring animation on release
- Visual feedback without haptics (glass is visual)

### GlassEffectContainer - Grouping Elements

By placing our Liquid Glass UI elements in the same container, the elements will blend together when they're close to each other in the UI.

```swift
GlassEffectContainer {
    // All glass elements here will blend when close
    NavigationBar()
    FloatingButtons()
    ModalSheet()
}
```

**Why Container Matters:**
1. **Performance** - System optimizes rendering for grouped elements
2. **Fluid Blending** - Elements merge/separate like liquid when animating
3. **Coherent Appearance** - Shared lighting and reflection model

**Usage Pattern:**
```swift
ZStack {
    // Content layer (no glass)
    ScrollView {
        ContentView()
    }
    
    // Glass layer (grouped)
    GlassEffectContainer {
        VStack {
            Spacer()
            CustomTabBar()
                .glassEffect(.regular.tint(.blue.opacity(0.7)))
        }
        
        VStack {
            CustomNavBar()
                .glassEffect(.regular)
            Spacer()
        }
    }
}
```

### Alternative: `.liquidGlassMaterial` Modifier

Use the new liquidGlassMaterial modifier to wrap background views, navigation bars, or sheets. Customize intensity and color blending to match your app's branding.

```swift
ZStack {
    Color.background
        .liquidGlassMaterial()
        .ignoresSafeArea()
    
    ContentView()
}
```

**When to Use Each:**
- **`.glassEffect()`** - For discrete UI elements (buttons, toolbars, cards)
- **`.liquidGlassMaterial()`** - For large background surfaces (sheets, navigation backdrops)

### UIKit Implementation (If Needed)

The updated UIVisualEffectView supports advanced materials with Liquid Glass effects.

```swift
// UIKit approach
let glassView = UIVisualEffectView(effect: UIBlurEffect(style: .liquidGlass))
glassView.layer.cornerRadius = 20
glassView.layer.cornerCurve = .continuous
```

**For Pulsum:** 
Since you're pure SwiftUI, focus on SwiftUI modifiers. Only use UIKit if integrating third-party components.

---

## 4. App Structure & Navigation {#app-structure}

### Tab Bar Design (Photos App Style)

Tab bars and sidebars have been redesigned with the same approach. In iOS 26, when users scroll, tab bars shrink to bring focus to the content while keeping navigation instantly accessible. The moment users scroll back up, tab bars fluidly expand.

**Pulsum Tab Structure:**
```
┌─────────────────────────────────────┐
│   Today      Insights    Journal    │  ← Tab bar (Liquid Glass)
└─────────────────────────────────────┘
```

#### Implementation Pattern

```swift
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        GlassEffectContainer {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tag(0)
                
                InsightsView()
                    .tag(1)
                
                JournalView()
                    .tag(2)
            }
            .tabViewStyle(.glass) // iOS 26 new style
        }
    }
}
```

**Custom Tab Bar (More Control):**

```swift
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { item in
                TabButton(
                    item: item,
                    isSelected: selectedTab == item.rawValue,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = item.rawValue
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(.blue.opacity(0.6)))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

struct TabButton: View {
    let item: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                
                Text(item.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .matchedGeometryEffect(id: "TAB", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

enum TabItem: Int, CaseIterable, Identifiable {
    case today = 0
    case insights = 1
    case journal = 2
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .today: "Today"
        case .insights: "Insights"
        case .journal: "Journal"
        }
    }
    
    var icon: String {
        switch self {
        case .today: "house.fill"
        case .insights: "chart.xyaxis.line"
        case .journal: "book.fill"
        }
    }
}
```

**Key Features:**
- Liquid Glass background with tint
- Matched geometry animation for selection indicator
- SF Symbols with hierarchical rendering
- Spring animation for tactile feedback
- Accessible tap targets (44pt minimum)

### Dynamic Tab Bar Behavior

```swift
struct ScrollableContentView: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var isTabBarExpanded = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack {
                    // Content
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                let threshold: CGFloat = 50
                withAnimation(.spring(response: 0.3)) {
                    isTabBarExpanded = value > -threshold
                }
            }
            
            CustomTabBar(selectedTab: $selectedTab)
                .scaleEffect(isTabBarExpanded ? 1.0 : 0.85, anchor: .bottom)
                .offset(y: isTabBarExpanded ? 0 : 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTabBarExpanded)
        }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

### Navigation Bar Design

Controls, toolbars, and navigation within apps have been redesigned. Previously configured for rectangular displays, they now fit perfectly concentric with the rounded corners of modern hardware and app windows.

```swift
struct PulsumNavigationBar: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.thin)
        .ignoresSafeArea(edges: .top)
    }
}
```

**Usage:**
```swift
VStack(spacing: 0) {
    PulsumNavigationBar(
        title: "Today",
        subtitle: "Tuesday, September 30",
        trailing: AnyView(
            Button {
                // Settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        )
    )
    
    ScrollView {
        // Content
    }
}
```

---

## 5. Component-by-Component Breakdown {#components}

### Buttons

**Primary Action Button:**
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .glassEffect(.regular.tint(.blue.opacity(0.9)).interactive())
        .padding(.horizontal, 20)
    }
}
```

**Secondary Button:**
```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .glassEffect(.thin.tint(.secondary.opacity(0.3)).interactive())
        .padding(.horizontal, 20)
    }
}
```

**Floating Action Button (FAB):**
```swift
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
        }
        .glassEffect(.regular.tint(.blue.opacity(0.85)).interactive())
        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}
```

### Cards

**Health Metric Card:**
```swift
struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: TrendDirection
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Spacer()
                
                TrendIndicator(direction: trend)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(unit)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }
}
```

**IMPORTANT:** Cards are content, not controls. Use `.ultraThinMaterial` NOT `.glassEffect()`.

**Recommendation Card:**
```swift
struct RecommendationCard: View {
    let recommendation: Recommendation
    let onTap: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recommendation.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(recommendation.duration)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: recommendation.icon)
                        .font(.title)
                        .foregroundStyle(.blue)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(.blue.opacity(0.15))
                        }
                }
                
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Label("Strong Evidence", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Button(action: onComplete) {
                        Text("Complete")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(.thin.tint(.green.opacity(0.8)).interactive())
                }
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}
```

### Modal Sheets

Controls are crafted out of Liquid Glass and act as a distinct functional layer that sits above apps.

```swift
struct GlassSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Handle
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(.tertiary)
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                        
                        content
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                    .glassEffect(.thick)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 32,
                            topTrailingRadius: 32
                        )
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
    }
}
```

**Usage:**
```swift
@State private var showingSheet = false

var body: some View {
    ZStack {
        ContentView()
        
        GlassSheet(isPresented: $showingSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recommendation Details")
                    .font(.title2.bold())
                
                // Sheet content
            }
        }
    }
}
```

### Lists

**CRITICAL:** List content should NOT use glass effect.

```swift
struct HealthList: View {
    let items: [HealthDataPoint]
    
    var body: some View {
        List(items) { item in
            HealthRow(item: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
    }
}

struct HealthRow: View {
    let item: HealthDataPoint
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundStyle(item.color)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(item.color.opacity(0.15))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(item.timestamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(item.value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}
```

### Text Input Fields

```swift
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }
}
```

### Toggle Switches

```swift
struct GlassToggle: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}
```

---

## 6. Color System & Materials {#color-system}

### Pulsum Color Palette

**Primary Colors:**
```swift
extension Color {
    // Brand Colors
    static let pulsumBlue = Color(red: 0.04, green: 0.52, blue: 1.0)      // #0A84FF
    static let pulsumTeal = Color(red: 0.0, green: 0.78, blue: 0.75)      // #00C7BE
    static let pulsumPurple = Color(red: 0.37, green: 0.36, blue: 0.90)   // #5E5CE6
    
    // Semantic Colors
    static let healthPositive = Color.green
    static let healthNeutral = Color.orange
    static let healthNegative = Color.red
    static let healthUnknown = Color.gray
    
    // Background Layers
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
}
```

**Glass Tints for Different Contexts:**
```swift
struct GlassTints {
    static let navigation = Color.pulsumBlue.opacity(0.7)
    static let toolbar = Color.pulsumBlue.opacity(0.5)
    static let modal = Color.pulsumTeal.opacity(0.6)
    static let actionButton = Color.pulsumBlue.opacity(0.9)
    static let secondaryButton = Color.secondary.opacity(0.3)
}
```

### Material Hierarchy

**When to Use Each Material:**

1. **`.glassEffect(.ultraThick)`** - Deep modals, full-screen overlays
2. **`.glassEffect(.thick)`** - Navigation bars, important toolbars
3. **`.glassEffect(.regular)`** - Standard buttons, tab bars
4. **`.glassEffect(.thin)`** - Subtle toolbars, secondary controls
5. **`.glassEffect(.ultraThin)`** - Minimal overlays, hints

**For Content (Not Glass):**
1. **`.ultraThinMaterial`** - Card backgrounds, list rows
2. **`.thinMaterial`** - Secondary cards
3. **`.regularMaterial`** - Primary cards, grouped content
4. **`.thickMaterial`** - Rarely used, heavy separation
5. **`.ultraThickMaterial`** - Almost never, extreme separation

### Dark Mode Considerations

```swift
struct AdaptiveGlassView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var glassColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.15) 
            : Color.black.opacity(0.08)
    }
    
    var body: some View {
        Button("Action") {
            // action
        }
        .glassEffect(.regular.tint(glassColor))
    }
}
```

**Best Practices:**
- Test BOTH light and dark modes for every view
- Liquid Glass automatically adapts, but tints may need adjustment
- Use semantic colors (`.primary`, `.secondary`) for text
- Avoid pure black or pure white backgrounds

---

## 7. Typography & Hierarchy {#typography}

### Font System

Use strong color separation: Choose brighter text and bold icons when placing them over glass backgrounds.

**Typography Scale:**
```swift
struct PulsumTypography {
    // Display
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Body
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // Data Display (Rounded for numbers)
    static let dataLarge = Font.system(size: 40, weight: .bold, design: .rounded)
    static let dataMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let dataSmall = Font.system(size: 20, weight: .semibold, design: .rounded)
}
```

**Weight Guidelines:**
- **Over Glass:** Use `.semibold` or `.bold` for readability
- **Over Solid:** Use `.regular` or `.medium`
- **Numbers:** Always use `.rounded` design
- **Headlines:** Always `.bold` or `.semibold`

### Text Contrast Rules

```swift
struct ContrastAwareText: View {
    let text: String
    let isOverGlass: Bool
    
    var body: some View {
        Text(text)
            .font(isOverGlass ? .headline : .body)
            .foregroundStyle(isOverGlass ? .primary : .primary)
            .shadow(
                color: isOverGlass ? .black.opacity(0.2) : .clear,
                radius: isOverGlass ? 1 : 0,
                y: isOverGlass ? 1 : 0
            )
    }
}
```

**CRITICAL:** Add a subtle shadow or outline to key text when over busy or variable backgrounds.

### SF Symbols Usage

```swift
struct SymbolConfig {
    static let small = Image.SymbolConfiguration(pointSize: 16, weight: .medium)
    static let medium = Image.SymbolConfiguration(pointSize: 20, weight: .semibold)
    static let large = Image.SymbolConfiguration(pointSize: 28, weight: .bold)
    static let xlarge = Image.SymbolConfiguration(pointSize: 36, weight: .bold)
}

// Usage
Image(systemName: "heart.fill")
    .symbolRenderingMode(.hierarchical)
    .font(.system(size: 24, weight: .semibold))
    .foregroundStyle(.red)
```

**Rendering Modes:**
- `.hierarchical` - Single color with depth (recommended)
- `.palette` - Multiple colors for complex icons
- `.monochrome` - Single flat color
- `.multicolor` - Full-color system icons

---

## 8. Animation & Motion Design {#animation}

### Spring Animations (Primary)

Animate transitions between states for a smooth, tactile feel.

```swift
struct AnimationPresets {
    // Quick response (buttons, toggles)
    static let quick = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // Standard (view transitions, sheet presentation)
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.8)
    
    // Smooth (large movements, scroll-driven)
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.85)
    
    // Bouncy (celebrations, completions)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}
```

**Usage:**
```swift
Button("Action") {
    withAnimation(.quick) {
        isExpanded.toggle()
    }
}
```

### Transition Patterns

```swift
// Fade + Scale (Modals, alerts)
.transition(
    .scale(scale: 0.95)
    .combined(with: .opacity)
)

// Slide + Opacity (Sheets, cards)
.transition(
    .move(edge: .bottom)
    .combined(with: .opacity)
)

// Blur transition (Background changes)
.transition(.blur)

// Asymmetric (Different in/out)
.transition(
    .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
)
```

### Interactive Glass Animation

When I tap the buttons now, not a lot happens. We can do better by making our buttons respond to user interaction.

```swift
struct InteractiveGlassButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
        }
        .glassEffect(.regular.tint(.blue.opacity(0.9)).interactive())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

### Scroll-Driven Animations

```swift
struct ScrollDrivenView: View {
    @State private var scrollOffset: CGFloat = 0
    
    var headerOpacity: Double {
        let threshold: CGFloat = 100
        return min(1, max(0, scrollOffset / threshold))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack {
                    // Content
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            
            // Header that fades in on scroll
            HStack {
                Text("Header")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .glassEffect(.regular)
            .opacity(headerOpacity)
        }
    }
}
```

### Loading States

```swift
struct GlassLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1).repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .padding(20)
        .glassEffect(.regular)
        .onAppear {
            isAnimating = true
        }
    }
}
```

---

## 9. Accessibility & Performance {#accessibility}

### Accessibility Guidelines

Respect system settings: Apple's Dynamic Type and increased contrast options should work seamlessly atop glass.

**Dynamic Type Support:**
```swift
struct AccessibleText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .dynamicTypeSize(.large...(.accessibility5))
    }
}
```

**Contrast Checks:**
```swift
struct HighContrastAwareView: View {
    @Environment(\.colorSchemeContrast) var contrast
    
    var glassIntensity: GlassEffect.Style {
        contrast == .increased ? .thick : .regular
    }
    
    var body: some View {
        Button("Action") {
            // action
        }
        .glassEffect(glassIntensity.tint(.blue))
    }
}
```

**VoiceOver Labels:**
```swift
Button {
    // action
} label: {
    Image(systemName: "heart.fill")
}
.accessibilityLabel("Add to favorites")
.accessibilityHint("Double tap to save this recommendation")
```

**Minimum Touch Targets:**
- **Standard:** 44x44 points minimum
- **Glass Buttons:** 48x48 points recommended (harder to see edges)

```swift
.frame(minWidth: 44, minHeight: 44)
.contentShape(Rectangle()) // Expand tap area
```

### Performance Optimization

Use the new rendering options to avoid battery drain, especially on older devices. Prefer lower blur levels for secondary surfaces.

**Device-Specific Optimization:**
```swift
struct OptimizedGlassView: View {
    @Environment(\.displayScale) var displayScale
    
    var glassIntensity: GlassEffect.Style {
        // Lower blur on lower-end devices
        displayScale < 3.0 ? .thin : .regular
    }
    
    var body: some View {
        Button("Action") {
            // action
        }
        .glassEffect(glassIntensity)
    }
}
```

**Reduce Motion Support:**
```swift
struct MotionAwareView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var animation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .quick
    }
    
    var body: some View {
        Button("Action") {
            withAnimation(animation) {
                isExpanded.toggle()
            }
        }
    }
}
```

**Lazy Loading:**
```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            HealthMetricCard(item: item)
        }
    }
}
```

**Glass Container Limits:**
This is a recommendation from Apple that helps make sure the system can render our effects efficiently.

```swift
// ✅ Good: All glass elements in one container
GlassEffectContainer {
    Navigation()
    TabBar()
    FloatingButton()
}

// ❌ Bad: Multiple nested containers
GlassEffectContainer {
    GlassEffectContainer {
        Navigation()
    }
}
```

---

## 10. Pulsum-Specific Implementation {#pulsum-specific}

### Architecture Mapping

**Your Current Structure:**
```
UI Layer → Agent System → Services → ML/Data
```

**Glass Integration Points:**
1. **UI Layer** - Apply all Liquid Glass here
2. **Agent System** - No visual changes needed
3. **Services** - No visual changes needed
4. **ML/Data** - No visual changes needed

### Screen-by-Screen Implementation

#### 1. Daily Home View (Today Tab)

**Components:**
- Navigation bar (Glass)
- Wellbeing score card (Material, not glass)
- Recommendation cards (Material, not glass)
- Floating action button for voice journal (Glass)
- Tab bar (Glass)

```swift
struct DailyHomeView: View {
    @StateObject private var viewModel: DailyHomeViewModel
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content Layer
            ScrollView {
                VStack(spacing: 24) {
                    // Wellbeing Score
                    WellbeingScoreCard(score: viewModel.currentScore)
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("For You Today")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        ForEach(viewModel.recommendations) { rec in
                            RecommendationCard(
                                recommendation: rec,
                                onTap: { viewModel.selectRecommendation(rec) },
                                onComplete: { viewModel.completeRecommendation(rec) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 100) // Space for nav bar
                .padding(.bottom, 100) // Space for tab bar + FAB
            }
            .background(Color.backgroundPrimary)
            
            // Glass Layer
            GlassEffectContainer {
                // Navigation Bar
                VStack {
                    PulsumNavigationBar(
                        title: "Today",
                        subtitle: viewModel.dateString,
                        trailing: AnyView(
                            Button {
                                viewModel.showSettings()
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        )
                    )
                    Spacer()
                }
                
                // Tab Bar
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: .constant(0))
                }
                
                // FAB for Voice Journal
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "mic.fill") {
                            viewModel.startVoiceJournal()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // Above tab bar
                    }
                }
            }
        }
    }
}
```

#### 2. Health Insights View

**Components:**
- Navigation bar (Glass)
- Time range selector (Glass)
- Chart cards (Material)
- Metric cards (Material)
- Tab bar (Glass)

```swift
struct HealthInsightsView: View {
    @StateObject private var viewModel: HealthInsightsViewModel
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    TimeRangePicker(selection: $selectedTimeRange)
                        .glassEffect(.thin.tint(.blue.opacity(0.5)))
                        .padding(.horizontal, 20)
                    
                    // HRV Trend Chart
                    ChartCard(
                        title: "Heart Rate Variability",
                        data: viewModel.hrvData(for: selectedTimeRange)
                    )
                    
                    // Metrics Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        ForEach(viewModel.metrics) { metric in
                            HealthMetricCard(
                                title: metric.name,
                                value: metric.value,
                                unit: metric.unit,
                                trend: metric.trend,
                                icon: metric.icon
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 100)
                .padding(.bottom, 100)
            }
            
            GlassEffectContainer {
                VStack {
                    PulsumNavigationBar(
                        title: "Insights",
                        subtitle: nil,
                        trailing: nil
                    )
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: .constant(1))
                }
            }
        }
    }
}
```

#### 3. Voice Journal View

**Components:**
- Navigation bar with close button (Glass)
- Recording indicator (Glass when active)
- Transcript view (Material)
- Action buttons (Glass)

```swift
struct VoiceJournalView: View {
    @StateObject private var viewModel: VoiceJournalViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button area (glass)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .glassEffect(.regular.interactive())
                    
                    Spacer()
                }
                .padding(20)
                
                Spacer()
                
                // Recording Indicator
                if viewModel.isRecording {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(.red)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "waveform")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .red.opacity(0.5), radius: 20)
                        
                        Text("Listening...")
                            .font(.title3.bold())
                        
                        Text(viewModel.elapsedTime)
                            .font(.system(.title, design: .rounded))
                            .monospacedDigit()
                    }
                    .padding(32)
                    .glassEffect(.thick.tint(.red.opacity(0.3)))
                }
                
                // Transcript (if exists)
                if let transcript = viewModel.transcript {
                    ScrollView {
                        Text(transcript)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(24)
                    }
                    .frame(maxHeight: 300)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.regularMaterial)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {