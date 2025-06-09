

import SwiftUI
import WebKit
import RealityKit
import _RealityKit_SwiftUI
import Speech

struct SwiftUIWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        webView.layer.cornerRadius = 20
        webView.layer.masksToBounds = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

final class SwiftUIWebViewModel: ObservableObject {
    @Published var addressStr = "https://www.youtube.com"
    @Published var isFullscreen = false
    @Published var isLoading = false
    
    @AppStorage("isAdBlock") private var isAdBlock = true
    @AppStorage("isDarkMode") private var isDarkMode = true
    let webView: WKWebView
    private let uiDelegate = WebViewUIDelegate()
    private var loadingObservation: NSKeyValueObservation?
    
    init() {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.preferences.isElementFullscreenEnabled = true
        webViewConfiguration.preferences.setValue(true, forKey:"developerExtrasEnabled")
        webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.uiDelegate = uiDelegate
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        
        webView.configuration.userContentController.addUserScript(WKUserScript(
            source: """
                function cleanupItems() {
                    const searchBar = document.getElementsByClassName("ytSearchboxComponentHost"),
                        voiceButton = document.getElementById("voice-search-button"),
                        sideNav = document.getElementsByTagName("ytd-mini-guide-renderer"),
                        guideContent = document.getElementById("guide-content"),
                        guideButton = document.getElementById("guide-button");
            
                    if (searchBar && searchBar.length > 0) 
                        searchBar[0].style.setProperty("display", "none", "important");
            
                    if (sideNav && sideNav.length > 0) 
                        sideNav[0].style.setProperty("display", "none", "important");
            
                    if (voiceButton)
                        voiceButton.style.setProperty("display", "none", "important");
                    
                    if (guideContent) 
                        guideContent.style.setProperty("display", "none", "important");
            
                    if (guideButton)
                        guideButton.style.setProperty("display", "none", "important");
                }
                setInterval(cleanupItems, 200);
                cleanupItems();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        
        if (isDarkMode) {
            webView.configuration.userContentController.addUserScript(WKUserScript(
                source: """
                    try {
                    document.documentElement.setAttribute('dark', 'true');
                
                                alert('dark mode!');
                
                    function setDarkMode() {
                
                    const style = document.createElement('style');
                    style.textContent = `
                      * {
                        color: inherit !important;
                      }
                
                      html[dark], html[darker-dark-theme] {
                        background-color: #000 !important;
                        color: #fff !important;
                      }
                
                      ytd-app, ytd-watch-flexy, ytd-page-manager {
                        background-color: #000 !important;
                        color: #fff !important;
                      }
                
                      yt-formatted-string, span, div {
                        color: #fff !important;
                      }
                    `;
                    document.head.appendChild(style);
                }
                setDarkMode();
                setInterval(setDarkMode, 800);
                } catch (e) { alert('Error setting dark mode: ' + e); }
                """,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }
        
        loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] webView, change in
            DispatchQueue.main.async {
                self?.isLoading = webView.isLoading
            }
        }
        
        uiDelegate.onFullscreenPresented = { [weak self] in
            DispatchQueue.main.async {
                self?.isFullscreen = true
            }
        }
        
        uiDelegate.onFullscreenDismissed = { [weak self] in
            DispatchQueue.main.async {
                self?.isFullscreen = false
            }
        }
        
        loadUrl(url: "https://www.youtube.com")
        
        let group = DispatchGroup()
        group.enter()
        setupContentBlockFromStringLiteral {
            group.leave()
        }
        print("Waiting for content rules to be set up")
        group.notify(queue: .main, execute: { [weak self] in
            print("Content rules set up successfully")
            self?.loadUrl(url: "https://www.youtube.com")
        })
    }
    
    private func setupContentBlockFromStringLiteral(_ completion: (() -> Void)?) {
        let jsonString = """
    [{
      "trigger": {
        "url-filter": "r[0-9]*---sn-.*-.*.googlevideo.com"
      },
      "action": {
        "type": "block"
      }
    }]
    """
        if isAdBlock {
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "default", encodedContentRuleList: jsonString) { [weak self] (contentRuleList: WKContentRuleList?, error: Error?) in
                if let error = error {
                    print(error)
                    return
                }
                if let list = contentRuleList {
                    self?.webView.configuration.userContentController.add(list)
                    completion?()
                }
            }
        } else {
            completion?()
        }
    }
    
    func loadUrl(url: String) {
        let url = URL(string: url)
        webView.load(URLRequest(url: url!))
    }
    
    func clearCookies() {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieStore.delete(cookie)
            }
        }
        webView.reload()
    }
    
    func clearCache() {
        let dataStore = webView.configuration.websiteDataStore
        let cacheTypes: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache
        ]
        dataStore.removeData(ofTypes: cacheTypes, modifiedSince: Date.distantPast) {
            self.webView.reload()
        }
    }
    
    func performSearch(query: String) {
        loadUrl(url:  "https://www.youtube.com/results?search_query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
    }
}

struct PlayerView: View {
    @ObservedObject var model: SwiftUIWebViewModel
    var selectedTab: YouPlayTab = .home
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            SwiftUIWebView(webView: model.webView)
            if !model.isLoading && selectedTab != .shorts {
                SearchBar(text: $searchText, placeholderText: String(localized: "Search")) {
                    model.performSearch(query: searchText)
                }
                .padding(.top, -10)
            }
            if model.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.4)
            }
        }
        .onChange(of: model.isFullscreen) { newValue, _ in
            Task {
                if newValue {
                    await openImmersiveSpace(id: "youPlayScene")
                } else {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}

class WebViewUIDelegate: NSObject, WKUIDelegate {
    var onFullscreenPresented: (() -> Void)?
    var onFullscreenDismissed: (() -> Void)?
    
    func webView(_ webView: WKWebView, presentFullscreenController viewController: UIViewController) {
        onFullscreenPresented?()
        
        print("Going fullscreen")

        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // Set the modal presentation style to custom
            viewController.modalPresentationStyle = .custom
            // Set the preferred content size to match the window
            viewController.preferredContentSize = window.bounds.size
            // Present the controller
            rootVC.present(viewController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, dismissFullscreenController viewController: UIViewController) {
        onFullscreenDismissed?()
        viewController.dismiss(animated: true, completion: nil)
    }
}
