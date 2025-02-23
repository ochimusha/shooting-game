//
//  GameScene.swift
//  shooting-game
//
//  Created by Yasui Yuito on 2019/08/18.
//  Copyright © 2019 Yasui Yuito. All rights reserved.
//

import CoreMotion
import GameplayKit
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    var accelaration: CGFloat = 0.0

    var timer: Timer?

    let spaceshipCategory: UInt32 = 0b0001
    let missileCategory: UInt32 = 0b0010
    let asteroidCategory: UInt32 = 0b0100
    let earthCategory: UInt32 = 0b1000

    var earth: SKSpriteNode!
    var spaceShip: SKSpriteNode!

    override func didMove(to view: SKView) {
        // 重力シミュレートは必要だが重力の影響は受けたくないため
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        self.earth = SKSpriteNode(imageNamed: "earth")
        self.earth.xScale = 1.5
        self.earth.yScale = 0.3
        self.earth.position = CGPoint(x: 0, y: -frame.height / 2)
        self.earth.zPosition = -1.0
        self.earth.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 100))
        self.earth.physicsBody?.categoryBitMask = earthCategory
        self.earth.physicsBody?.contactTestBitMask = asteroidCategory
        self.earth.physicsBody?.collisionBitMask = 0
        addChild(self.earth)

        self.spaceShip = SKSpriteNode(imageNamed: "spaceship")
        self.spaceShip.scale(to: CGSize(width: frame.width / 5, height: frame.width / 5))
        self.spaceShip.position = CGPoint(x: 0, y: self.earth.frame.maxY + 50)
        self.spaceShip.physicsBody = SKPhysicsBody(circleOfRadius: self.spaceShip.frame.width * 0.1)
        self.spaceShip.physicsBody?.categoryBitMask = spaceshipCategory
        self.spaceShip.physicsBody?.contactTestBitMask = asteroidCategory
        self.spaceShip.physicsBody?.collisionBitMask = 0
        addChild(self.spaceShip)

        self.motionManager.accelerometerUpdateInterval = 0.2
        self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { data, _ in
            guard let data = data else { return }
            let a = data.acceleration
            self.accelaration = CGFloat(a.x) * 0.75 + self.accelaration * 0.25
        })

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.addAsteroid()})
    }

    override func didSimulatePhysics() {
        let nextPosition = self.spaceShip.position.x + self.accelaration * 50
        if frame.width / 2 - 30 < nextPosition {
            return
        }

        if nextPosition < -frame.width / 2 + 30 {
            return
        }

        self.spaceShip.position.x = nextPosition
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let missile: SKSpriteNode = SKSpriteNode(imageNamed: "missile")
        missile.position = CGPoint(x: self.spaceShip.position.x, y: self.spaceShip.position.y + 50)
        //NSLog("self.spaceShip.position.x=\(self.spaceShip.position.x), self.spaceShip.position.y=\(self.spaceShip.position.y)")
        missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.frame.height / 2)
        missile.physicsBody?.categoryBitMask = missileCategory
        missile.physicsBody?.contactTestBitMask = asteroidCategory
        missile.physicsBody?.collisionBitMask = 0
        addChild(missile)

        let moveToTop = SKAction.moveTo(y: frame.height, duration: 0.3)
        NSLog("frame.height=\(frame.height), self.frame.heigh=\(self.frame.height)")
        let remove = SKAction.removeFromParent()
        missile.run(SKAction.sequence([moveToTop, remove]))
    }

    func addAsteroid() {
        let names = ["asteroid1", "asteroid2", "asteroid3"]
        let name = names.randomElement()!
        let asteroid = SKSpriteNode(imageNamed: name)
        let random = CGFloat.random(in: -0.5...0.5)
        let positionX = frame.width * random
        NSLog("乱数は%f.positionXは%f.", random, positionX)
        asteroid.position = CGPoint(x: positionX, y: frame.height / 2 + asteroid.frame.height)
        asteroid.scale(to: CGSize(width: 70, height: 70))
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width)
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = missileCategory + spaceshipCategory + earthCategory
        asteroid.physicsBody?.collisionBitMask  = 0
        addChild(asteroid)

        let move = SKAction.moveTo(y: -frame.height / 2 - asteroid.frame.height, duration: 6.0)
        let remove = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([move, remove]))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        var asteroid: SKPhysicsBody
        var target: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask == asteroidCategory {
            asteroid = contact.bodyA
            target = contact.bodyB
        } else {
            asteroid = contact.bodyB
            target = contact.bodyA
        }

        guard let asteroidNode = asteroid.node else { return }
        guard let targetNode = target.node else { return }
        guard let explosion = SKEmitterNode(fileNamed: "Explosion") else { return }
        explosion.position = asteroidNode.position
        addChild(explosion)

        asteroidNode.removeFromParent()
        if target.categoryBitMask == missileCategory {
            targetNode.removeFromParent()
        }

        self.run(SKAction.wait(forDuration: 1.0)) {
            explosion.removeFromParent()
        }
    }
}
