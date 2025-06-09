//
//  ContentView.swift
//  YouPlay
//
//  Created by Simon Kobler on 01.03.25.
//

import SwiftUI

enum YouPlayTab: Hashable {
    case home, shorts, abos, settings, history
}

struct ContentView: View {
    @State private var selectedTab: YouPlayTab = .home
    @StateObject private var model = SwiftUIWebViewModel()
        
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Text("")
                    .tabItem {
                        Label(String(localized: "Homepage"), systemImage: "play.square")
                    }
                    .tag(YouPlayTab.home)
                    .id(YouPlayTab.home)
                
                Text("")
                    .tabItem {
                        Label(String(localized: "Shorts"), systemImage: "play.square.stack.fill")
                    }
                    .tag(YouPlayTab.shorts)
                    .id(YouPlayTab.shorts)
                
                Text("")
                    .tabItem {
                        Label(String(localized: "Subscriptions"), systemImage: "play.rectangle.on.rectangle")
                    }
                    .tag(YouPlayTab.abos)
                    .id(YouPlayTab.abos)
                
                Text("")
                    .tabItem {
                        Label(String(localized: "History"), systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                    .tag(YouPlayTab.history)
                    .id(YouPlayTab.history)
                
                SettingsView(model: model)
                    .tabItem {
                        Label(String(localized: "Settings"), systemImage: "gear")
                    }
                    .tag(YouPlayTab.settings)
            }
            .onChange(of: selectedTab) { _, newTab in
                switch newTab {
                case .home:
                    model.loadUrl(url: "https://www.youtube.com")
                case .shorts:
                    model.loadUrl(url: "https://www.youtube.com/shorts")
                case .abos:
                    model.loadUrl(url: "https://www.youtube.com/feed/subscriptions")
                case .history:
                    model.loadUrl(url: "https://www.youtube.com/feed/history")
                case .settings:
                    break
                }
            }
            if selectedTab != .settings {
                PlayerView(model: model, selectedTab: selectedTab)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
