//
//  LiveCameraViewController.swift
//  iOS-ARVideo
//
//  Created by EugenKGD on 03/06/2019.
//  Copyright © 2019 ELezov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class LiveCameraViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var playButton: UIButton!
    
    enum PlayButtonType {
        case hidden
        case pause
        case play
    }
    
    var playButtonType: PlayButtonType = .hidden {
        didSet {
            configurePlayButton(type: playButtonType)
        }
    }
    
    var videoPlayer: AVPlayer?
    
    fileprivate var arkitSceneManager: ARKitSceneManagerAbstract?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureArkitSceneManager()
        configurePlayButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = configureSession()
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
}

fileprivate extension LiveCameraViewController {
    
    func configureArkitSceneManager() {
        guard
            let fileUrlString = Bundle.main.path(forResource: "Uni",
                                                 ofType: "mp4")
        else {
                return
        }

        arkitSceneManager = ARKitSceneManager(configModel:
            ARKitSceneManager.ConfigModel(fileUrlString: fileUrlString),
                                              sceneView: sceneView)
        arkitSceneManager?.onOutputActionIntent = { [weak self] actionType in
            guard let self = self else { return }
            switch actionType {
            case .didUpdate:
                if self.playButtonType == .play {
                    self.videoPlayer?.pause()
                }
            case .didCreatePlayer(let player):
                self.videoPlayer = player
                self.playButtonType = .pause
            }
        }
    }
    
    func configurePlayButton() {
        playButton.addTarget(self,
                             action: #selector(didTapPlayButton),
                             for: .touchUpInside)
        playButtonType = .hidden
    }
    
    func configureSession() -> ARImageTrackingConfiguration {
        if ARConfiguration.isSupported {
            print("ARKit is supported. You can work with ARKit")
        } else {
            print("ARKit is not supported. You cannot work with ARKit")
        }
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // first see if there is a folder called "ARImages" Resource Group in our Assets Folder
        if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "ARImages", bundle: Bundle.main) {
            
            // if there is, set the images to track
            configuration.trackingImages = trackedImages
            // at any point in time, only 1 image will be tracked
            configuration.maximumNumberOfTrackedImages = 1
        }
        
        return configuration
    }
}

extension LiveCameraViewController {
    @objc
    func didTapPlayButton() {
        switch playButtonType {
        case .pause:
            videoPlayer?.pause()
            playButtonType = .play
            
        case .play:
            playButtonType = .pause
            videoPlayer?.play()
        default:
            break
        }
    }
    
    func configurePlayButton(type: PlayButtonType) {
        switch type {
        case .hidden:
            DispatchQueue.main.async { [weak self] in
                self?.playButton.isHidden = true
            }
        case .pause:
            DispatchQueue.main.async {  [weak self] in
                guard let self = self else { return }
                self.playButton.isHidden = false
                self.playButton.setBackgroundImage(UIImage(named: "pause"),
                                                   for: .normal)
            }
        case .play:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.playButton.isHidden = false
                self.playButton.setBackgroundImage(UIImage(named: "play"),
                                                   for: .normal)
            }
        }
    }
}


