//
//  MainScene.swift
//  StayFit
//
//  Created by Timothy Liew on 8/2/16.
//  Copyright © 2016 Tim Liew. All rights reserved.
//

import SpriteKit
import Firebase
import FirebaseDatabase
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKLoginKit

var home = true as Bool!

class MainScene: SKScene {
    
    var scrollCloud: SKNode!
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    var playButton: MSButtonNode!
    var creditsButton: MSButtonNode!
    var homeButton: MSButtonNode!
    var leaderboardButton: MSButtonNode!
    var wallpaper: SKNode!
    var credits: SKNode!
    var font: UIFont!
    var title: SKSpriteNode!
    var toggleOffButton: MSButtonNode!
    var toggleOnButton: MSButtonNode!
    var international:SKNode!
    
    var playerProfile = Profile()
    /* Firebase connection */
    var firebaseRef = FIRDatabase.database().referenceWithPath("/bestScore")
    /* High score custom dictionary */
    var scoreTower: [Int:Profile] = [:]
    
    override func didMoveToView(view: SKView) {
        scrollCloud = self.childNodeWithName("scrollCloud")
        playButton = self.childNodeWithName("playButton") as! MSButtonNode
        creditsButton = self.childNodeWithName("creditsButton") as! MSButtonNode
        homeButton = self.childNodeWithName("homeButton") as! MSButtonNode
        leaderboardButton = self.childNodeWithName("leaderboard") as! MSButtonNode
        wallpaper = self.childNodeWithName("wallpaper")
        credits = self.childNodeWithName("credits")
        font = UIFont(name: "Noteworthy", size: 26)
        title = self.childNodeWithName("title") as! SKSpriteNode
        toggleOffButton = self.childNodeWithName("toggleOffButton") as! MSButtonNode
        toggleOnButton = self.childNodeWithName("toggleOnButton") as! MSButtonNode
        international = self.childNodeWithName("international") as SKNode!
        
        self.view?.multipleTouchEnabled = false
        
        GameViewController.loginButton.hidden = false
        
        self.credits.hidden = true
        self.homeButton.state = .hidden
        international.hidden = true
        
        playButton.selectedHandler = {
            home = false
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load game scene */
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            scene.playerProfile = self.playerProfile
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFit
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = false
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)
        }
        
        creditsButton.selectedHandler = {
            home = false
            self.playButton.state = .hidden
            self.creditsButton.state = .hidden
            self.leaderboardButton.state = .hidden
            self.homeButton.state = .active
            self.toggleOffButton.state = .hidden
            self.toggleOnButton.state = .hidden
            self.credits.hidden = false
            self.title.hidden = true
            GameViewController.loginButton.hidden = true
            
        }
        
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
        
        leaderboardButton.selectedHandler = {
            home = false
            self.international.hidden = false
            self.playButton.state = .hidden
            self.creditsButton.state = .hidden
            self.toggleOffButton.state = .hidden
            self.toggleOnButton.state = .hidden
            self.homeButton.state = .active
            self.credits.hidden = true
            self.leaderboardButton.state = .hidden
            self.title.hidden = true
            GameViewController.loginButton.hidden = true
            
            var y = self.scrollCloud.position.y - 150
            for (highScore, player) in self.scoreTower {
                let scoreLabel = SKLabelNode(fontNamed: self.font.fontName)
                scoreLabel.fontSize = 26
                scoreLabel.color = SKColor.blackColor()
                scoreLabel.position.y = y
                scoreLabel.position.x = self.size.width * 0.5
                scoreLabel.text = "\(player.name): \(highScore)"
                //print("\(player.name): \(highScore)")
                self.addChild(scoreLabel)
                y -= 24
            }
            
        }
        
        toggleOnButton.selectedHandler = {
            tutorialCounter = 1
            self.toggleOffButton.state = .active
            self.toggleOnButton.state = .hidden
        }
        
        toggleOffButton.selectedHandler = {
            tutorialCounter = 0
            self.toggleOnButton.state = .active
            self.toggleOffButton.state = .hidden
        }
        
        let colorChange = SKAction.colorizeWithColor(.blueColor(), colorBlendFactor: 1, duration: 5)
        let colorChange1 = SKAction.colorizeWithColor(.redColor(), colorBlendFactor: 1, duration: 5)
        let colorChange2 = SKAction.colorizeWithColor(.yellowColor(), colorBlendFactor: 1, duration: 5)
        let action = SKAction.repeatActionForever(SKAction.sequence([colorChange, colorChange1, colorChange2]))
        self.wallpaper.runAction(action)
        
        /* Facebook profile lookup */
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
//            let params = ["access_token" : FBSDKAccessToken.currentAccessToken()]
//            let request = FBSDKGraphRequest(graphPath: "498071220390019/scores", parameters: params, HTTPMethod: "GET")
//            request.startWithCompletionHandler({ (connection, result, error) -> Void in
//                if (error == nil){
//                    print("No error \(result)")
//                    /* Update player profile */
//                    self.playerProfile.facebookId = result.valueForKey("id") as! String
//                    self.playerProfile.name = result.valueForKey("first_name") as! String
//                    print(self.playerProfile)
//                }
//            })

            
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    
                    /* Update player profile */
                    self.playerProfile.facebookId = result.valueForKey("id") as! String
                    self.playerProfile.name = result.valueForKey("first_name") as! String
                    print(self.playerProfile)
                }
            })
        }
        
        firebaseRef.queryOrderedByChild("score").queryLimitedToLast(5).observeEventType(.Value, withBlock: { snapshot in
            
            /* Check snapshot has results */
            if snapshot.exists() {
                
                /* Loop through data entries */
                for child in snapshot.children {
                    
                    /* Create new player profile */
                    var profile = Profile()
                    
                    /* Assign player name */
                    profile.name = child.key
                   // print("Value \(profile.name)")
                    /* Assign profile data */
                    profile.facebookId = child.value.objectForKey("id") as! String
                  //  print("ID \(profile.facebookId)")
                    profile.score = child.value.objectForKey("score") as! Int
                    self.scoreTower[profile.score] = profile
                    
                  //  print(profile)
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    override func update(currentTime: NSTimeInterval) {
        scrollWorld()
        if home == true {
            if tutorialCounter == 0 {
                self.toggleOffButton.state = .hidden
                self.toggleOnButton.state = .active
            } else {
                self.toggleOffButton.state = .active
                self.toggleOnButton.state = .hidden
            }
        } else {
            self.toggleOffButton.state = .hidden
            self.toggleOnButton.state = .hidden

        }
    }

    
    func scrollWorld() {
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
        
}