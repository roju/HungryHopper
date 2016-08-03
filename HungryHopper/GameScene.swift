//
//  GameScene.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/8/16.
//  Copyright (c) 2016 Ross Justin. All rights reserved.
//

/*
 TODO:
 check hero linear damping: sometimesvar gets reset to default
 calculate gap sizes to avoid impossible levels
 
 FISH TYPES:
 1) moves in a line, large gap
 2) moves in a line, small fish and small gaps
 3) moves in a line, randomized gaps
 4) moves at a high diagonal angle, large spacing, zigzag
 5) appears randomly in the scene
 6) one from each side swims to middle, they touch and swim back
 7) fish swim in a circle
 
 CONTROLS:
    hero linear damping 8
    heroImpulseY        1.5
    gravityInWater      -2.5
 
 &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 */

import SpriteKit

enum GameState {
    case Paused, Active, GameOver
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
    var highScoreLabel:SKLabelNode!
    
    var highScoreLabelText = "Best: "
    
    var impulseX:CGFloat = 0.0
    //var impulseXContinuous:CGFloat = 0.05
    var cam:SKCameraNode!
    let gravityInWater:CGFloat = -2.5
    let gravityOutOfWater:CGFloat = -9.0
    var gameState:GameState = .Active
    var frameCenter:CGFloat = 0
    let MAX_FIELD_MASK:UInt32 = 4294967295
    
    var score = 0
    var nextGoalHeight:CGFloat = 240
    
    var leftBoundary:CGFloat = 0
    var rightBoundary:CGFloat = 0
    
    let zoomLevel = 1.5
    
    var obstacles = Set<Obstacle>()
    var levels = [Level]()
    var collectibles = Set<Collectible>()
    
    let heroImpulseY:CGFloat = 1.5
    
    var updatedHighScore = false
    
    var scoreMultiplier = 1
    var starScale:CGFloat = 0.1
    var holdingForCombo = false
    var comboCancelled = true
    var justDied = false
    
    let 💀 = true
    
    var deathDelayCounter:CFTimeInterval = 0
    var deathDelayBeforeRestarting:CFTimeInterval = 1
    
    //------------------------------------------------------
    
