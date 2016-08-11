//
//  GameScene.swift
//  StayFit
//
//  Created by Timothy Liew on 6/29/16.
//  Copyright (c) 2016 Tim Liew. All rights reserved.
//

import SpriteKit
import AudioToolbox
import Firebase
import FirebaseDatabase
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKLoginKit
import AVFoundation

/* Social profile structure */
struct Profile {
    var name = ""
    var facebookId = ""
    var score = 0
}

enum GameState {
    case Active, GameOver, Pause
}

enum Size {
    case Fat, Skinny
}

var tutorialCounter = 0

class GameScene: SKScene, SKPhysicsContactDelegate  {
    
    var playerProfile = Profile()
    /* Firebase connection */
    var firebaseRef = FIRDatabase.database().referenceWithPath("/bestScore")
    
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    
    let scrollSpeed: CGFloat = 160
    var scrollLayer: SKNode!
    var scrollCloud: SKNode!
    var obstacleLayer: SKNode!
    var timer: CFTimeInterval = 0
    var tutorialTimer: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    var foodTimer: CFTimeInterval = 0
    var coinTimer: CFTimeInterval = 0
    var secondBeeTimer: CFTimeInterval = 0
    var carrotTimer: CFTimeInterval = 0
    var touchCounter = 0
    var wallpaper: SKNode!
    var gameState: GameState = .Active
    var hero: SKSpriteNode!
    var hero2: SKSpriteNode!
    var evilBee: SKSpriteNode!
    var replayButton: MSButtonNode!
    var pauseButton: MSButtonNode!
    var continueButton: MSButtonNode!
    var homeButton: MSButtonNode!
    var sizeState: Size = .Skinny
    var heroScale: CGFloat!
    var level = 0
    var pointsLabel: SKLabelNode!
    var points: Int = 0
    var bestLabel: SKLabelNode!
    var mass: CGFloat!
    var swipeBegins: CGPoint!
    var swipeEnds: CGPoint!
    var highScore: Bool = false
    var tap: SKSpriteNode!
    var swipe: SKSpriteNode!
    var font: UIFont!
    var font2: UIFont!
    var font3: UIFont!
    var tipsLabel: SKSpriteNode!
    var tipsLabel2: SKSpriteNode!
    var pausedForTapTutorial = false
    var pausedForSwipeTutorial = false
    var backgroundAudio: AVAudioPlayer!
    var touchedFirstBee = 0
    var touchedSecBee = 0

    static var stayPaused = false as Bool
    
    override var paused: Bool {
        get {
            return super.paused
        }
        set {
            if (newValue || !GameScene.stayPaused) {
                super.paused = newValue
            } else if GameScene.stayPaused && replayButton != nil {
                replayButton.hidden = false
                continueButton.hidden = false
                replayButton.hidden = false
                homeButton.hidden = false
                pauseButton.hidden = true
            }
            
            GameScene.stayPaused = false
        }
    }
    
