//
//  ViewController.swift
//  MapTest
//
//  Created by Echo on 10/21/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import Mapbox

@objc(OfflinePackDownloaderViewController)

class OfflinePackDownloaderViewController: UIViewController, MGLMapViewDelegate {
    var processHintView = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    var offlineMapInfo: OfflineMapInfo?
    var mapView: MGLMapView!
    var progressView: UIProgressView!
    
    var observer: NSObjectProtocol?
    
    var mapIsReady = false
    var offlineStorageIsReady = false
    
    @IBOutlet var downloadButton: UIBarButtonItem!
    @IBOutlet var diskSpaceButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadButton.isEnabled = false
        deleteButton.isEnabled = false
        
        if DiskHelper.hasMinimumDiskSpace() {
            requestMapInfoForOffline()
            
            observer = MGLOfflineStorage.shared.observe(\.packs, options: .new) { (_, changed) in
                self.offlineStorageIsReady = true
                self.deleteButton.isEnabled = true
                self.checkDownloadButtonStatus()
            }

        } else {
            let message = "Your device space is less than \(DiskHelper.getMinimumRequiredDiskSpaceDescription()),\n please make more space in order to download offline map."
            AlertHelper.showAlert(message: message, presentViewController: self)
        }
        
        diskSpaceButton.title = DiskHelper.remainingDiskSpaceDescription()
        diskSpaceButton.tintColor = .blue
    }

    // Simulating a network request to get offline map information
    func requestMapInfoForOffline() {
        
        processHintView.message = "Getting the map infomation for offline storage..."
        present(processHintView, animated: true)
        
        // wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            self.offlineMapInfo = UserService.shared.getOfflineMapInfo()
            
            if let mapInfo = self.offlineMapInfo {
                self.showMap(by: mapInfo)
                self.setupOfflinePackNotificationHandlers()
            } else {
                let message = "Failed to get map infomation for offline."
                AlertHelper.showAlert(message: message, presentViewController: self)
            }
        }
    }
    
    func showMap(by mapInfo: OfflineMapInfo) {
        processHintView.message = "loading the map of \(mapInfo.name)..."

        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.darkStyleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .gray
        mapView.delegate = self
        view.addSubview(mapView)

        mapView.setCenter(CLLocationCoordinate2D(latitude: mapInfo.latitude, longitude: mapInfo.longitude), zoomLevel: mapInfo.fromZoomLevel, animated: false)
        
    }

    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        processHintView.dismiss(animated: true)
        
        if let mapInfo = self.offlineMapInfo {
            
            if let id = OfflineMapStorageHelper.getSavedMapId(), mapInfo.id == id {
                let fileSize = OfflineMapStorageHelper.getSavedMapSizeInfo()
                 title = "\(self.offlineMapInfo!.name): offline size - \(fileSize)"
            } else {
                title = mapInfo.name + " : no offline map yet"
            }
        }
        
        mapIsReady = true
        checkDownloadButtonStatus()
    }
    
    func checkDownloadButtonStatus() {
        downloadButton.isEnabled = mapIsReady && offlineStorageIsReady
    }
    
    func setupOfflinePackNotificationHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
    }
    
    @IBAction func downloadOfflineMap(_ sender: Any) {
        guard let mapInfo = self.offlineMapInfo else {
            return
        }
        
        if OfflineMapStorageHelper.isMapSavedById(mapInfo.id) {
            let alert = UIAlertController(title: "Prompt", message: "Offline Map with the same id has been found on your device, do you want to download it again?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                guard let self = self else { return }
                OfflineMapStorageHelper.removeMapSavedMarkById(mapInfo.id)
                self.startOfflinePackDownload(by: mapInfo)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
            
        } else {
            startOfflinePackDownload(by: mapInfo)
        }
    }
        
    @IBAction func deleteOfflineMap(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to delete the offline map?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            alert.dismiss(animated: true) {
                handleDeleteOfflineMap()
            }
        }
        
        let noAction = UIAlertAction(title: "no", style: .default)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true)
        
        func handleDeleteOfflineMap() {
            DispatchQueue.main.async {
                self.deleteButton.isEnabled = false
            }            
            
            if let mapId = offlineMapInfo?.id {
                OfflineMapStorageHelper.removeMapSavedMarkById(mapId)
            }
            
            if let packs = MGLOfflineStorage.shared.packs {
                packs.forEach {
                    MGLOfflineStorage.shared.removePack($0) { error in
                        if let error = error {
                            print("Error occured when removing pack: \(error)")
                        }
                    }
                }
            }
            
            title = offlineMapInfo!.name + " : no offline map yet"
            
            AlertHelper.showAlert(title:"Infomation", message: "Your offline map is deleted.", presentViewController: self)
        }
        
    }
    
    func startOfflinePackDownload(by mapInfo: OfflineMapInfo) {
        DispatchQueue.main.async {
            self.deleteButton.isEnabled = false
        }
        
        // Create a region that includes the current viewport and any tiles needed to view it when zoomed further in.
        // Because tile count grows exponentially with the maximum zoom level, you should be conservative with your `toZoomLevel` setting.
        let region = MGLTilePyramidOfflineRegion(styleURL: mapView.styleURL, bounds: mapView.visibleCoordinateBounds, fromZoomLevel: mapInfo.fromZoomLevel, toZoomLevel: mapInfo.toZoomLevel)

        // Store some data for identification purposes alongside the downloaded resources.
        let userInfo = ["name": mapInfo.id]
        
        do {
            let context = try NSKeyedArchiver.archivedData(withRootObject: userInfo, requiringSecureCoding: false)
            
            MGLOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "unknown error")")
                    return
                }

                pack!.resume()
            }
        } catch {
            print("error: \(error)")
        }

    }
}

