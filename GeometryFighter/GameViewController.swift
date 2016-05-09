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
    var scnScene: SCNScene!
    var cameraNode: SCNNode!

    var game = GameHelper.sharedInstance
    var spawnTime:NSTimeInterval = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.locationInView(scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            guard let result = hitResults.first else {
                return
            }
            handleTouchFor(result.node)
        }
    }

}

// MARK: - SCNSceneRendererDelegate Methods

extension GameViewController : SCNSceneRendererDelegate {

    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if time > spawnTime {
            spawnShape()

            spawnTime = time + NSTimeInterval(Float.random(min: 0.2, max: 1.5))
        }

        cleanScene()
        game.updateHUD()
    }

}

// MARK: - Setup Methods

private extension GameViewController {

    func setupView() {
        scnView = self.view as! SCNView
        scnView.delegate = self
        scnView.playing = true
        setupDebug()
    }

    func setupDebug() {
        scnView.showsStatistics = true
//        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
    }

    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }

    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }

    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }

}

// MARK: - Helpers

private extension GameViewController {

    func spawnShape() {
        var geometry: SCNGeometry

        let shapeType = ShapeType.random()
        print("Generating a \(shapeType) Shape")

        switch shapeType {
        case .Capsule:
            geometry = SCNCapsule(capRadius: 0.5, height: 2)
        case .Cone:
            geometry = SCNCone(topRadius: 0, bottomRadius: 1, height: 1)
        case .Cylider:
            geometry = SCNCylinder(radius: 0.25, height: 1)
        case .Pyramid:
            geometry = SCNPyramid(width: 1, height: 1, length: 1)
        case .Sphere:
            geometry = SCNSphere(radius: 1)
        case .Torus:
            geometry = SCNTorus(ringRadius: 1, pipeRadius: 0.25)
        case .Tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1)
        case .Box:
            geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        }

        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let geometryNode = SCNNode(geometry: geometry)

        if let trailEmitter = createTrail(color, geometry: geometry) {
            geometryNode.addParticleSystem(trailEmitter)
        }

        if color == UIColor.blackColor() {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }

        geometryNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        scnScene.rootNode.addChildNode(geometryNode)
        pushShape(geometryNode)
    }

    func handleTouchFor(node: SCNNode) {
        createExplosion(node.geometry!, position: node.presentationNode.position,
                        rotation: node.presentationNode.rotation)
        if node.name == "GOOD" {
            game.score += 1
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            game.lives -= 1
            node.removeFromParentNode()
        }
    }

    func pushShape(geometryNode: SCNNode) {
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, atPosition: position, impulse: true)
    }

    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentationNode.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }

    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem? {
        guard let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil) else {
            print("ERROR: Couldn't load the Trail particle system")
            return nil
        }
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }

    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        guard let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil) else {
            print("ERROR: Couldn't load the Explosion particle system")
            return
        }
        explosion.emitterShape = geometry
        explosion.birthLocation = .Surface

        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, withTransform: transformMatrix)
    }
    
}
