//
//  AppDelegate.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var nfcService = NFCService()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Initialize the window
        window = UIWindow(frame: UIScreen.main.bounds)

        // Create the main view controller, passing the configured nfcService
        let mainViewController = MainViewController(nfcService: nfcService)
        let navigationController = UINavigationController(rootViewController: mainViewController)

        // Set the root view controller
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Find the first available USB serial port and set as connection string
        let devPath = "/dev"
        let fileManager = FileManager.default
        var connectionString: String? = nil
        do {
            let devContents = try fileManager.contentsOfDirectory(atPath: devPath)
            let ports = devContents.filter { $0.hasPrefix("cu.usb") }.map { "/dev/" + $0 }
            if let firstPort = ports.first {
                connectionString = firstPort
                print("Using first USB serial port as connection string: \(firstPort)")
            } else {
                print("No USB serial ports found. NFC will not be available.")
            }
        } catch {
            print("Error reading /dev directory: \(error)")
        }

        #if targetEnvironment(macCatalyst)
        if let conn = connectionString {
            UserDefaults.standard.set(conn, forKey: "ACE_RFID_SelectedSerialPort")
            nfcService.setPort(conn)
        }
        let available = nfcService.nfcManager.isNFCAvailable()
        if available {
            print("NFC is available via libnfc!")
        } else {
            print("NFC not available.")
        }
        #endif

        return true
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "FilamentDataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be written to, or a similar file system issue.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

}
