//
//  ARKitSceneManager.swift
//  iOS-ARVideo
//
//  Created by EugenKGD on 28/09/2019.
//  Copyright © 2019 ELezov. All rights reserved.
//

import Foundation

import SceneKit
import ARKit

protocol ARKitSceneManagerAbstract {
    typealias OnOutputActionIntent = (ARKitSceneManager.OutputActionType) -> Void
    var onOutputActionIntent: OnOutputActionIntent? { get set }
}

class ARKitSceneManager:
NSObject,
ARKitSceneManagerAbstract {
    
    enum OutputActionType {
    case didUpdate
    case didCreatePlayer(AVPlayer)
    }
    
    var onOutputActionIntent: OnOutputActionIntent?
    
    var sceneView: ARSCNView?

    struct ConfigModel {
        let fileUrlString: String
    }
    
    let configModel: ConfigModel
    init(configModel: ConfigModel,
         sceneView: ARSCNView?) {
        self.configModel = configModel
        self.sceneView = sceneView
        super.init()
        sceneView?.delegate = self
    }
}

fileprivate extension ARKitSceneManager {
    func configurePlayer() -> AVPlayer {
        let url = URL(fileURLWithPath: configModel.fileUrlString)
        let videoItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: videoItem)
        player.play()
        // add observer when our player.currentItem finishes player, then start playing from the beginning
        NotificationCenter
            .default
            .addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                         object: player.currentItem,
                         queue: nil) { (notification) in
            player.seek(to: CMTime.zero)
            player.play()
        }
        
        return player
    }
}

extension ARKitSceneManager: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode,
                  for anchor: ARAnchor) {
        onOutputActionIntent?(.didUpdate)
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didAdd node: SCNNode,
                  for anchor: ARAnchor) {
        // if the anchor is not of type ARImageAnchor (which means image is not detected), just return
        guard
            let imageAnchor = anchor as? ARImageAnchor
            else { return }
        //find our video file
        
        let player = configurePlayer()
        onOutputActionIntent?(.didCreatePlayer(player))
        //initialize video node with avplayer
        let videoNode = SKVideoNode(avPlayer: player)
        // finally add the plane node (which contains the video node) to the added node
        let planeNode = configureNode(videoNode: videoNode,
                                      imageAnchor: imageAnchor)
        node.addChildNode(planeNode)
    }
    
    func configureNode(videoNode: SKVideoNode,
                       imageAnchor: ARImageAnchor)  -> SCNNode {
        // set the size (just a rough one will do)
        let videoScene = SKScene(size: CGSize(width: 480,
                                              height: 360))
        // center our video to the size of our video scene
        videoNode.position = CGPoint(x: videoScene.size.width / 2,
                                     y: videoScene.size.height / 2)
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
        return planeNode
    }
}