// MARK: - MGLOfflinePack notification handlers
extension OfflinePackDownloaderViewController {
    @objc func offlinePackProgressDidChange(notification: NSNotification) {
        // Get the offline pack this notification is regarding,
        // and the associated user info for the pack; in this case, `name = My Offline Pack`
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pack.context) as? [String: String] {
            let progress = pack.progress
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            print("completedResources(\(completedResources)) expectedResources(\(expectedResources))")

            // Calculate current progress percentage.
            let progressPercentage = Float(completedResources) / Float(expectedResources)

            // Setup the progress bar.
            if progressView == nil {
                progressView = UIProgressView(progressViewStyle: .default)
                let frame = view.bounds.size
                progressView.frame = CGRect(x: frame.width / 4, y: frame.height * 0.75, width: frame.width / 2, height: 10)
                view.addSubview(progressView)
            }

            progressView.progress = progressPercentage

            // If this pack has finished, print its size and resource count.
            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack “\(userInfo["name"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
                
                if let mapId = userInfo["name"] {
                    OfflineMapStorageHelper.markMapSavedById(mapId)
                }
                
                DispatchQueue.main.async {
                    let fileSize = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: .file)
                    OfflineMapStorageHelper.saveMapSizeInfo(fileSize)
                    self.title = "\(self.offlineMapInfo!.name): offline size - \(fileSize)"
                    self.deleteButton.isEnabled = true
                    self.progressView.isHidden = true
                    AlertHelper.showAlert(title: "Download Finished", message: "You have successfully downloaded the offline map of \(self.offlineMapInfo!.name)", presentViewController: self)
                }
            } else {
                // Otherwise, print download/verification progress.
                print("Offline pack “\(userInfo["name"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
                
                DispatchQueue.main.async {
                    self.deleteButton.isEnabled = false
                }
            }
            
            DispatchQueue.main.async {
                self.diskSpaceButton.title = DiskHelper.remainingDiskSpaceDescription()
                
                if !DiskHelper.hasMinimumDiskSpace() {
                    self.diskSpaceButton.tintColor = .red
                }
            }
        }
    }

    @objc func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pack.context) as? [String: String],
            let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
            let errorMessage = "Offline pack “\(userInfo["name"] ?? "unknown")” received error: \(error.localizedFailureReason ?? "unknown error")"
            print(errorMessage)
            AlertHelper.showAlert(message: errorMessage, presentViewController: self)
        }
    }

    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pack.context) as? [String: String],
            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
            let errorMessage = "Offline pack “\(userInfo["name"] ?? "unknown")” reached limit of \(maximumCount) tiles."
            AlertHelper.showAlert(message: errorMessage, presentViewController: self)
        }
    }
}