    override func didMoveToView(view: SKView) {
        background = childNodeWithName("background") as! SKSpriteNode
        startingPlatform = childNodeWithName("startingPlatform") as! SKSpriteNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        frameCenter = self.frame.width / 2
        rightBoundary = frameCenter + 400
        leftBoundary = frameCenter - 550
        
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
        
        // create the score label
        scoreLabel = SKLabelNode.init(text: "0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.position = CGPoint(x: hero.hero.size.width, y: 200)
        scoreLabel.fontColor = UIColor.whiteColor()
        
        // add the score label as a child of camera
        cam.addChild(scoreLabel)
        
        // create the high score label
        highScoreLabel = SKLabelNode.init(text: highScoreLabelText + "\(HighScore.sharedInstance.highScore)")
        highScoreLabel.fontSize = 15
        highScoreLabel.fontName = "AvenirNext-Bold"
        highScoreLabel.position = CGPoint(x: -70, y: 225)
        highScoreLabel.fontColor = UIColor.whiteColor()
        
        // add the high score label as a child of camera
        cam.addChild(highScoreLabel)
        
        let progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        progressView.center = CGPoint(x: 200, y: 150)
        //self.view!.addSubview(progressView)
        
        self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);// gravityInWater
        
        // these default values will be changed when randomized, so they don't matter
        let tdvA = 4.8, rdA = CGSizeMake(30, 20), dA:MovingDirection = .Right, sA:CGFloat = 1.6
        let tdvB = 4.1, rdB = CGSizeMake(50, 20), dB:MovingDirection = .Left, sB:CGFloat = 1.8
        let tdvC = 4.0, rdC = CGSizeMake(40, 20), dC:MovingDirection = .Right, sC:CGFloat = 2.0
        let tdvD = 4.4, rdD = CGSizeMake(20, 20), dD:MovingDirection = .Left, sD:CGFloat = 1.7
        let tdvE = 5.2, rdE = CGSizeMake(40, 20), dE:MovingDirection = .Right, sE:CGFloat = 1.9
        let tdvF = 5.3, rdF = CGSizeMake(80, 20), dF:MovingDirection = .Left, sF:CGFloat = 2.1
        
        levels.append(Level.init(timerDelayValue: tdvF, yPosition: 1440, rectDimensions: rdF, direction: dF, speed: sF, levelID:"F")) // visual only
        levels.append(Level.init(timerDelayValue: tdvE, yPosition: 1200, rectDimensions: rdE, direction: dE, speed: sE, levelID:"E")) // visual only
        levels.append(Level.init(timerDelayValue: tdvD, yPosition: 960, rectDimensions: rdD, direction: dD, speed: sD, levelID:"D")) // top
        levels.append(Level.init(timerDelayValue: tdvC, yPosition: 720, rectDimensions: rdC, direction: dC, speed: sC, levelID:"C"))
        levels.append(Level.init(timerDelayValue: tdvB, yPosition: 480, rectDimensions: rdB, direction: dB, speed: sB, levelID:"B"))
        levels.append(Level.init(timerDelayValue: tdvA, yPosition: 240, rectDimensions: rdA, direction: dA, speed: sA, levelID:"A"))
        // hero starting position
        levels.append(Level.init(timerDelayValue: tdvF, yPosition:    0, rectDimensions: rdF, direction: dF, speed: sF, levelID:"F"))
        levels.append(Level.init(timerDelayValue: tdvE, yPosition: -240, rectDimensions: rdE, direction: dE, speed: sE, levelID:"E"))
        levels.append(Level.init(timerDelayValue: tdvD, yPosition: -480, rectDimensions: rdD, direction: dD, speed: sD, levelID:"D")) // bottom
        levels.append(Level.init(timerDelayValue: tdvC, yPosition: -720, rectDimensions: rdC, direction: dC, speed: sC, levelID:"C")) // visual only
        levels.append(Level.init(timerDelayValue: tdvB, yPosition: -960, rectDimensions: rdB, direction: dB, speed: sB, levelID:"B")) // visual only
        
        for level in levels {
            // initially randomize and populate the obstacles for all levels so we don't have to wait for them to move onscreen before we see them
            randomizeLevelsWithEnemies(CGFloat(level.yPosition))
        }
        
        addCollectible(1200)
        addCollectible(1440)
    }
    
    func addCollectible(yPos:CGFloat) {
        let nameOfTextureFile = "star1"
        
        let collectible = Collectible.init(imageNamed: nameOfTextureFile)
        
        collectible.name = "collectible"
        
        collectible.physicsBody = SKPhysicsBody.init(texture: collectible.texture!, size: CGSize(width: 512, height: 512))
        collectible.physicsBody?.dynamic = true
        collectible.physicsBody?.affectedByGravity = false
        collectible.physicsBody?.categoryBitMask = 8
        collectible.physicsBody?.collisionBitMask = 0 //4294967295
        collectible.physicsBody?.contactTestBitMask = 1

        collectible.position = CGPoint(x:frameCenter, y:yPos)
        collectible.setScale(starScale)
        
        addChild(collectible)
        collectibles.insert(collectible)
    }
    
