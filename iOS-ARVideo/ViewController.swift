//
//  ViewController.swift
//  iOS-ARVideo
//
//  Created by EugenKGD on 03/06/2019.
//  Copyright © 2019 ELezov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        playButton.addTarget(self,
                             action: #selector(didTapPlayButton),
                             for: .touchUpInside)
        playButtonType = .hidden
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
}

extension ViewController {
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
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode,
                  for anchor: ARAnchor) {
        if playButtonType == .play {
            videoPlayer?.pause()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didAdd node: SCNNode,
                  for anchor: ARAnchor) {
        // if the anchor is not of type ARImageAnchor (which means image is not detected), just return
        guard
            let imageAnchor = anchor as? ARImageAnchor,
            playButtonType == .hidden,
            let fileUrlString = Bundle.main.path(forResource: "Uni",
                                                 ofType: "mp4")
        else { return }
        //find our video file
        
        let videoItem = AVPlayerItem(url: URL(fileURLWithPath: fileUrlString))
        
        let player = AVPlayer(playerItem: videoItem)
        videoPlayer = player
        //initialize video node with avplayer
        let videoNode = SKVideoNode(avPlayer: player)
        player.play()
        playButtonType = .pause
        // add observer when our player.currentItem finishes player, then start playing from the beginning
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem,
                                               queue: nil) { (notification) in
            player.seek(to: CMTime.zero)
            player.play()
            print("Looping Video")
        }
        
        // set the size (just a rough one will do)
        let videoScene = SKScene(size: CGSize(width: 480, height: 360))
        // center our video to the size of our video scene
        videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        // invert our video so it does not look upside down
        videoNode.yScale = -1.0
        // add the video to our scene
        videoScene.addChild(videoNode)
        // create a plan that has the same real world height and width as our detected image
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                             height: imageAnchor.referenceImage.physicalSize.height)
        // set the first materials content to be our video scene
        plane.firstMaterial?.diffuse.contents = videoScene
        // create a node out of the plane
        let planeNode = SCNNode(geometry: plane)
        // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
        planeNode.eulerAngles.x = -Float.pi / 2
        // finally add the plane node (which contains the video node) to the added node
        node.addChildNode(planeNode)
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


