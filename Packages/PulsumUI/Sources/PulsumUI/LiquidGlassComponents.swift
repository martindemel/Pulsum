import SwiftUI

public struct LiquidGlassTabBar: View {
    public struct TabItem: Identifiable {
        public let id = UUID()
        public let icon: String
        public let title: String
        public let badge: Int?

        public init(icon: String, title: String, badge: Int? = nil) {
            self.icon = icon
            self.title = title
            self.badge = badge
        }
    }

    @Binding private var selectedTab: Int
    private let tabs: [TabItem]
    @Namespace private var namespace

    public init(selectedTab: Binding<Int>, tabs: [TabItem]) {
        self._selectedTab = selectedTab
        self.tabs = tabs
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 12) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    tabButton(for: index, tab: tab)
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 20)
            .padding(.vertical, 14)
            .background { tabBarBackground }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.pulsumStandard, value: selectedTab)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateSelection(for: value.location, in: proxy)
                    }
                    .onEnded { _ in }
            )
        }
        .frame(height: 82)
    }

    @ViewBuilder
    private func tabButton(for index: Int, tab: TabItem) -> some View {
        let isSelected = index == selectedTab

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = index
            }
        } label: {
            tabContent(for: tab, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func tabContent(for tab: TabItem, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                iconView(for: tab, isSelected: isSelected)
                    .frame(width: 28, height: 28)
                    .scaleEffect(isSelected ? 1.04 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isSelected)

                if let badge = tab.badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.9))
                        )
                        .offset(x: 8, y: -8)
                }
            }

            Text(tab.title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? Color.pulsumTextPrimary : Color.pulsumTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 80, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background { tabBackground(isSelected: isSelected) }
    }

    @ViewBuilder
    private func tabBackground(isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        if isSelected {
            shape
                .fill(Color.white.opacity(0.22))
                .overlay {
                    shape
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                }
                .overlay {
                    shape
                        .fill(selectionFill)
                        .blur(radius: 14)
                        .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 6)
        } else {
            shape
                .fill(Color.white.opacity(0.08))
                .overlay {
                    shape
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
    }

    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.15))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.35))
                    .blur(radius: 22)
                    .opacity(0.45)
                    .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func iconView(for tab: TabItem, isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Image(systemName: tab.icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(selectionIconTint)
            } else {
                Image(systemName: tab.icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.secondary)
            }
        }
        .font(.system(size: 22, weight: .semibold))
    }

    private var selectionFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.65),
                Color.white.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var selectionIconTint: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.pulsumBlueSoft,
                Color.pulsumBlueSoft.opacity(0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func updateSelection(for location: CGPoint, in proxy: GeometryProxy) {
        guard !tabs.isEmpty else { return }

        let leadingInset: CGFloat = 18
        let trailingInset: CGFloat = 20
        let usableWidth = max(proxy.size.width - (leadingInset + trailingInset), 1)
        let adjustedX = max(0, min(location.x - leadingInset, usableWidth))
        let segmentWidth = usableWidth / CGFloat(tabs.count)

        let proposedIndex = min(tabs.count - 1, max(0, Int(adjustedX / segmentWidth)))

        if proposedIndex != selectedTab {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedTab = proposedIndex
            }
        }
    }
}
