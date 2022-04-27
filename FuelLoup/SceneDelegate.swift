//
//  SceneDelegate.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 06/07/2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let dataController = FuelLoupDataController(modelName: "FuelLoup")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backgroundColor = .systemPurple
            let proxy = UINavigationBar.appearance()
            proxy.tintColor = .white
            proxy.standardAppearance = appearance
            proxy.scrollEdgeAppearance = appearance
        } else {
            let appearance = UINavigationBar.appearance()
            appearance.tintColor = .white
            appearance.barTintColor = .systemPurple
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        }

        guard let _ = (scene as? UIWindowScene) else { return }
        
        dataController.load()
        
        guard let tabBarController = window?.rootViewController as? UITabBarController,
              let mapTabNavigationViewController = tabBarController.viewControllers?[0] as? UINavigationController,
              var mapDataControllerAwareController = mapTabNavigationViewController.topViewController as? DataControllerAware,
              let tableTabNavigationViewController = tabBarController.viewControllers?[1] as? UINavigationController,
              var tableDataControllerAwareController = tableTabNavigationViewController.topViewController as? DataControllerAware else { return }
        
        mapDataControllerAwareController.dataController = dataController
        tableDataControllerAwareController.dataController = dataController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

}

