//
//  GameScene.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/8/16.
//  Copyright (c) 2016 Ross Justin. All rights reserved.
//

/*
 TODO:
 check hero linear damping: sometimes it gets reset to default
 */

import SpriteKit

enum GameState {
    case Paused, Active, GameOver
}

enum ObstacleType {
    case MarchingLine, Door, BackAndForth
}

enum MovingDirection {
    case Left, Right
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero:MSReferenceNode!
    var isTouching = false
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var gameTimeStamp:CFTimeInterval = 0
    var enemyTimer: CFTimeInterval = 0
    let enemyDelaySeconds:CFTimeInterval = 0.1
    var enemies = Set<Enemy>()
    
    var background:SKSpriteNode!
    var startingPlatform:SKSpriteNode!
    //var scoreLabel:SKLabelNode!
    
    var impulseX:CGFloat = 0.0
    var impulseXContinuous:CGFloat = 0.05
    var cam:SKCameraNode!
    let gravityInWater:CGFloat = -2.0
    let gravityOutOfWater:CGFloat = -9.0
    var gameState:GameState = .Active
    var frameCenter:CGFloat = 0
    
    var score = 0
    var nextGoalHeight:CGFloat = 120
    
    var leftBoundary:CGFloat = 0
    var rightBoundary:CGFloat = 0
    
    //obstacle
    var obstacles = Set<Obstacle>()
    var levels = [Level]()
    
    
    override func didMoveToView(view: SKView) {
        background = childNodeWithName("background") as! SKSpriteNode
        startingPlatform = childNodeWithName("startingPlatform") as! SKSpriteNode
        //scoreLabel = hero.childNodeWithName("//scoreLabel") as! SKLabelNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        frameCenter = self.frame.width / 2
        
        hero.hero.position = CGPoint(x: frameCenter, y: 200) //  + hero.hero.size.width
        addChild(hero)
        
        physicsWorld.contactDelegate = self
        
        /* Camera */
        cam = SKCameraNode() //initialize and assign an instance of SKCameraNode to the cam variable.
        cam.scaleAsPoint = CGPoint(x: 1.5, y: 1.5) //the scale sets the zoom level of the camera on the given position
        
        self.camera = cam //set the scene's camera to reference cam
        self.addChild(cam) //make the cam a childElement of the scene itself.
        
        //position the camera on the gamescene.
        cam.position = CGPoint(x: hero.hero.position.x, y: hero.hero.position.y)
        
        self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
        
        levels.append(Level.init(timerDelayValue: 1.8, yPosition: 600, rectDimensions: CGSizeMake(70, 20), direction: .Right, speed: 1.8)) // B (visual only)
        levels.append(Level.init(timerDelayValue: 1.1, yPosition: 480, rectDimensions: CGSizeMake(40, 20), direction: .Left, speed: 1.8)) // A (top)
        levels.append(Level.init(timerDelayValue: 1.0, yPosition: 360, rectDimensions: CGSizeMake(40, 20), direction: .Right, speed: 3.5)) // C
        levels.append(Level.init(timerDelayValue: 2.1, yPosition: 240, rectDimensions: CGSizeMake(80, 20), direction: .Left, speed: 1.7))
        levels.append(Level.init(timerDelayValue: 2.0, yPosition: 120, rectDimensions: CGSizeMake(80, 20), direction: .Right, speed: 2.1))
        // hero starting position
        levels.append(Level.init(timerDelayValue: 1.8, yPosition: 0, rectDimensions: CGSizeMake(70, 20), direction: .Right, speed: 1.8)) // B
        levels.append(Level.init(timerDelayValue: 1.1, yPosition: -120, rectDimensions: CGSizeMake(40, 20), direction: .Left, speed: 1.8)) // A (bottom)
        levels.append(Level.init(timerDelayValue: 1.0, yPosition: -240, rectDimensions: CGSizeMake(40, 20), direction: .Right, speed: 3.5)) // C (visual only)
        

        for level in levels {
            addObstacle(level)
                var xPos:CGFloat = leftBoundary
                let spaceBetweenObstacles = CGFloat(level.timerDelayValue*60)
                
                if level.direction == .Left {
                    xPos = rightBoundary
                }
                
                for i in 1...10 {
                    addObstacle(level, specifiedPosition: CGPoint(x: xPos, y: CGFloat(level.yPosition)))
                    
                    if level.direction == .Right {
                        xPos += spaceBetweenObstacles
                    }
                    else {
                        xPos -= spaceBetweenObstacles
                    }
                }
            }
    }
    
