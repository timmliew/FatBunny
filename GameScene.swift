//
//  GameScene.swift
//  StayFit
//
//  Created by Timothy Liew on 6/29/16.
//  Copyright (c) 2016 Tim Liew. All rights reserved.
//

import SpriteKit
import AudioToolbox

enum GameState {
    case Active, GameOver
}

enum Size {
    case Fat, Skinny
}

class GameScene: SKScene, SKPhysicsContactDelegate  {
    
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    var scrollLayer: SKNode!
    var scrollCloud: SKNode!
    var obstacleLayer: SKNode!
    var deathLayer: SKNode!
    var referAirGround: SKNode?
    var timer: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    var foodTimer: CFTimeInterval = 0
    var evilTimer: CFTimeInterval = 0
    var groundTimer: CFTimeInterval = 0
    var waterTimer: CFTimeInterval = 0
    var sinceTouch: CFTimeInterval = 0
    var touchCounter = 0
    var wallpaper: SKNode!
    var gameState: GameState = .Active
    var hero: SKSpriteNode!
    var hero2: SKSpriteNode!
    var evilBee: SKSpriteNode!
    var replayButton: MSButtonNode!
    var sizeState: Size!
    var heroScale: CGFloat!
    var number = 0
    var levelNode: SKNode!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        scrollLayer = self.childNodeWithName("scrollLayer")
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        deathLayer = self.childNodeWithName("deathLayer")
        scrollCloud = self.childNodeWithName("scrollCloud")
        wallpaper = self.childNodeWithName("wallpaper")
        hero = self.childNodeWithName("//bunny") as! SKSpriteNode
        hero2 = self.childNodeWithName("//bunnySprite") as! SKSpriteNode
        evilBee = self.childNodeWithName("evilBee") as! SKSpriteNode
        replayButton = self.childNodeWithName("replayButton") as! MSButtonNode
        replayButton.hidden = true
        heroScale = hero.xScale
        
        if heroScale == hero.xScale {
            sizeState = .Skinny
        }
        
