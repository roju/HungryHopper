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
 make obstacles move diagonally
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
    var scoreLabel:SKLabelNode!
    
    var impulseX:CGFloat = 0.0
    var impulseXContinuous:CGFloat = 0.05
    var cam:SKCameraNode!
    let gravityInWater:CGFloat = -2.0
    let gravityOutOfWater:CGFloat = -9.0
    var gameState:GameState = .Active
    var frameCenter:CGFloat = 0
    
    var score = 0
    var nextGoalHeight:CGFloat = 240
    
    var leftBoundary:CGFloat = 0
    var rightBoundary:CGFloat = 0
    
    let zoomLevel = 1.5
    
    //obstacle
    var obstacles = Set<Obstacle>()
    var levels = [Level]()
    
    
    override func didMoveToView(view: SKView) {
        background = childNodeWithName("background") as! SKSpriteNode
        startingPlatform = childNodeWithName("startingPlatform") as! SKSpriteNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        frameCenter = self.frame.width / 2
        rightBoundary = frameCenter + 100
        leftBoundary = frameCenter - 300
        
        hero.hero.position = CGPoint(x: frameCenter, y: 150) //  + hero.hero.size.width
        addChild(hero)
        
        physicsWorld.contactDelegate = self
        
        /* Camera */
        cam = SKCameraNode() //initialize and assign an instance of SKCameraNode to the cam variable.
        
        self.camera = cam //set the scene's camera to reference cam
        self.addChild(cam) //make the cam a childElement of the scene itself.
        
        //position the camera on the gamescene.
        cam.position = CGPoint(x: hero.hero.position.x, y: hero.hero.position.y)
        cam.scaleAsPoint = CGPoint(x: zoomLevel, y: zoomLevel) //the scale sets the zoom level of the camera on the given position
        
        // add the score label as a child of camera
        scoreLabel = SKLabelNode.init(text: "0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.position = CGPoint(x: hero.hero.size.width, y: 200)
        scoreLabel.fontColor = UIColor.whiteColor()
        
        cam.addChild(scoreLabel)
        
        self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);// gravityInWater
        
        //let tdvA = 3.5, rdA = CGSizeMake(70, 20), dA:MovingDirection = .Right, sA:CGFloat = 0.5
        let tdvA = 2.0, rdA = CGSizeMake(30, 20), dA:MovingDirection = .Right, sA:CGFloat = 1.6
        let tdvB = 1.8, rdB = CGSizeMake(50, 20), dB:MovingDirection = .Left, sB:CGFloat = 1.8
        let tdvC = 1.6, rdC = CGSizeMake(40, 20), dC:MovingDirection = .Right, sC:CGFloat = 2.0
        let tdvD = 1.2, rdD = CGSizeMake(20, 20), dD:MovingDirection = .Left, sD:CGFloat = 1.7
        let tdvE = 1.5, rdE = CGSizeMake(40, 20), dE:MovingDirection = .Right, sE:CGFloat = 1.9
        let tdvF = 1.9, rdF = CGSizeMake(80, 20), dF:MovingDirection = .Left, sF:CGFloat = 2.1
        
        levels.append(Level.init(timerDelayValue: tdvF, yPosition: 720, rectDimensions: rdF, direction: dF, speed: sF, levelID:"F")) // visual only
        levels.append(Level.init(timerDelayValue: tdvE, yPosition: 600, rectDimensions: rdE, direction: dE, speed: sE, levelID:"E")) // visual only
        levels.append(Level.init(timerDelayValue: tdvD, yPosition: 480, rectDimensions: rdD, direction: dD, speed: sD, levelID:"D")) // top
        levels.append(Level.init(timerDelayValue: tdvC, yPosition: 360, rectDimensions: rdC, direction: dC, speed: sC, levelID:"C"))
        levels.append(Level.init(timerDelayValue: tdvB, yPosition: 240, rectDimensions: rdB, direction: dB, speed: sB, levelID:"B"))
        levels.append(Level.init(timerDelayValue: tdvA, yPosition: 120, rectDimensions: rdA, direction: dA, speed: sA, levelID:"A"))
        // hero starting position
        levels.append(Level.init(timerDelayValue: tdvF, yPosition:    0, rectDimensions: rdF, direction: dF, speed: sF, levelID:"F"))
        levels.append(Level.init(timerDelayValue: tdvE, yPosition: -120, rectDimensions: rdE, direction: dE, speed: sE, levelID:"E"))
        levels.append(Level.init(timerDelayValue: tdvD, yPosition: -240, rectDimensions: rdD, direction: dD, speed: sD, levelID:"D")) // bottom
        levels.append(Level.init(timerDelayValue: tdvC, yPosition: -360, rectDimensions: rdC, direction: dC, speed: sC, levelID:"C")) // visual only
        levels.append(Level.init(timerDelayValue: tdvB, yPosition: -480, rectDimensions: rdB, direction: dB, speed: sB, levelID:"B")) // visual only
        
        // initially populate the obstacles for all levels so we don't have to wait for them to move onscreen before we see them
        for level in levels {
            populateObstaclesForLevel(level)
        }
    }
    
    func populateObstaclesForLevel(level:Level) {
        addObstacle(level)
        var xPos:CGFloat = leftBoundary
        let spaceBetweenObstacles = CGFloat(level.timerDelayValue)*(60*(level.speed/2))
        
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
            
            let yBoundary:CGFloat = 480
            
            if hero.hero.position.y > nextGoalHeight { // passed through a level
                score += 1
                nextGoalHeight += 240
                if nextGoalHeight > yBoundary * 2 {
                    nextGoalHeight = -yBoundary / 2
                }
                //print("nextGoalHeight: \(nextGoalHeight)")
                
                // randomize
                randomizeLevels(nextGoalHeight)
            }
            if hero.hero.position.y > yBoundary * 2 { // passed above level D
                if startingPlatform != nil {
                    startingPlatform.removeFromParent()
                }
                hero.hero.position.y = -yBoundary
                // Hero reached the top and looped around to bottom of scene
                //-------------------------------------------------------------------
                
                // increase speed of obstacles every time hero passes level
                let speedIncrease:CGFloat = 0.2
                for obstacle in obstacles {
                    if obstacle.direction == .Right {
                        obstacle.movementSpeed += speedIncrease
                    }
                    else { // Left
                        obstacle.movementSpeed -= speedIncrease
                    }
                }
                for level in levels {
                    level.speed += speedIncrease
                    level.timerDelayValue -= level.timerDelayValue * CFTimeInterval(speedIncrease / 8)
                }
                
                //-------------------------------------------------------------------
            }
            
            // loop around if moving down past boundary
            if hero.hero.position.y < -yBoundary {
                hero.hero.position.y = yBoundary * 2
            }
            scoreLabel.text = String(score)
            
            if isTouching {
                hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseX, 0.28))
            }
            //hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseXContinuous, 0))
            
            if hero.hero.position.y > background.frame.height {
                self.physicsWorld.gravity = CGVectorMake(0.0, gravityOutOfWater);
            }
            else{
                self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
            }
            
            var camPosition = CGPoint(x: hero.hero.position.x, y: hero.hero.position.y + 200)
            camPosition.x -= hero.hero.size.width
            
            let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 1.0/60.0)
            cam.runAction(moveCamToPlayer)
            
            for level in levels {
                if level.timerCounter >= level.timerDelayValue {
                    addObstacle(level)
                    level.timerCounter = 0
                }
                else {
                    level.timerCounter += fixedDelta
                }
            }
            
            moveObstacles()
            
            flagObstaclesOutOfBounds()
            removeFlaggedObstacles()
            
            //enemyTimer += fixedDelta
            
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
        let xPos = level.direction == .Right ? leftBoundary : rightBoundary
        var position = CGPoint(x:Int(xPos), y:level.yPosition)
        
        if specifiedPosition != nil {
            position = specifiedPosition!
        }
        
        //let obstacle = Obstacle.init(circleOfRadius: radius)
        
        let obstacle = Obstacle.init(rect:CGRect(origin:position, size:level.rectDimensions))
        obstacle.name = "obs"
        obstacle.levelID = level.levelID
        
        let rectCenter = CGPointMake(position.x + level.rectDimensions.width / 2, position.y + level.rectDimensions.height / 2)
        
        obstacle.physicsBody = SKPhysicsBody.init(rectangleOfSize: level.rectDimensions, center: rectCenter)
        obstacle.physicsBody?.dynamic = true
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.categoryBitMask = 8
        obstacle.physicsBody?.collisionBitMask = 0 //4294967295 // 0
        obstacle.physicsBody?.contactTestBitMask = 1
        
        if level.direction == .Right {
            obstacle.movementSpeed = level.speed
            obstacle.direction = .Right
        }
        else { // Left
            obstacle.movementSpeed = -level.speed
            obstacle.direction = .Left
        }
        
        if level.levelID == "A" {
            obstacle.fillColor = SKColor.redColor()
        }
        if level.levelID == "B" {
            obstacle.fillColor = SKColor.orangeColor()
        }
        if level.levelID == "C" {
            obstacle.fillColor = SKColor.yellowColor()
        }
        if level.levelID == "D" {
            obstacle.fillColor = SKColor.greenColor()
        }
        if level.levelID == "E" {
            obstacle.fillColor = SKColor.blueColor()
        }
        if level.levelID == "F" {
            obstacle.fillColor = SKColor.purpleColor()
        }
        
        obstacle.initialMovementSpeed = obstacle.movementSpeed
        obstacle.position = position
        
        addChild(obstacle)
        obstacles.insert(obstacle)
    }
    
    func randomizeLevels(yPos:CGFloat) {
        var randomizedID:String = ""
        
        switch yPos {
        case 0:  //E
            randomizedID = "B"
            break
        case 240://F
            randomizedID = "C"
            break
        case 480://A
            randomizedID = "D"
            break
        case 720://B
            randomizedID = "E"
            break
        case 960://C
            randomizedID = "F"
            break
        case -240://D
            randomizedID = "A"
            break
        default:
            break
        }
        
        var levelsToRandomize = [Level]()
        for level in levels {
            if level.levelID == randomizedID {
                levelsToRandomize.append(level)
                level.timerCounter = 0
            }
        }
        //let tdv = 2.0
        let rd = CGSizeMake(randomBetweenNumbers(10, secondNum: 50), randomBetweenNumbers(10, secondNum: 50))
        //let dA:MovingDirection = .Right
        //let sA:CGFloat = 1.6
        
        for obstacle in obstacles {
            if obstacle.levelID == randomizedID {
                obstacle.flaggedForRemoval = true
            }
        }
        for level in levelsToRandomize {
            level.rectDimensions = rd
            populateObstaclesForLevel(level)
        }
    }
    
    func moveObstacles(){
        for obstacle in obstacles {
            let move = SKAction.moveBy(CGVector(dx: obstacle.movementSpeed, dy: 0), duration: 0.5)
            obstacle.runAction(move)
        }
    }
    
    func flagObstaclesOutOfBounds(){
        for obstacle in obstacles {
            if (obstacle.direction == .Right && obstacle.position.x > self.frame.width + 200) ||
                (obstacle.direction == .Left && obstacle.position.x < -600) {
                obstacle.flaggedForRemoval = true
            }
        }
    }
    
    func removeFlaggedObstacles() {
        for obstacle in obstacles {
            if obstacle.flaggedForRemoval {
                obstacles.remove(obstacle)
                obstacle.removeFromParent()
            }
        }
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
        //hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 1))//was 0.8
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
        //print("DEAD")
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