    //MARK: Update
    override func update(currentTime: CFTimeInterval) {
        if gameState == .Paused {
            
        }
        else if gameState == .GameOver {
            restartGame()
        }
        else if gameState == .Active {
            /* Called before each frame is rendered */
            gameTimeStamp += fixedDelta
            
            if hero.hero.position.y > nextGoalHeight {
                score += 1
                nextGoalHeight += 120
                if nextGoalHeight > self.frame.height { // passed level A
                    nextGoalHeight = 0
                }
            }
            
            //scoreLabel.text = String(score)
            
            if hero.hero.position.y > self.size.height * 2 {
                if startingPlatform != nil {
                    startingPlatform.removeFromParent()
                }
                hero.hero.position.y = -self.size.height / 2
            }
            
            if hero.hero.position.y < -self.size.height {
                hero.hero.position.y = self.size.height * 2
            }
            
            
            if isTouching {
                //print("xMOD: \(impulseX)")
                hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseX, 0.25))
            }
            //hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseXContinuous, 0))
            
            if hero.hero.position.y > background.frame.height {
                self.physicsWorld.gravity = CGVectorMake(0.0, gravityOutOfWater);
            }
            else{
                self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
            }
            
            var camPosition = hero.hero.position
            camPosition.x -= hero.hero.size.width
            