    //MARK: Update ---------------------------------------
    override func update(currentTime: CFTimeInterval) {
        if gameState == .Paused {
            
        }
        else if gameState == .GameOver {
            // camera follows hero
            var camPosition = CGPoint(x: hero.hero.position.x, y: hero.hero.position.y + 200)
            camPosition.x -= hero.hero.size.width
            let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 1.0/60.0)
            cam.runAction(moveCamToPlayer)
            
            if justDied { // runs once
                enableCollisionPhysics()
                justDied = false
            }
            
            if deathDelayCounter >= deathDelayBeforeRestarting {
                restartGame()
            }
            
            moveEnemies()
            flagEnemiesOutOfBounds()
            removeFlaggedEnemies()
            removeFlaggedCollectibles()
            
            deathDelayCounter += fixedDelta
            
            // runs once: if player achieved a high score, save it
            if score > HighScore.sharedInstance.highScore && !updatedHighScore{
                let defaults = NSUserDefaults.standardUserDefaults()
                HighScore.sharedInstance.highScore = score
                defaults.setInteger(score, forKey: "HighScore")
                updatedHighScore = true
            }
        }
        /* Called before each frame is rendered */
        else if gameState == .Active {
            gameTimeStamp += fixedDelta
            
            // apply impulse to hero continuously while holding finger down on screen
            if isTouching {
                hero.hero.physicsBody!.applyImpulse(CGVectorMake(0, heroImpulseY)) // 0.3 // 0.7
            }
            //hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseXContinuous, 0))
            
            let yBoundary:CGFloat = 960
            if hero.hero.position.y > nextGoalHeight { // passed through a level
                nextGoalHeight += 240
                if nextGoalHeight > yBoundary {
                    nextGoalHeight = -240
                }
                
                score += 1 * scoreMultiplier
                
                if isTouching && !holdingForCombo {
                    holdingForCombo = true
                }
                
                if holdingForCombo {
                    scoreMultiplier += 1
                    starScale += 0.05
                    
                    for collectible in collectibles {
                        collectible.runAction(SKAction.scaleTo(starScale, duration: 0.2))
                    }
                }
                
                // randomize levels
                randomizeLevelsWithEnemies(nextGoalHeight)
            }
            // update the score label
            scoreLabel.text = String(score)
            
            // update high score label
            if score > HighScore.sharedInstance.highScore {
                highScoreLabel.text = highScoreLabelText + String(score)
            }
            
            // passed above level D: Hero reached the top and looped around to bottom of scene
            if hero.hero.position.y > yBoundary {
                if startingPlatform != nil {
                    startingPlatform.removeFromParent()
                }
                hero.hero.position.y = -yBoundary / 2
                // increase speed of obstacles every time hero passes level
                //increaseGameSpeed()
            }
            
            // loop around to the top of the scene if moving down past lower boundary
            if hero.hero.position.y < -yBoundary / 2 {
                hero.hero.position.y = yBoundary
            }
            
            //print(hero.hero.position)
            //print("next g0al height: \(nextGoalHeight)")
            
            // move camera to follow hero
            var camPosition = CGPoint(x: hero.hero.position.x, y: hero.hero.position.y + 200)
            camPosition.x -= hero.hero.size.width
            
            let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 1.0/60.0)
            cam.runAction(moveCamToPlayer)
            
            // add new obstacles to all levels
            for level in levels {
                if level.timerCounter >= level.timerDelayValue {
                    //addObstacle(level)
                    addEnemy(level)
                    level.timerCounter = 0
                }
                else {
                    level.timerCounter += fixedDelta
                }
            }
            
            //print("tmr:\(levels[0].timerCounter)")
            //print("target:\(levels[0].timerDelayValue)")
            //print("")
            
            moveEnemies()
            flagEnemiesOutOfBounds()
            removeFlaggedEnemies()
            removeFlaggedCollectibles()
            
            //moveObstacles()
            //flagObstaclesOutOfBounds()
            //removeFlaggedObstacles()
            
            
            //enemyTimer += fixedDelta
            
            // keep hero centered in X
            /*
             if hero.hero.position.x > frameCenter {
             hero.hero.position.x = frameCenter
             }
             else if hero.hero.position.x < frameCenter {
             hero.hero.position.x = frameCenter
             }
            */
            
