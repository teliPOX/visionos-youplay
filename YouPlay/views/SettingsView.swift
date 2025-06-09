import SwiftUI
import WebKit

struct SettingsView: View {
    @State private var showCacheAlert = false
    @State private var showCookiesAlert = false
    @State private var showSignOutDialog = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("isIntro") private var isIntro = true
    @AppStorage("isAdBlock") private var isAdBlock = true
    @State private var showCredits = false
    var model: SwiftUIWebViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String(localized: "General"))) {
                    Toggle(isOn: $isDarkMode) {
                        Label(
                            String(localized: "DarkMode"),
                            systemImage: "moon.fill"
                        )
                    }
                    Toggle(isOn: $isIntro) {
                        Label(
                            String(localized: "PlayIntro"),
                            systemImage: "play.circle.fill"
                        )
                    }
                    Toggle(isOn: $isAdBlock) {
                        Label(
                            String(localized: "AdBlock"),
                            systemImage: "shield.fill"
                        )
                    }
                }
                
                Section(header: Text(String(localized: "Account"))) {
                    Button(String(localized: "LogoutClearAll")) {
                        showSignOutDialog = true
                    }
                    .confirmationDialog(
                        String(localized: "LogoutMessage"),
                        isPresented: $showSignOutDialog,
                        titleVisibility: .visible
                    ) {
                        Button(
                            String(localized: "Logout"),
                            role: .destructive
                        ) {
                            model.clearCookies()
                            showCookiesAlert = true
                        }
                        Button(String(localized: "Cancel"), role: .cancel) { }
                    }
                    .alert(
                        String(localized: "LogoutTitle"),
                        isPresented: $showCookiesAlert
                    ) {
                        Button(String(localized: "OK"), role: .cancel) { }
                    } message: {
                        Text(String(localized: "LogoutMessage"))
                    }
                }
                
                Section(header: Text(String(localized: "Storage"))) {
                    Button(String(localized: "ClearCache")) {
                        model.clearCache()
                        showCacheAlert = true
                    }
                    .alert(
                        String(localized: "ClearCacheTitle"),
                        isPresented: $showCacheAlert
                    ) {
                        Button(String(localized: "OK"), role: .cancel) { }
                    } message: {
                        Text(String(localized: "ClearCacheMessage"))
                    }
                }
                
                Section(
                    header: Text(
                        String(localized: "Disclaimer")
                    )
                ) {
                    Text(String(localized: "DisclaimerMessage"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "Settings"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
