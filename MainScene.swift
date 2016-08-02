//
//  MainScene.swift
//  StayFit
//
//  Created by Timothy Liew on 8/2/16.
//  Copyright © 2016 Tim Liew. All rights reserved.
//

import SpriteKit

class MainScene: SKScene {
    
    var scrollCloud: SKNode!
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    var playButton: MSButtonNode!
    var tutorialButton: MSButtonNode!
    var creditsButton: MSButtonNode!
    var homeButton: MSButtonNode!
    var wallpaper: SKNode!
    var credits: SKNode!

    
    override func didMoveToView(view: SKView) {
        scrollCloud = self.childNodeWithName("scrollCloud")
        playButton = self.childNodeWithName("playButton") as! MSButtonNode
        tutorialButton = self.childNodeWithName("tutorialButton") as! MSButtonNode
        creditsButton = self.childNodeWithName("creditsButton") as! MSButtonNode
        homeButton = self.childNodeWithName("homeButton") as! MSButtonNode
        wallpaper = self.childNodeWithName("wallpaper")
        credits = self.childNodeWithName("credits")
        
        self.credits.hidden = true
        self.homeButton.state = .hidden
        
        playButton.selectedHandler = {
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
        
        
        
        tutorialButton.selectedHandler = {
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load game scene */
            let scene = TutorialScene(fileNamed: "TutorialScene") as TutorialScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFit
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = true
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)
                
        }
        
        creditsButton.selectedHandler = {
            
            self.playButton.state = .hidden
            self.tutorialButton.state = .hidden
            self.creditsButton.state = .hidden
            self.homeButton.state = .active
            self.credits.hidden = false
            
        }
        
        homeButton.selectedHandler = {
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load game scene */
            let scene = MainScene(fileNamed: "MainScene") as MainScene!
            
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
        let colorChange1 = SKAction.colorizeWithColor(.orangeColor(), colorBlendFactor: 1, duration: 5)
        let colorChange2 = SKAction.colorizeWithColor(.grayColor(), colorBlendFactor: 1, duration: 5)
        let action = SKAction.repeatActionForever(SKAction.sequence([colorChange, colorChange1, colorChange2]))
        wallpaper.runAction(action)
        
        
    }
    
    override func update(currentTime: NSTimeInterval) {
        scrollWorld()
    }
    
    func scrollWorld() {
        /* Scroll Cloud */
        scrollCloud.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes*/
        for cloud in scrollCloud.children as! [SKSpriteNode]{
            
            /* Get ground node position, convert node position to scene space*/
            let cloudPosition = scrollCloud.convertPoint(cloud.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if cloudPosition.x <= -cloud.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake((self.size.width / 2) + self.size.width, cloudPosition.y)
                
                /* Convert new node position back to scroll layer space */
                cloud.position = self.convertPoint(newPosition, toNode: scrollCloud)
            }
        }
    }
}