            /*
             if hero.hero.position.y > background.frame.height {
             self.physicsWorld.gravity = CGVectorMake(0.0, gravityOutOfWater);
             }
             else{
             self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
             }
             */
            
        }
    }
 
    //MARK: Obstacles ------------------------------------
    func addObstacle(level:Level, specifiedPosition:CGPoint? = nil) -> Obstacle {
        let xPos = level.direction == .Right ? leftBoundary : rightBoundary
        var position = CGPoint(x:xPos, y:level.yPosition)
        
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
        obstacle.physicsBody?.collisionBitMask = 0 //4294967295
        obstacle.physicsBody?.contactTestBitMask = 1
        
        if level.direction == .Right {
            obstacle.movementSpeedX = level.speed
            obstacle.direction = .Right
        }
        else { // Left
            obstacle.movementSpeedX = -level.speed
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
        
        obstacle.movementSpeedY = level.verticalSpeed
        obstacle.position = position
        //setRotationAngle(level, obstacle: obstacle)
        
        addChild(obstacle)
        obstacles.insert(obstacle)
        
        return obstacle
    }
    
    func randomizeLevelsWithObstacles(yPos:CGFloat) {
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
        
        for obstacle in obstacles {
            if obstacle.levelID == randomizedID {
                obstacle.flaggedForRemoval = true
            }
        }
        
        let rectX:CGFloat = randomBetweenNumbers(55, secondNum: 65)
        let rectY:CGFloat = randomBetweenNumbers(20, secondNum: 25)
        //let s = randomBetweenNumbers(20, secondNum: 50)
        let rectDimensions = CGSizeMake(rectX, rectY)
        
        let timerDelayValue = randomBetweenNumbers(1.5, secondNum: 2)
        
        let direction:MovingDirection = randomBool() ? .Left : .Right
        
        let speed:CGFloat = randomBetweenNumbers(1, secondNum: 2)
        
        let verticalSpeed:CGFloat = randomBetweenNumbers(-0.2, secondNum: 0.2)
        
        
        let gapSize = CGFloat(timerDelayValue)*(60*(speed)) - rectX
        print(gapSize)
        
        
        for level in levels {
            if level.levelID == randomizedID {
                level.rectDimensions = rectDimensions
                level.timerDelayValue = CFTimeInterval(timerDelayValue)
                level.direction = direction
                level.speed = speed
                level.verticalSpeed = verticalSpeed
                
                populateObstaclesForLevel(level)
                level.timerCounter = 0
            }
        }
    }
    
    func populateObstaclesForLevel(level:Level) {
        addObstacle(level)
        var xPos:CGFloat = leftBoundary
        var yPos = CGFloat(level.yPosition)
        
        let spaceBetweenObstacles = CGFloat(level.timerDelayValue)*(60*(level.speed/2))
        let verticalSpacing = CGFloat(level.timerDelayValue)*(60*(level.verticalSpeed/2))
        
        if level.direction == .Left {
            xPos = rightBoundary
        }
        
        //for _ in 1...10 {
        while true {
            addObstacle(level, specifiedPosition: CGPoint(x: xPos, y: yPos))
            
            if level.direction == .Right {
                if xPos > self.frame.width {
                    break
                }
                xPos += spaceBetweenObstacles
            }
            else { // direction .Left
                if xPos < 0 {
                    break
                }
                xPos -= spaceBetweenObstacles
            }
            
            yPos += verticalSpacing
        }
    }
    
    func moveObstacles(){
        for obstacle in obstacles {
            let move = SKAction.moveBy(CGVector(dx: obstacle.movementSpeedX, dy: obstacle.movementSpeedY), duration: 0.5)
            obstacle.runAction(move)
        }
    }
    
    func flagObstaclesOutOfBounds(){
        for obstacle in obstacles {
            if obstacleIsOutOfBounds(obstacle) {
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
    
    func obstacleIsOutOfBounds(obstacle:Obstacle) -> Bool {
        if (obstacle.direction == .Right && obstacle.position.x > self.frame.width + 200) ||
            (obstacle.direction == .Left && obstacle.position.x < -600) {
            return true
        }
        else {
            return false
        }
    }
    
    //MARK: Enemies ---------------------------------------
    
    func addEnemy(level:Level, specifiedPosition:CGPoint? = nil) {
        let xPos = level.direction == .Right ? leftBoundary : rightBoundary
        var position = CGPoint(x:xPos, y:level.yPosition)
        
        if specifiedPosition != nil {
            position = specifiedPosition!
        }
        
        let nameOfTextureFile = String(level.enemyType)
        
        let enemy = Enemy.init(imageNamed: nameOfTextureFile)
        
        enemy.name = "enemy"
        enemy.levelID = level.levelID
        
        enemy.physicsBody = SKPhysicsBody.init(texture: enemy.texture!, size: CGSize(width: 114, height: 116))
        enemy.physicsBody?.dynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = 8
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.contactTestBitMask = 1
        enemy.physicsBody?.mass = 5
        
        if level.direction == .Right {
            enemy.movementSpeedX = level.speed
            enemy.direction = .Right
        }
        else { // Left
            enemy.movementSpeedX = -level.speed
            enemy.direction = .Left
        }
        
        /*
         if level.levelID == "A" {
         enemy.fillColor = SKColor.redColor()
         }
         if level.levelID == "B" {
         enemy.fillColor = SKColor.orangeColor()
         }
         if level.levelID == "C" {
         enemy.fillColor = SKColor.yellowColor()
         }
         if level.levelID == "D" {
         enemy.fillColor = SKColor.greenColor()
         }
         if level.levelID == "E" {
         enemy.fillColor = SKColor.blueColor()
         }
         if level.levelID == "F" {
         enemy.fillColor = SKColor.purpleColor()
         }
         */
        
        enemy.movementSpeedY = level.verticalSpeed
        enemy.position = position
        
        addChild(enemy)
        enemies.insert(enemy)
    }
    
    func randomizeLevelsWithEnemies(yPos:CGFloat) {
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
        
        for enemy in enemies {
            if enemy.levelID == randomizedID {
                enemy.flaggedForRemoval = true
            }
        }
        
        //let rectX:CGFloat = randomBetweenNumbers(55, secondNum: 65)
        //let rectY:CGFloat = randomBetweenNumbers(20, secondNum: 25)
        //let rectDimensions = CGSizeMake(rectX, rectY)
        
        let speed:CGFloat = randomBetweenNumbers(3.5, secondNum: 4.5)
        
        let timerDelayValue = randomBetweenNumbers(speed/5, secondNum: speed/3)
        
        let direction:MovingDirection = randomBool() ? .Left : .Right
        
        let verticalSpeed:CGFloat = randomBetweenNumbers(-0.4, secondNum: 0.4)
        
        let enemyType = Int(randomBetweenNumbers(1, secondNum: 24))
        
        //let gapSize = CGFloat(timerDelayValue)*(60*(speed/2)) - rectX
        //print(gapSize)
        
        for level in levels {
            if level.levelID == randomizedID {
                //level.rectDimensions = rectDimensions
                level.timerDelayValue = CFTimeInterval(timerDelayValue)
                level.direction = direction
                level.speed = speed
                level.verticalSpeed = verticalSpeed
                level.enemyType = enemyType
                level.timerCounter = 0
                
                populateEnemiesForLevel(level)
                
                if level.yPosition < 1200 && level.yPosition > -720 {
                    // add collectibles to each level
                    addCollectible(level.yPosition)
                }
            }
        }
    }
    
    func populateEnemiesForLevel(level:Level) {
        addEnemy(level)
        var xPos:CGFloat = leftBoundary
        var yPos = CGFloat(level.yPosition)
        
        let spaceBetweenObstacles = CGFloat(level.timerDelayValue)*(60*(level.speed))
        let verticalSpacing = CGFloat(level.timerDelayValue)*(60*(level.verticalSpeed))
        
        if level.direction == .Left {
            xPos = rightBoundary
        }
        
        while true {
            addEnemy(level, specifiedPosition: CGPoint(x: xPos, y: yPos))
            
            if level.direction == .Right {
                if xPos > self.frame.width {
                    break
                }
                xPos += spaceBetweenObstacles
            }
            else { // direction .Left
                if xPos < 0 {
                    break
                }
                xPos -= spaceBetweenObstacles
            }
            
            yPos += verticalSpacing
        }
    }
    
    func flagEnemiesOutOfBounds(){
        for enemy in enemies {
            if enemyIsOutOfBounds(enemy) {
                enemy.flaggedForRemoval = true
            }
        }
    }
    
    func enemyIsOutOfBounds(enemy:Enemy) -> Bool {
        if (enemy.direction == .Right && enemy.position.x > rightBoundary) ||
            (enemy.direction == .Left && enemy.position.x < leftBoundary) {
            return true
        }
        else {
            return false
        }
    }
    
    func removeFlaggedEnemies() {
        for enemy in enemies {
            if enemy.flaggedForRemoval {
                enemies.remove(enemy)
                enemy.removeFromParent()
            }
        }
    }
    
    func moveEnemies(){
        for enemy in enemies {
            let move = SKAction.moveBy(CGVector(dx: enemy.movementSpeedX, dy: enemy.movementSpeedY), duration: 0.5)
            enemy.runAction(move)
            
            if enemy.movementSpeedX > 0 {
                enemy.xScale = -(abs(enemy.xScale))
            } else {
                enemy.xScale = (abs(enemy.xScale))
            }
        }
    }
    
    //MARK: Physics ----------------------------------------
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
        
        
        if (nodeA.name == "hero" && nodeB.name == "enemy"){
            heroEnemyContact(nodeA as! Hero, enemy: nodeB as! Enemy)
        }
        else if (nodeA.name == "enemy" && nodeB.name == "hero") {
            heroEnemyContact(nodeB as! Hero, enemy: nodeA as! Enemy)
        }
        
        
        if (nodeA.name == "hero" && nodeB.name == "collectible"){
            heroCollectibleContact(nodeA as! Hero, collectible: nodeB as! Collectible)
        }
        else if (nodeA.name == "collectible" && nodeB.name == "hero") {
            heroCollectibleContact(nodeB as! Hero, collectible: nodeA as! Collectible)
        }
    }
    
    func heroObstacleContact(hero:Hero, obstacle:Obstacle){
        gameState = .GameOver
    }
    
    func heroEnemyContact(hero:Hero, enemy:Enemy){
        if 💀 {
            justDied = true
            gameState = .GameOver
        }
    }
    
    func heroCollectibleContact(hero:Hero, collectible:Collectible){
        collectible.flaggedForRemoval = true
    }
    
    //MARK: Touch ------------------------------------------
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = true
        //hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        //hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 1))//was 0.8
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
        holdingForCombo = false
        
        scoreMultiplier = 1
        starScale = 0.1
        
        for collectible in collectibles {
            collectible.runAction(SKAction.scaleTo(starScale, duration: 0.2))
        }
    }
    
    //MARK: Misc --------------------------------------------
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
    
    func getRotationAngle(level:Level) -> CGFloat { // doesn't work :(
        let speed = level.direction == .Right ? level.speed : -level.speed
        
        let x = CGFloat(level.timerDelayValue)*(60*(speed))
        let y = CGFloat(level.timerDelayValue)*(60*(level.verticalSpeed))
        
        var p =  CGFloat(atan2f(Float(y), Float(x)))
        if p > 1 || p < -1 {
            //p = 0
        }
        print("x:\(x) y:\(y)   p:\(p)")
        return p
    }
    
    func increaseGameSpeed() {
        let speedIncrease:CGFloat = 0.2
        for obstacle in obstacles {
            if obstacle.direction == .Right {
                obstacle.movementSpeedX += speedIncrease
            }
            else { // Left
                obstacle.movementSpeedX -= speedIncrease
            }
        }
        for level in levels {
            level.speed += speedIncrease
            level.timerDelayValue -= level.timerDelayValue * CFTimeInterval(speedIncrease / 8)
        }
    }
    
    func removeFlaggedCollectibles() {
        for collectible in collectibles {
            if collectible.flaggedForRemoval {
                collectibles.remove(collectible)
                collectible.removeFromParent()
            }
        }
    }
    
    func enableCollisionPhysics() {
        hero.hero.physicsBody?.allowsRotation = true
        hero.hero.physicsBody?.collisionBitMask = MAX_FIELD_MASK
        hero.hero.physicsBody?.linearDamping = 0
        
        for enemy in enemies {
            enemy.physicsBody?.collisionBitMask = MAX_FIELD_MASK
        }
    }
    
    //MARK: Unused --------------------------------------------
    
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
    //----------------------------------------------------------------------------------

}
