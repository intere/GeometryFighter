//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Eric Internicola on 5/8/16.
//  Copyright (c) 2016 Eric Internicola. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {

    var scnView: SCNView!
    var manager: GameSceneManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
    }

    override var shouldAutorotate : Bool {
        return true
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        manager.handleTouch(touch)
    }

}

// MARK: - SCNSceneRendererDelegate Methods

extension GameViewController : SCNSceneRendererDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        manager.render(updateAtTime: time)
    }

}

// MARK: - Setup Methods

private extension GameViewController {

    func setupView() {
        scnView = self.view as! SCNView
        scnView.delegate = self
        scnView.isPlaying = true
        setupDebug()
    }

    func setupDebug() {
        scnView.showsStatistics = true
//        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
    }

    func setupScene() {
        manager = GameSceneManager(scnView)
        scnView.scene = manager.scene
    }

}