    override func didMoveToView(view: SKView) {
        GameViewController.loginButton.hidden = true
        do {
            try backgroundAudio = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath:NSBundle.mainBundle().pathForResource("Happy Tune",ofType:"wav")!))
                backgroundAudio.numberOfLoops = -1
        }
        catch {
            
        }
        
        /* Setup your scene here */
        font = UIFont(name: "Noteworthy", size: 26)
        font2 = UIFont(name: "Noteworthy", size: 18)
        font3 = UIFont(name: "Noteworthy", size: 26)
        scrollLayer = self.childNodeWithName("scrollLayer")
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        scrollCloud = self.childNodeWithName("scrollCloud")
        wallpaper = self.childNodeWithName("wallpaper")
        hero = self.childNodeWithName("//bunny") as! SKSpriteNode
        hero2 = self.childNodeWithName("//bunnySprite") as! SKSpriteNode
        evilBee = self.childNodeWithName("evilBee") as! SKSpriteNode
        replayButton = self.childNodeWithName("replayButton1") as! MSButtonNode
        pauseButton = self.childNodeWithName("pause") as! MSButtonNode
        continueButton = self.childNodeWithName("continueButton") as! MSButtonNode
        homeButton = self.childNodeWithName("homeButton") as! MSButtonNode
        pointsLabel = self.childNodeWithName("pointsLabel") as! SKLabelNode
        heroScale = hero2.xScale
        pointsLabel.text = String(points)
        bestLabel = self.childNodeWithName("bestLabel") as! SKLabelNode
        bestLabel.text = String(NSUserDefaults.standardUserDefaults().integerForKey("bestLabel"))
        mass = hero.physicsBody?.mass
        swipe = self.childNodeWithName("swipe") as! SKSpriteNode
        tap = self.childNodeWithName("tap") as! SKSpriteNode
        
        self.view?.multipleTouchEnabled = false
        
        self.tap.hidden = true
        self.swipe.hidden = true
        self.replayButton.hidden = true
        self.continueButton.hidden = true
        self.replayButton.hidden = true
        self.homeButton.hidden = true
        self.pauseButton.hidden = false
        
        homeButton.selectedHandler = {
            home = true
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load game scene */
            let scene = MainScene(fileNamed: "MainScene") as MainScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFit
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = false
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)
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
            skView.showsDrawCount = false
            skView.showsFPS = false
            
            /* Restart game scene */
            scene.playerProfile = self.playerProfile
            skView.presentScene(scene)
        }
        
        pauseButton.selectedHandler = {
            self.gameState = .Pause
            self.backgroundAudio.pause()
            if self.tipsLabel.hidden == false || self.tipsLabel2.hidden == false {
                self.tipsLabel.hidden = true
                self.tipsLabel2.hidden = true
            }
            self.pauseButton.hidden = true
            self.continueButton.hidden = false
            self.replayButton.hidden = false
            self.homeButton.hidden = false
            self.tap.hidden = true
            self.swipe.hidden = true
            self.gameState = .Pause
            self.paused = true
            self.physicsWorld.speed = 0
        }
        
        continueButton.selectedHandler = {
            self.gameState = .Active
            self.pauseButton.hidden = false
            self.homeButton.hidden = true
            self.replayButton.hidden = true
            self.continueButton.hidden = true
            self.paused = false
            self.physicsWorld.speed = 1
            self.backgroundAudio.play()
        }
        
        let colorChange = SKAction.colorizeWithColor(.blueColor(), colorBlendFactor: 1, duration: 5)
        let colorChange1 = SKAction.colorizeWithColor(.redColor(), colorBlendFactor: 1, duration: 5)
        let colorChange2 = SKAction.colorizeWithColor(.yellowColor(), colorBlendFactor: 1, duration: 5)
        let action = SKAction.repeatActionForever(SKAction.sequence([colorChange, colorChange1, colorChange2]))
        self.wallpaper.runAction(action)
        
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        
        let swipeRight:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.respondToSwipe(_:)))
        swipeRight.direction = .Right
        view.addGestureRecognizer(swipeRight)
        
        
        let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.respondToSwipe(_:)))
        swipeLeft.direction = .Left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.respondToSwipe(_:)))
        swipeDown.direction = .Down
        view.addGestureRecognizer(swipeDown)
        
        tipsLabel = self.childNodeWithName("tipsLabel") as! SKSpriteNode
        tipsLabel.hidden = true
        tipsLabel2 = self.childNodeWithName("tipsLabel2") as! SKSpriteNode
        tipsLabel2.hidden = true
        
        if tutorialCounter == 0 {
            
            if gameState == .Pause || gameState == .Active {
                tipsLabel.runAction(SKAction.sequence([
                    SKAction.waitForDuration(5),
                    SKAction.unhide(),
                    SKAction.waitForDuration(5),
                    SKAction.removeFromParent()
                    ]))
                
                tipsLabel2.runAction(SKAction.sequence([
                    SKAction.waitForDuration(10),
                    SKAction.unhide(),
                    SKAction.waitForDuration(5),
                    SKAction.removeFromParent()
                    ]))
                
                self.runAction(SKAction.sequence([
                    SKAction.waitForDuration(1),
                    SKAction.runBlock({
                        self.paused = true
                        self.tap.hidden = false
                        self.pausedForTapTutorial = true
                    })
                ]))
                
                self.runAction(SKAction.sequence([
                    SKAction.waitForDuration(5.0),
                    SKAction.runBlock({
                        self.paused = true
                        self.swipe.hidden = false
                        self.pausedForSwipeTutorial = true
                    })
                ]))
            }
        }
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch ended */
        if self.paused && self.pausedForTapTutorial {
            self.paused = false
            self.tap.hidden = true
            self.pausedForTapTutorial = false
        }
        
        touchCounter += 1
        
        if touchCounter <= 2 {
            self.runAction(SKAction.playSoundFileNamed("Jump", waitForCompletion: false))
            hero2.runAction(SKAction(named: "jump")!)
            
            /* Reset velocity, helps improve response against cumulative falling velocity */
            hero.physicsBody?.velocity = CGVectorMake(0, 0)
            
            /* Called when a touch begins */
            
            /* Apply vertical impulse */
            hero.physicsBody?.applyImpulse(CGVectorMake(0, 600))
            
            
            /* Apply subtle rotation */
            hero.physicsBody?.applyAngularImpulse(1)
        }
    }

   
    override func update(currentTime: CFTimeInterval) {
  
        /* Called before each frame is rendered */
        if gameState == .GameOver || gameState == .Pause {
            backgroundAudio.pause()
        } else {
            backgroundAudio.play()
        }
        
        if hero.position.x >= 200 {
            hero.position.x = 200
        }
    
        if hero.position.y < 40 || hero.position.x < -self.size.width {
            gameOver()
        }
        
        if sizeState == .Fat  {
            hero.physicsBody?.applyForce(CGVector(dx: -25, dy: 0))
        } else {
            hero.physicsBody?.applyForce(CGVector(dx: 0, dy: 0))
        }
        
        if hero2.xScale <= heroScale {
            hero.physicsBody?.mass = mass
            hero2.xScale = heroScale
            sizeState = .Skinny
        } else {
            sizeState = .Fat
        }
        
        if hero2.xScale >= heroScale * 2 {
            hero2.xScale = heroScale * 2
        }
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 600 {
            hero.physicsBody?.velocity.dy = 550
        }
        
        /* Called before each frame is rendered */
        evilBee.position.x = beeAttackBunny(hero.position.x)
        
        scrollWorld()
        updateObstacles()
        
        timer += fixedDelta
        
        tutorialTimer += fixedDelta
        
        secondBeeTimer += fixedDelta
        
        carrotTimer += fixedDelta
        
        coinTimer += fixedDelta
        
        foodTimer += fixedDelta
        
        spawnTimer += fixedDelta
    }
    
    func beeAttackBunny(position: CGFloat) -> CGFloat {
        let x = position / 200.0
        
        let a: CGFloat = 25.0
        let b: CGFloat = -25.0
        
        let result = a + ((b - a) * x)
        
        return result
    }
    
    func scrollWorld(){
        scrollLayer.position.x -= (scrollSpeed + CGFloat(points / 6)) * CGFloat(fixedDelta)
        
        if scrollLayer.position.x < size.width * CGFloat(level + 1) * -5.0 {
            if timer >= 5.0 {
                level += 1
                timer = 0
            }
            
            for child in scrollLayer.children {
                if child.name == "background" {
                    child.name = "backgroundOld"
                }
            }
            
            let resourcePath = NSBundle.mainBundle().pathForResource("Level\((level % 4) + 1)", ofType: "sks")
            let levelFirst = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            
            let offset = self.convertPoint(CGPoint(x: self.size.width * 1.5 + 40, y: 0), toNode: scrollLayer).x
            for child in levelFirst.children[0].children {
                child.removeFromParent()
                child.position.x += offset
                scrollLayer.addChild(child)
            }
        }
        
        /* Loop through scroll layer nodes*/
        for ground in scrollLayer.children {
            
            if ground.name == "background" {
                
                let groundSprite = ground as! SKSpriteNode
                
                /* Get ground node position, convert node position to scene space*/
                let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
                
                /* Check if ground sprite has left the scene */
                if groundPosition.x <= -groundSprite.size.width / 2 {
                    
                    /* Reposition ground sprite to the second starting position */
                    ground.position.x += size.width * 1.5
                }
                
            } else if ground.name == "backgroundOld" {
                
                let groundSprite = ground as! SKSpriteNode
                
                /* Get ground node position, convert node position to scene space*/
                let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
                
                /* Check if ground sprite has left the scene */
                if groundPosition.x <= -groundSprite.size.width / 2 {
                    
                    /* Reposition ground sprite to the second starting position */
                    ground.removeFromParent()
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
            if cloudPosition.x < -cloud.size.width / 2 {
                cloud.position.x += cloud.size.width * 2
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
        
        if foodTimer >= 4.0 {
            
            let resourcePath = NSBundle.mainBundle().pathForResource("Fries", ofType: "sks")
            let fries = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            scrollLayer.addChild(fries)
            
            /* Generate new obstacle position for water */
            let randomPosition = CGPointMake(CGFloat.random(min: self.size.width + (self.size.width / 2), max: self.size.width * 2), 500)
            fries.position = self.convertPoint(randomPosition, toNode: scrollLayer)
            
            foodTimer = 0
        }
        
        if carrotTimer >= 2.0 {
            
            let topRight = CGPointMake(self.size.width, self.size.height)
            let bottomRight = CGPointMake(self.size.width, 0)
            
            let collision = self.physicsWorld.bodyAlongRayStart(topRight, end: bottomRight)
            
            if let collisionNode = collision?.node {
                
                let resourcePath = NSBundle.mainBundle().pathForResource("Carrot", ofType: "sks")
                let carrot = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
                scrollLayer.addChild(carrot)
                /* Convert new node position back to obstacle layer space */
                
                carrot.position.x = self.convertPoint(topRight, toNode: scrollLayer).x + 30
                carrot.position.y = collisionNode.convertPoint(CGPoint(x: 0, y: 0), toNode: scrollLayer).y + 50
            }
            carrotTimer = 0
        }
        
        if coinTimer >= 3.0 {
            
            let topRight = CGPointMake(self.size.width, self.size.height)
            let bottomRight = CGPointMake(self.size.width, 0)
            
            let collision = self.physicsWorld.bodyAlongRayStart(topRight, end: bottomRight)
            
            if let collisionNode = collision?.node {
                let coins = SKSpriteNode(imageNamed: "coin_gold")
                coins.name = "coins"
                let coin = SKPhysicsBody (texture: coins.texture!, size: CGSize(width: 55,height: 55))
                coins.physicsBody = coin
                coins.physicsBody!.affectedByGravity = true
                coins.physicsBody!.allowsRotation = false
                coins.physicsBody!.categoryBitMask = 4
                coins.physicsBody!.collisionBitMask = 2
                coins.physicsBody!.contactTestBitMask = 1
                coins.physicsBody!.linearDamping = 10
                coins.size = CGSize(width: 55,height: 55)
                scrollLayer.addChild(coins)
                
                /* Convert new node position back to obstacle layer space */
                coins.position.x = self.convertPoint(topRight, toNode: scrollLayer).x + 30
                coins.position.y = collisionNode.convertPoint(CGPoint(x: 0, y: 0), toNode: scrollLayer).y + 50
            }
            
            coinTimer = 0
        }
        if points >= 70 {
            if points % 10 == 2 {
                if secondBeeTimer > 5.0 {
                    let secondBee = SKSpriteNode(imageNamed: "evilBee")
                    secondBee.name = "secondBee"
                    let secBee = SKPhysicsBody(circleOfRadius: secondBee.size.width * 0.5)
                    secondBee.zPosition = 1
                    secondBee.physicsBody = secBee
                    secondBee.physicsBody!.dynamic = false
                    secondBee.physicsBody!.affectedByGravity = false
                    secondBee.physicsBody!.categoryBitMask = 16
                    secondBee.physicsBody!.collisionBitMask = 0
                    secondBee.physicsBody!.contactTestBitMask = 1
                    secondBee.setScale(0.5)
                    secondBee.position = self.convertPoint(CGPoint(x: self.size.width * 2, y: 180), toNode: scrollLayer)
                    
                    scrollLayer.addChild(secondBee)
                    
                    secondBee.runAction(SKAction.repeatActionForever(SKAction(named: "fly")!))
                    
                    secondBeeTimer = 0
                    
                }
            }
        }
        
        /* Time to add new obstacle */
        if hero.position.x >= self.size.width / 2{
            
            if spawnTimer >= 0.8 {
            
                let topRight = CGPointMake(self.size.width, self.size.height)
                let bottomRight = CGPointMake(self.size.width, 0)
                
                let collision = self.physicsWorld.bodyAlongRayStart(topRight, end: bottomRight)
                
                if let collisionNode = collision?.node {
                    
                    if collisionNode.name!.hasPrefix("background") {
                    
                        let resourcePath = NSBundle.mainBundle().pathForResource("Obstacles", ofType: "sks")
                        let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
                        scrollLayer.addChild(newObstacle)
                        /* Convert new node position back to obstacle layer space */
                        
                        newObstacle.position.x = self.convertPoint(topRight, toNode: scrollLayer).x
                        newObstacle.position.y = collisionNode.convertPoint(CGPoint(x: 0, y: 0), toNode: scrollLayer).y + 50
                    }
                }
                
                let topRight2 = CGPointMake(self.size.width, self.size.height)
                let bottomRight2 = CGPointMake(self.size.width, 0)
                let collision2 = self.physicsWorld.bodyAlongRayStart(topRight2, end: bottomRight2)
                
                if let collisionNode2 = collision2?.node {
                    
                    if collisionNode2.name!.hasPrefix("background") {
                        
                        let resourcePath2 = NSBundle.mainBundle().pathForResource("Grass", ofType: "sks")
                        let grass = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath2!))
                        scrollLayer.addChild(grass)
                        /* Convert new node position back to obstacle layer space */
                        
                        grass.position.x = self.convertPoint(topRight2, toNode: scrollLayer).x
                        grass.position.y = collisionNode2.convertPoint(CGPoint(x: 0, y: 0), toNode: scrollLayer).y + 50
                    }
                }
            
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
        //carrot disappears when it touches bunny
        if (nodeA.name == "bunny" && nodeB.name == "carrot") || (nodeA.name == "carrot" && nodeB.name == "bunny")  {
            hero2.removeActionForKey("Growing")
            hero.physicsBody!.velocity.dx = (scrollSpeed / 2)
            self.runAction(SKAction.playSoundFileNamed("Chomp", waitForCompletion: false))
            if sizeState != .Skinny || hero.physicsBody?.mass > mass {
                hero2.runAction(SKAction.sequence([
                    SKAction.scaleXTo(hero2.xScale - heroScale / 4, duration: 0.15),
                    SKAction.scaleXTo(hero2.xScale, duration: 0.15),
                    SKAction.scaleXTo(hero2.xScale - heroScale / 4, duration: 0),
                    ]), withKey: "Growing")

                
                hero.physicsBody?.mass -= mass / 4
            }
            if gameState != .GameOver {
                points += 1
                pointsLabel.text = String(points)
                let scoreLabel = SKLabelNode(fontNamed: font3.fontName)
                scoreLabel.fontSize = 26
                scoreLabel.color = SKColor.blackColor()
                scoreLabel.position = hero.convertPoint(CGPoint(x:0, y: 10), toNode: scrollLayer)
                scrollLayer.addChild(scoreLabel)
                scoreLabel.text = "+1"
                scoreLabel.runAction(SKAction.fadeOutWithDuration(1))
                scoreLabel.runAction(SKAction.sequence([
                    SKAction.moveByX(0, y: 30, duration: 1),
                    SKAction.removeFromParent()
                    ]))
                
                if points > Int(bestLabel.text!) {
                    bestLabel.text = String(points)
                    
                    if highScore == false {
                        highScore = true
                        let newHS = SKSpriteNode(imageNamed: "newhighscore")
                        newHS.setScale(0.5)
                        newHS.position = hero.convertPoint(CGPoint(x:0, y: 20), toNode: scrollLayer)
                        scrollLayer.addChild(newHS)
                        newHS.runAction(SKAction.fadeOutWithDuration(1))
                        newHS.runAction(SKAction.sequence([
                            SKAction.moveByX(0, y: 50, duration: 1),
                            SKAction.removeFromParent()
                            ]))
                    }
                }
                
            }
            
            if nodeA.name == "carrot" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
            
        }
        
       
        //coins disappears when it touches bunny
        if (nodeA.name == "bunny" && nodeB.name == "coins") || (nodeA.name == "coins" && nodeB.name == "bunny") {
            if gameState != .GameOver {
                points += 2
                pointsLabel.text = String(points)
                let scoreLabel = SKLabelNode(fontNamed: font3.fontName)
                scoreLabel.fontSize = 26
                scoreLabel.color = SKColor.blackColor()
                scoreLabel.position = hero.convertPoint(CGPoint(x:0, y: 10), toNode: scrollLayer)
                scrollLayer.addChild(scoreLabel)
                scoreLabel.text = "+2"
                scoreLabel.runAction(SKAction.fadeOutWithDuration(1))
                scoreLabel.runAction(SKAction.sequence([
                    SKAction.playSoundFileNamed("Power Up", waitForCompletion: false),
                    SKAction.moveByX(0, y: 30, duration: 1),
                    SKAction.removeFromParent()
                    ]))
                
                if points > Int(bestLabel.text!) {
                    bestLabel.text = String(points)
                    
                    if highScore == false {
                        highScore = true
                        let newHS = SKSpriteNode(imageNamed: "newhighscore")
                        newHS.setScale(0.5)
                        newHS.position = hero.convertPoint(CGPoint(x:0, y: 20), toNode: scrollLayer)
                        scrollLayer.addChild(newHS)
                        newHS.runAction(SKAction.fadeOutWithDuration(1))
                        newHS.runAction(SKAction.sequence([
                            SKAction.moveByX(0, y: 50, duration: 1),
                            SKAction.removeFromParent()
                            ]))
                    }
                }
                
            }
            
            if nodeA.name == "coins" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
        }
        
        if (nodeA.name == "bunny" && nodeB.name == "evilBee") || (nodeA.name == "evilBee" && nodeB.name == "bunny") {
            if touchedFirstBee == 0 {
                touchedFirstBee = 1
//                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                hero2.runAction(SKAction.sequence([
                    SKAction.playSoundFileNamed("Game Over", waitForCompletion: false),
                    SKAction(named: "hurt")!,
                    SKAction(named: "jump")!,
                    SKAction(named: "hurt")!,
                ]))
                death()
            }
        }
        
        if (nodeA.name == "bunny" && nodeB.name == "secondBee") || (nodeA.name == "secondBee" && nodeB.name == "bunny") {
            if touchedSecBee == 0 {
                touchedSecBee = 1
//                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                hero2.runAction(SKAction.sequence([
                    SKAction.playSoundFileNamed("Game Over", waitForCompletion: false),
                    SKAction(named: "hurt")!,
                    SKAction(named: "jump")!,
                    SKAction(named: "hurt")!,
                    ]))
                death()
            }
        }
        
        //fries disappears when it touches bunny
        if (nodeA.name == "bunny" && nodeB.name == "fries") || (nodeA.name == "fries" && nodeB.name == "bunny") {
            hero2.removeActionForKey("Growing")
            hero2.runAction(SKAction.sequence([
                SKAction.playSoundFileNamed("Growing", waitForCompletion: false),
                SKAction(named: "hurt")!,
                SKAction.scaleXTo(hero2.xScale + heroScale / 4, duration: 0.15),
                SKAction.scaleXTo(hero2.xScale, duration: 0.15),
                SKAction.scaleXTo(hero2.xScale + heroScale / 4, duration: 0),
                ]), withKey: "Growing")
            sizeState = .Fat
            if hero.physicsBody?.mass <= mass * 2 {
                hero.physicsBody?.mass += mass / 4
            }
            if nodeA.name == "fries" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
            
        }
        
        if (nodeA.name == "bunny" && nodeB.name!.hasPrefix("background")) {
            if nodeA.position.y > nodeB.position.y {
                touchCounter = 0
            }
        } else if (nodeA.name!.hasPrefix("background") && nodeB.name == "bunny") {
            if nodeB.position.y > nodeA.position.y {
                touchCounter = 0
            }
        }

        
        if (nodeA.name == "bunny" && nodeB.name == "obstacle") || (nodeA.name == "obstacle" && nodeB.name == "bunny") {
            touchCounter = 0
        }
        
    }
    
    func death() {
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
    }
    
    func respondToSwipe(sender: UISwipeGestureRecognizer) {
        if self.paused && self.pausedForSwipeTutorial {
            self.paused = false
            self.swipe.hidden = true
            self.pausedForSwipeTutorial = false
            tutorialCounter = 1
        }
        if gameState == .Active {
            if let swipeGesture = sender as? UISwipeGestureRecognizer {
                switch swipeGesture.direction {
                case UISwipeGestureRecognizerDirection.Left:
                    hero.physicsBody!.velocity.dx = -(scrollSpeed * 1.25)
                    let wind = SKSpriteNode(imageNamed: "wind")
                    wind.setScale(0.3)
                    wind.position = hero.convertPoint(CGPoint(x: 100, y: -20), toNode: scrollLayer)
                    scrollLayer.addChild(wind)
                    wind.runAction(SKAction.moveByX(-30, y: 0, duration: 1))
                    wind.runAction(SKAction.sequence([
                        SKAction.fadeOutWithDuration(1),
                        SKAction.removeFromParent()
                        ]))
                    
                case UISwipeGestureRecognizerDirection.Right:
                    hero.physicsBody!.velocity.dx = (scrollSpeed * 1.25)
                    let wind = SKSpriteNode(imageNamed: "wind")
                    wind.setScale(0.3)
                    wind.xScale = wind.xScale * -1
                    wind.position = hero.convertPoint(CGPoint(x: -100, y: -20), toNode: scrollLayer)
                    scrollLayer.addChild(wind)
                    wind.runAction(SKAction.moveByX(30, y: 0, duration: 1))
                    wind.runAction(SKAction.sequence([
                        SKAction.fadeOutWithDuration(1),
                        SKAction.removeFromParent()
                        ]))
                    
                    
                case UISwipeGestureRecognizerDirection.Down:
                    hero.physicsBody!.applyImpulse(CGVectorMake(0, -50))
                    
                default:
                    break
                }
            }
        }
    }
    
    func gameOver() {
        var tempPosition = continueButton.position
        gameState = .GameOver
        self.tap.hidden = true
        self.swipe.hidden = true
        self.tipsLabel.hidden = true
        self.tipsLabel2.hidden = true
        self.continueButton.state = .hidden
        homeButton.position.y = replayButton.position.y + 30
        homeButton.hidden = false
        replayButton.position.y = tempPosition.y + 30
        replayButton.hidden = false
        pauseButton.hidden = true
        self.runAction(SKAction.runBlock({ 
            SKAction.playSoundFileNamed("Game Over", waitForCompletion: false)
            SKAction.waitForDuration(5)
            self.paused = true
            self.backgroundAudio.pause()
        }))
        
        /* Check for new high score and has a facebook user id */
        
        if points > NSUserDefaults.standardUserDefaults().integerForKey("bestLabel") {
            NSUserDefaults.standardUserDefaults().setInteger(points, forKey: "bestLabel")
            NSUserDefaults.standardUserDefaults().synchronize()
            
           // print(playerProfile)
            if !playerProfile.facebookId.isEmpty {
                
                //* Update profile score */
                playerProfile.score = points
                
                /* Build data structure to be saved to firebase */
                let saveProfile = [playerProfile.name :
                    ["score" : playerProfile.score,
                        "id" : playerProfile.facebookId ]]
                
                /* Save to Firebase */
                firebaseRef.updateChildValues(saveProfile, withCompletionBlock: {
                    (error:NSError?, ref:FIRDatabaseReference!) in
                    if (error != nil) {
                        print("Data save failed: ",error)
                    } else {
                        print("Data saved success")
                    }
                })
                
            }
            
        }
    }
    
}
