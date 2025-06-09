//
//  AppDelegate.swift
//  YouPlay
//
//  Created by Simon Kobler on 05.06.25.
//

import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let preferences = UIWindowScene.GeometryPreferences.Vision()
        preferences.resizingRestrictions = UIWindowScene.ResizingRestrictions.uniform // Set it to none or uniform
        windowScene.requestGeometryUpdate(preferences)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