        /* Setup restart button selection handler */
        replayButton.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load game scene */
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFit
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = true
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)
        }
        
        let colorChange = SKAction.colorizeWithColor(.blueColor(), colorBlendFactor: 1, duration: 5)
        let colorChange1 = SKAction.colorizeWithColor(.blackColor(), colorBlendFactor: 1, duration: 5)
        let colorChange2 = SKAction.colorizeWithColor(.grayColor(), colorBlendFactor: 1, duration: 5)
        let action = SKAction.repeatActionForever(SKAction.sequence([colorChange, colorChange1, colorChange2]))
        wallpaper.runAction(action)
        
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if gameState != .Active {
            return
        }
        
        touchCounter += 1
        
        if touchCounter <= 2 {
            hero2.runAction(SKAction(named: "jump")!)
            
            /* Reset velocity, helps improve response against cumulative falling velocity */
            hero.physicsBody?.velocity = CGVectorMake(0, 0)
            
            /* Called when a touch begins */
            
            /* Apply vertical impulse */
            hero.physicsBody?.applyImpulse(CGVectorMake(0, 450))
            
            
            /* Apply subtle rotation */
            hero.physicsBody?.applyAngularImpulse(1)
            
            
            /* Reset touch timer */
            sinceTouch = 0
        }
        
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if hero.position.x >= 280 {
            hero.position.x = 280
        }
        
        if hero.position.y < 20 || hero.position.x < -self.size.width {
            gameOver()
        }
        
        if hero.xScale <= heroScale {
            hero.xScale = heroScale
            sizeState = .Skinny
        }
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        
        /* Called before each frame is rendered */
        scrollWorld()
        updateObstacles()
        
        if timer >= 5.0 {
            number += 1
            timer = 0
        }
        
        timer += fixedDelta
        
        groundTimer += fixedDelta
        
        waterTimer += fixedDelta
        
        evilTimer += fixedDelta
        
        foodTimer += fixedDelta
        
        spawnTimer += fixedDelta
        
        sinceTouch += fixedDelta
    }
    
    func scrollWorld(){
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes*/
        for ground in scrollLayer.children {
            
            if ground.name == "background" {
                
                let groundSprite = ground as! SKSpriteNode
                
                /* Get ground node position, convert node position to scene space*/
                let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
                
                /* Check if ground sprite has left the scene */
                if groundPosition.x <= -groundSprite.size.width / 2 {
                    
                    /* Reposition ground sprite to the second starting position */
                    let newPosition = CGPointMake((self.size.width / 2) + size.width, groundPosition.y)
                    
                    /* Convert new node position back to scroll layer space */
                    groundSprite.position = self.convertPoint(newPosition, toNode: scrollLayer)
                }
            }
        }
        
        /* Scroll Cloud */
        scrollCloud.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes*/
        for cloud in scrollCloud.children as! [SKSpriteNode]{
            
            /* Get ground node position, convert node position to scene space*/
            let cloudPosition = scrollCloud.convertPoint(cloud.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if cloudPosition.x <= -cloud.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake((self.size.width / 2) + size.width, cloudPosition.y)
                
                /* Convert new node position back to scroll layer space */
                cloud.position = self.convertPoint(newPosition, toNode: scrollCloud)
            }
        }
        
    }

    
    func updateObstacles(){
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        for obstacle1 in obstacleLayer.children as! [SKReferenceNode] {
            let obstacle1Position = obstacleLayer.convertPoint(obstacle1.position, toNode: self)
            
            if obstacle1Position.x <= -size.width {
                obstacle1.removeFromParent()
            }
        }
        

        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode]{
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            
            /* Check if the bunny has left the scene */
            if obstaclePosition.x <= 0 {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
//        if groundTimer >= 3.0 {
//            
//            let resourcePath = NSBundle.mainBundle().pathForResource("AirGround", ofType: "sks")
//            let airground = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
//            referAirGround = airground
//            scrollLayer.addChild(airground)
//            
//            /* Generate new obstacle position for carrots */
//            let randomPosition = CGPointMake(CGFloat.random(min: 300, max: 320), CGFloat.random(min: 200, max: 250))
//            airground.position = self.convertPoint(randomPosition, toNode: scrollLayer)
//            
////            let resourcePath2 = NSBundle.mainBundle().pathForResource("SmallAirGround", ofType: "sks")
////            let smallairground = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath2!))
////            scrollLayer.addChild(smallairground)
////            
////            /* Generate new obstacle position for carrots */
////            let randomPosition2 = CGPointMake(CGFloat.random(min: 150, max: 200), CGFloat.random(min: 200, max: 300))
////            smallairground.position = self.convertPoint(randomPosition2, toNode: scrollLayer)
//            
//            groundTimer = 0
//        }
        
        if number%3 == 0 && waterTimer >= 3.0 {
            
            let resourcePath = NSBundle.mainBundle().pathForResource("Water", ofType: "sks")
            let water = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            scrollLayer.addChild(water)
            
            /* Generate new obstacle position for carrots */
            let randomPosition = CGPointMake(CGFloat.random(min: self.size.width, max: self.size.width * 2), 500)
            water.position = self.convertPoint(randomPosition, toNode: scrollLayer)
            
            waterTimer = 0
        }
        
        if number%2 == 0 && foodTimer >= 3.0 {
            
            let resourcePath = NSBundle.mainBundle().pathForResource("Fries", ofType: "sks")
            let fries = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            scrollLayer.addChild(fries)
            
            /* Generate new obstacle position for carrots */
            let randomPosition = CGPointMake(CGFloat.random(min: self.size.width, max: self.size.width * 2), 500)
            fries.position = self.convertPoint(randomPosition, toNode: scrollLayer)
            
            foodTimer = 0
        }
        
        if evilTimer >= 3.0 {
            
            var randomPosition: CGPoint
            
            if let referAirGround = referAirGround {
                randomPosition = CGPointMake(referAirGround.position.x, referAirGround.position.y + referAirGround.frame.height + 50)
                randomPosition = scrollLayer.convertPoint(randomPosition, toNode: self)
                
                if self.physicsWorld.bodyAlongRayStart(CGPoint(x: randomPosition.x, y: randomPosition.y + 100), end: CGPoint(x: randomPosition.x, y: randomPosition.y - 500)) != nil {
                    
                    let resourcePathEvil = NSBundle.mainBundle().pathForResource("Carrot", ofType: "sks")
                    let carrot = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePathEvil!))
                    scrollLayer.addChild(carrot)
                    /* Convert new node position back to obstacle layer space */
                    
                    carrot.position = self.convertPoint(randomPosition, toNode: scrollLayer)
                }
            }
            
            evilTimer = 0
        }
        
        /* Time to add new obstacle */
        if spawnTimer >= 1.5{
            
            /* Generate new obstacle position for obstacle1 */
            let randomPosition2 = CGPointMake(self.size.width, 70)
            
            if self.physicsWorld.bodyAlongRayStart(CGPoint(x: randomPosition2.x, y: randomPosition2.y + 100), end: CGPoint(x: randomPosition2.x, y: randomPosition2.y - 200)) != nil {
            
                let resourcePath2 = NSBundle.mainBundle().pathForResource("Obstacles", ofType: "sks")
                let newObstacle2 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath2!))
                scrollLayer.addChild(newObstacle2)
                /* Convert new node position back to obstacle layer space */
                
                newObstacle2.position = self.convertPoint(randomPosition2, toNode: scrollLayer)
            }
            
            let randomPosition3 = CGPointMake(CGFloat.random(min: self.size.width, max: self.size.width * 2), 80)
            
            if self.physicsWorld.bodyAlongRayStart(CGPoint(x: randomPosition3.x, y: randomPosition3.y + 100), end: CGPoint(x: randomPosition3.x, y: randomPosition3.y - 200)) != nil {
                
                let resourcePath3 = NSBundle.mainBundle().pathForResource("Grass", ofType: "sks")
                let grass = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath3!))
                scrollLayer.addChild(grass)
                /* Convert new node position back to obstacle layer space */
                
                grass.position = self.convertPoint(randomPosition3, toNode: scrollLayer)
            }
            
            /* Reset spawn timer */
            spawnTimer = 0
        }
        
    }
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        guard let nodeA = contactA.node, nodeB = contactB.node else {
            return
        }
        //carrot disappears when it touches anything
        if (nodeA.name == "background" && nodeB.name == "carrot") || (nodeA.name == "carrot" && nodeB.name == "background") || (nodeA.name == "obstacle" && nodeB.name == "carrot") || (nodeA.name == "carrot" && nodeB.name == "obstacle") {
            if nodeA.name == "carrot" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
        }
        //carrot disappears when it touches bunny
        if (nodeA.name == "bunny" && nodeB.name == "carrot") || (nodeA.name == "carrot" && nodeB.name == "bunny")  {
            hero.position.x -= scrollSpeed + 100 * CGFloat(fixedDelta)
            if sizeState != .Skinny {
                hero.xScale -= heroScale
            }
            if nodeA.name == "carrot" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
            
        }
        //water disappears when it touches anything
        if (nodeA.name == "background" && nodeB.name == "water") || (nodeA.name == "water" && nodeB.name == "background") || (nodeA.name == "obstacle" && nodeB.name == "water") || (nodeA.name == "water" && nodeB.name == "obstacle") {
            if nodeA.name == "water" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
        }
        //water disappears when it touches bunny
        if (nodeA.name == "bunny" && nodeB.name == "water") || (nodeA.name == "water" && nodeB.name == "bunny") {
            hero.physicsBody!.velocity.dx = (scrollSpeed/2)
            if sizeState != .Skinny {
                hero.xScale -= heroScale / 2
            }
            if nodeA.name == "water" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
        }
        
        if (nodeA.name == "bunny" && nodeB.name == "evilBee") || (nodeA.name == "evilBee" && nodeB.name == "bunny") {
            hero2.runAction(SKAction(named: "hurt")!)
            
            /* Create our hero death action */
            let heroDeath = SKAction.runBlock({
                
                /* Put our hero face down in the dirt */
                self.hero.physicsBody?.applyImpulse(CGVectorMake(0, 40))
                
                /* Put our hero face down in the dirt */
                self.hero.zRotation = CGFloat(-180).degreesToRadians()
                
                /* Stop hero from colliding with anything else */
                self.hero.physicsBody?.collisionBitMask = 0
                self.hero.physicsBody?.contactTestBitMask = 0
                self.touchCounter = 5
            })
            
            hero2.runAction(heroDeath)
            
            hero2.runAction(SKAction(named: "hurt")!)
            
            
        }
        //evil disappears when it touches anything
        if (nodeA.name == "evil" && nodeB.name == "background") || (nodeA.name == "background" && nodeB.name == "evil") || (nodeA.name == "obstacle" && nodeB.name == "evil") || (nodeA.name == "evil" && nodeB.name == "obstacle") {
            if nodeA.name == "evil" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
        }
        
        //fries disappears when it touches bunny
        if (nodeA.name == "bunny" && nodeB.name == "fries") || (nodeA.name == "fries" && nodeB.name == "bunny") {
            hero.physicsBody!.velocity.dx = -(scrollSpeed / 4)
            hero.runAction(SKAction(named: "hurt")!)
            hero.xScale += heroScale / 2
            sizeState = .Fat
            hero.physicsBody?.mass += ((hero.physicsBody?.mass)! / 4)
            if nodeA.name == "fries" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
            
        }
        //fries disappears when it touches anything
        if (nodeA.name == "fries" && nodeB.name == "background") || (nodeA.name == "background" && nodeB.name == "fries") || (nodeA.name == "obstacle" && nodeB.name == "fries") || (nodeA.name == "fries" && nodeB.name == "obstacle") {
            
            if nodeA.name == "fries" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
        }
        
        if (nodeA.name == "bunny" && nodeB.name != "carrot") || (nodeA.name != "carrot" && nodeB.name == "bunny") || (nodeA.name != "bunny" && nodeB.name == "water") || (nodeA.name != "water" && nodeB.name == "bunny")  || (nodeA.name != "bunny" && nodeB.name == "fries") || (nodeA.name != "fries" && nodeB.name == "bunny") || (nodeA.name != "bunny" && nodeB.name == "airground") || (nodeA.name != "airground" && nodeB.name == "bunny"){
            touchCounter = 0
        }
        
    }
    
    func gameOver() {
        gameState = .GameOver
        replayButton.hidden = false
        self.paused = true
    }
    
}
