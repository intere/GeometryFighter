//
//  GameSceneManager.swift
//  GeometryFighter
//
//  Created by Internicola, Eric on 1/6/17.
//  Copyright © 2017 Eric Internicola. All rights reserved.
//

import SceneKit
import UIKit

class GameSceneManager {
    var view: SCNView!
    var scene: SCNScene
    var cameraNode: SCNNode!
    var game = GameHelper.sharedInstance
    var splashNodes: [String: SCNNode] = [:]
    var spawnTime:TimeInterval = 0
    
    init(_ view: SCNView) {
        self.view = view
        self.scene = SCNScene()
        setup()
    }

}

// MARK: - API

extension GameSceneManager {

    /// Shows the Splash Screen with the provided name
    ///
    /// - Parameter splashName: Show the splash screen that you tell us to show.
    func showSplash(_ splashName:String) {
        for (name,node) in splashNodes {
            if name == splashName {
                node.isHidden = false
            } else {
                node.isHidden = true
            }
        }
    }

    func render(updateAtTime time: TimeInterval) {
        if game.state == .playing {
            if time > spawnTime {
                spawnShape()
                spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
            }
            cleanScene()
        }
        game.updateHUD()
    }


    /// Handles a touch event
    ///
    /// - Parameter touch: The touch event
    func handleTouch(_ touch: UITouch) {
        switch game.state {
        case .gameOver:
            return

        case .tapToPlay:
            game.reset()
            game.state = .playing
            showSplash("")
            return

        case .playing:
            let location = touch.location(in: view)
            let hitResults = view.hitTest(location, options: nil)
            if hitResults.count > 0 {
                guard let result = hitResults.first, result.node != game.hudNode else {
                    return
                }
                handleTouchFor(result.node)
            }
        }
    }
}

// MARK: - Helpers

private extension GameSceneManager {

    /// Sets up the Game Scene
    func setup() {
        scene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
        setupCamera()
        setupHUD()
        setupSplash()
    }


    /// Sets up the Camera
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scene.rootNode.addChildNode(cameraNode)
    }

    /// Sets up the Heads Up Display
    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scene.rootNode.addChildNode(game.hudNode)
    }

    func setupSplash() {
        splashNodes["TapToPlay"] = createSplash("TAPTOPLAY",
                                                imageFileName: "GeometryFighter.scnassets/Textures/TapToPlay_Diffuse.png")
        splashNodes["GameOver"] = createSplash("GAMEOVER",
                                               imageFileName: "GeometryFighter.scnassets/Textures/GameOver_Diffuse.png")
        showSplash("TapToPlay")
    }

    func createSplash(_ name:String, imageFileName:String) -> SCNNode {
        let plane = SCNPlane(width: 5, height: 5)
        let splashNode = SCNNode(geometry: plane)
        splashNode.position = SCNVector3(x: 0, y: 5, z: 0)
        splashNode.name = name
        splashNode.geometry?.materials.first?.diffuse.contents = imageFileName
        scene.rootNode.addChildNode(splashNode)
        return splashNode
    }

    // Removes everything from the scene
    func cleanScene() {
        for node in scene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }

    func handleTouchFor(_ node: SCNNode) {
        createExplosion(node.geometry!, position: node.presentation.position,
                        rotation: node.presentation.rotation)
        if node.name == "GOOD" {
            handleGoodCollision()
        } else if node.name == "BAD" {
            handleBadCollision()
        }
        node.removeFromParentNode()
    }

    func spawnShape() {
        let geometry = generateGeometry()

        let color = UIColor.random
        geometry.materials.first?.diffuse.contents = color
        let geometryNode = SCNNode(geometry: geometry)

        if let trailEmitter = createTrail(color, geometry: geometry) {
            geometryNode.addParticleSystem(trailEmitter)
        }

        if color == UIColor.black {
            geometryNode.name = "BAD"
            game.playSound(scene.rootNode, name: "SpawnBad")
        } else {
            geometryNode.name = "GOOD"
            game.playSound(scene.rootNode, name: "SpawnGood")
        }

        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        scene.rootNode.addChildNode(geometryNode)
        pushShape(geometryNode)
    }

    func createExplosion(_ geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        guard let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil) else {
            print("ERROR: Couldn't load the Explosion particle system")
            return
        }
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface

        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scene.addParticleSystem(explosion, transform: transformMatrix)
    }

    func handleGoodCollision() {
        game.score += 1
        game.playSound(scene.rootNode, name: "ExplodeGood")
    }

    func handleBadCollision() {
        game.lives -= 1
        game.playSound(scene.rootNode, name: "ExplodeBad")
        game.shakeNode(cameraNode)

        if game.lives <= 0 {
            game.saveState()
            showSplash("GameOver")
            game.playSound(scene.rootNode, name: "GameOver")
            game.state = .gameOver
            scene.rootNode.runAction(SCNAction.waitForDurationThenRunBlock(5) { (node:SCNNode!) -> Void in
                self.showSplash("TapToPlay")
                self.game.state = .tapToPlay
            })
        }
    }

    func pushShape(_ geometryNode: SCNNode) {
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
    }

    func createTrail(_ color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem? {
        guard let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil) else {
            print("ERROR: Couldn't load the Trail particle system")
            return nil
        }
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }

    func generateGeometry() -> SCNGeometry {
        var geometry: SCNGeometry

        let shapeType = ShapeType.random()
        print("Generating a \(shapeType) Shape")

        switch shapeType {
        case .capsule:
            geometry = SCNCapsule(capRadius: 0.5, height: 2)
        case .cone:
            geometry = SCNCone(topRadius: 0, bottomRadius: 1, height: 1)
        case .cylider:
            geometry = SCNCylinder(radius: 0.25, height: 1)
        case .pyramid:
            geometry = SCNPyramid(width: 1, height: 1, length: 1)
        case .sphere:
            geometry = SCNSphere(radius: 1)
        case .torus:
            geometry = SCNTorus(ringRadius: 1, pipeRadius: 0.25)
        case .tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1)
        case .box:
            geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        }

        return geometry
    }
}