            let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 1.0/60.0)
            cam.runAction(moveCamToPlayer)
            
            
            //let speedMultiplier = 50.0
            //let speedUpDuration = 0.5 // in seconds
            
            
            for level in levels {
                /*
                // use fillsX?
                if gameTimeStamp <= speedUpDuration { // less than x seconds since game started
                    
                    level.timerDelayValue = level.initialTimerDelayValue / speedMultiplier
                    //level.speed = level.initialSpeed * CGFloat(speedMultiplier)
                }
                else {
                    level.timerDelayValue = level.initialTimerDelayValue
                    //level.speed = level.initialSpeed
                }
                */
                if level.timerCounter >= level.timerDelayValue {
                    addObstacle(level)
                    level.timerCounter = 0
                }
                else {
                    level.timerCounter += fixedDelta
                }
            }
            
            /*
            for obstacle in obstacles {
                if gameTimeStamp <= speedUpDuration { // less than x seconds since game started
                    obstacle.movementSpeed = obstacle.initialMovementSpeed * CGFloat(speedMultiplier)
                }
                else {
                    obstacle.movementSpeed = obstacle.initialMovementSpeed
                }
                
            }
             */
            
            
            moveObstacles()
            removeObstaclesOutOfBounds()
            
            /*
            enemyTimer += fixedDelta
            
            if enemyTimer >= enemyDelaySeconds {
                //addRandomEnemy()
                enemyTimer = 0
            }
 
 
            moveEnemies()
            removeEnemiesOutOfBounds()
            
            moveObstacles()
            removeObstaclesOutOfBounds()
            */
            
            // keep hero centered in X
            /*
             if hero.hero.position.x > screenWidth / 2 {
             hero.hero.position.x = screenWidth / 2
             }
             else if hero.hero.position.x < screenWidth / 2 {
             hero.hero.position.x = screenWidth / 2
             }
             */
        }
    }
 
    //MARK: Obstacles
    func addObstacle(level:Level, specifiedPosition:CGPoint? = nil){
        let xPos = level.direction == .Right ? frameCenter - 300 : frameCenter + 100
        var position = CGPoint(x:Int(xPos), y:level.yPosition)
        
        if specifiedPosition != nil {
            position = specifiedPosition!
        }
        
        //let obstacle = Obstacle.init(circleOfRadius: radius)
        
        let obstacle = Obstacle.init(rect:CGRect(origin:position, size:level.rectDimensions))
        obstacle.name = "obs"
        
        let rectCenter = CGPointMake(position.x + level.rectDimensions.width / 2, position.y + level.rectDimensions.height / 2)
        
        obstacle.physicsBody = SKPhysicsBody.init(rectangleOfSize: level.rectDimensions, center: rectCenter)
        obstacle.physicsBody?.dynamic = true
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.categoryBitMask = 8
        obstacle.physicsBody?.collisionBitMask = 0//4294967295 // 0
        obstacle.physicsBody?.contactTestBitMask = 1
        
        if level.direction == .Right {
            obstacle.movementSpeed = level.speed
        }
        else { // Left
            obstacle.movementSpeed = -level.speed
        }
        
        obstacle.initialMovementSpeed = obstacle.movementSpeed
        
        obstacle.position = position
        
        addChild(obstacle)
        obstacles.insert(obstacle)
    }
    
    func moveObstacles(){
        for obstacle in obstacles {
            let move = SKAction.moveBy(CGVector(dx: obstacle.movementSpeed, dy: 0), duration: 0.5)
            obstacle.runAction(move)
        }
    }
    
    func removeObstaclesOutOfBounds(){
        var tempSet:[Obstacle] = []
        for obstacle in obstacles {
            if (obstacle.direction == .Right && obstacle.position.x > self.frame.width + 200) ||
                (obstacle.direction == .Left && obstacle.position.x < -200) {
                tempSet.append(obstacle)
            }
        }
        enemyTimer += fixedDelta
        
        for obstacle in tempSet {
            obstacles.remove(obstacle)
            obstacle.removeFromParent()
        }
        tempSet.removeAll()
    }
    
    //MARK: Physics
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if (nodeA.name == "hero" && nodeB.name == "obs"){
            heroObstacleContact(nodeA as! Hero, obstacle: nodeB as! Obstacle)
        }
        else if (nodeA.name == "obs" && nodeB.name == "hero") {
            heroObstacleContact(nodeB as! Hero, obstacle: nodeA as! Obstacle)
        }
        
        /*
        if (nodeA.name == "hero" && nodeB.name == "enemy"){
            heroEnemyContact(nodeA as! Hero, enemy: nodeB as! Enemy)
        }
        else if (nodeA.name == "enemy" && nodeB.name == "hero") {
            heroEnemyContact(nodeB as! Hero, enemy: nodeA as! Enemy)
        }
         */
    }
    
    func heroObstacleContact(hero:Hero, obstacle:Obstacle){
        gameState = .GameOver
    }
    
    func heroEnemyContact(hero:Hero, enemy:Enemy){
        //print("enemy size: \(enemy.sizeValue)")
        //print("hero size: \(hero.sizeValue)")
        //print("hero contacted enemy")
        
        if hero.sizeValue > enemy.sizeValue {
            enemy.runAction(SKAction.removeFromParent())
            enemies.remove(enemy)
            hero.sizeValue += 0.05
            hero.runAction(SKAction.scaleTo(hero.sizeValue, duration: 0.2))
        }
        else{
            gameState = .GameOver
        }
    }
    
    //MARK: Touch
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = true
        
        /*
         impulseX = CGRectGetMidX(self.frame)
         
         for touch in touches {
         if touch == touches.first {
         //let position = touch.locationInNode(self)
         let position = touch.locationInView(self.view)
         impulseX = position.x
         //print("raw x: \(impulseX)")
         }
         }
         
         impulseX = impulseX / self.frame.width
         impulseX *= 2
         impulseX -= 1.2
         impulseX /= 15
         */
        
        /*
         let touch = touches.first
         let position = touch!.locationInView(self.view)
         let touchX = position.x
         //print("raw x: \(touchX)")
         
         let middleOfView = (self.view!.frame.width) / 2
         if touchX > middleOfView {
         print("touching right side")
         impulseX = 0.05
         }
         else if touchX < middleOfView {
         print("touching left side")
         impulseX = -0.05
         }
         */
        
        //print("xMOD: \(impulseX)")
        
        //hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 0.9))//0.8
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Update to new touch location */
        
        /*
         for touch in touches {
         //location = touch.locationInNode(self)
         if touch == touches.first {
         //let position = touch.locationInNode(self)
         let position = touch.locationInView(self.view)
         impulseX = position.x
         //print("raw x: \(impulseX)")
         
         impulseX = impulseX / self.frame.width
         impulseX *= 2
         impulseX -= 1.2
         impulseX /= 15
         }
         }
         */
        
        /*
         let touch = touches.first
         let position = touch!.locationInView(self.view)
         let touchX = position.x
         //print("raw x: \(touchX)")
         
         let middleOfView = (self.view!.frame.width) / 2
         if touchX > middleOfView {
         //print("touching right side")
         impulseX = 0.05
         }
         else if touchX < middleOfView {
         //print("touching left side")
         impulseX = -0.05
         }
         */
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = false
    }
    
    //MARK: Misc
    func restartGame() {
        // use separate function
        print("DEAD")
        enemies.removeAll()
        // restart game
        let skView = self.view as SKView!
        /* Load Game scene */
        let scene = GameScene(fileNamed:"GameScene") as GameScene!
        /* Ensure correct aspect mode */
        scene.scaleMode = .AspectFill
        /* Restart game scene */
        skView.presentScene(scene)
    }
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func randomBool() -> Bool {
        return arc4random_uniform(2) == 0 ? true: false
    }
    
    //MARK: Enemies (unused)
    
    func addEnemyGroup(amount:Int, size:CGFloat, position:CGFloat){
        /*
         for i in 1...amount {
         let enemyPositionX:CGFloat = self.frame.width + 100
         let randomPosition = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(position - 5, secondNum: position + 5))
         
         let resourcePath = NSBundle.mainBundle().pathForResource("Enemy", ofType: "sks")
         let enemyReferenceNode = EnemyReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
         let enemy = enemyReferenceNode.enemySprite
         
         // random position
         enemy.position = randomPosition
         
         // random speed
         var randomSpeed = randomBetweenNumbers(1, secondNum: 2)
         
         enemy.movementSpeed = randomSpeed
         enemy.direction = .Left
         enemy.movementSpeed = -enemy.movementSpeed
         
         var randomSize = randomBetweenNumbers(size - 0.5, secondNum: size + 0.5)
         
         enemy.setScale(randomSize)
         enemy.sizeValue = randomSize
         
         addChild(enemyReferenceNode)
         enemies.insert(enemy)
         }
         */
    }
    
    func moveEnemies(){
        for enemy in enemies {
            let move = SKAction.moveBy(CGVector(dx: enemy.movementSpeed, dy: 0), duration: 0.5)
            enemy.runAction(move)
            
            if enemy.movementSpeed > 0 {
                enemy.xScale = -(abs(enemy.xScale))
            } else {
                enemy.xScale = (abs(enemy.xScale))
            }
        }
    }
    
    func removeEnemiesOutOfBounds() {
        var tempSet:[Enemy] = []
        for enemy in enemies {
            if (enemy.direction == .Right && enemy.position.x > self.frame.width + 500) ||
                (enemy.direction == .Left && enemy.position.x < -500) {
                tempSet.append(enemy)
            }
        }
        
        for enemy in tempSet {
            enemies.remove(enemy)
            enemy.removeFromParent()
        }
        tempSet.removeAll()
        
        //print(enemies.count)
        //print(children.count)
    }
    
    func addRandomEnemy(){
        /*
         //let chanceForSmallEnemy = 5
         let enemyPositionX:CGFloat = -400
         let randomPosition = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(0, secondNum: background.size.height))
         let enemyFacingLeft = randomBool()
         let nameOfTextureFile = String(Int(randomBetweenNumbers(1, secondNum: 24)))
         
         let enemy = Enemy(imageNamed: nameOfTextureFile)
         enemy.name = "enemy"
         
         enemy.physicsBody = SKPhysicsBody.init(texture: enemy.texture!, size: CGSize(width: 114, height: 116))
         enemy.physicsBody?.dynamic = true
         enemy.physicsBody?.affectedByGravity = false
         enemy.physicsBody?.categoryBitMask = 8
         enemy.physicsBody?.collisionBitMask = 0
         enemy.physicsBody?.contactTestBitMask = 1
         
         let enemySizeMax:CGFloat = 3, enemySizeMin:CGFloat = 1
         
         // random position
         enemy.position = randomPosition
         
         // random speed
         let randomSpeed = randomBetweenNumbers(1, secondNum: 3)
         enemy.movementSpeed = randomSpeed
         
         if enemyFacingLeft { // random 50% chance to run
         enemy.position.x = self.frame.width + 400
         enemy.direction = .Left
         enemy.movementSpeed = -enemy.movementSpeed
         }
         var randomSize = randomBetweenNumbers(enemySizeMin, secondNum: enemySizeMax)
         
         enemy.setScale(randomSize)
         enemy.sizeValue = randomSize
         
         addChild(enemy)
         enemies.insert(enemy)
         //}
         */
    }
}
