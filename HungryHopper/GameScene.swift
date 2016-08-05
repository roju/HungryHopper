//
//  GameScene.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/8/16.
//  Copyright (c) 2016 Ross Justin. All rights reserved.
//

/*
 TODO:
 calculate gap sizes to avoid impossible levels
 add shark chasing hero
 add polish to the score increase and combos
 add sounds
 
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
    let FIXED_DELTA: CFTimeInterval = 1.0/60.0 /* 60 FPS */
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
    
    let defaultBubbleScale:CGFloat = 0.8
    var bubbleScale:CGFloat = 0.8
    let bubbleSizeIncrease:CGFloat = 0.2
    
    var holdingForCombo = false
    var comboCancelled = true
    var justDied = false
    
    let 💀 = true
    
    var deathDelayCounter:CFTimeInterval = 0
    var deathDelayBeforeRestarting:CFTimeInterval = 1
    
    //var mainButton:MSButtonNode!
    
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
        hero.hero.physicsBody?.linearDamping = 8
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

        /*
        mainButton = self.childNodeWithName("MainButton") as! MSButtonNode
        mainButton.selectedHandler = {
            self.gameState = .Active
        }
        mainButton.state = .MSButtonNodeStateHidden
         */
        
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
    
    //MARK: Update ---------------------------------------
    override func update(currentTime: CFTimeInterval) {
        if gameState == .Paused {
            //mainButton.state = .MSButtonNodeStateActive
        }
        else if gameState == .GameOver {
            /* camera follows hero
            var camPosition = CGPoint(x: hero.hero.position.x, y: hero.hero.position.y + 200)
            camPosition.x -= hero.hero.size.width
            let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 1.0/60.0)
            cam.runAction(moveCamToPlayer)
             */
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
            
            deathDelayCounter += FIXED_DELTA
            
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
            gameTimeStamp += FIXED_DELTA
            
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
                    //starScale += 0.05
                    bubbleScale += bubbleSizeIncrease
                    
                    for collectible in collectibles {
                        collectible.runAction(SKAction.scaleTo(bubbleScale, duration: 0.2))
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
                    addEnemy(level)
                    level.timerCounter = 0
                }
                else {
                    level.timerCounter += FIXED_DELTA
                }
            }
            
            moveEnemies()
            flagEnemiesOutOfBounds()
            removeFlaggedEnemies()
            removeFlaggedCollectibles()
        }
    }
    
    //MARK: Enemies ---------------------------------------
    
    func addEnemy(level:Level, specifiedPosition:CGPoint? = nil) {
        let xPos = level.direction == .Right ? leftBoundary : rightBoundary
        var position = CGPoint(x:xPos, y:level.yPosition)
        
        if specifiedPosition != nil {
            position = specifiedPosition!
        }
        
        let nameOfTextureFile = "fish" + String(level.enemyType)
        
        let enemy = Enemy.init(imageNamed: nameOfTextureFile)
        
        enemy.name = "enemy"
        enemy.levelID = level.levelID
        
        enemy.texture?.filteringMode = .Nearest
        enemy.setScale(5.0)
        
        enemy.physicsBody = SKPhysicsBody.init(texture: enemy.texture!, size: CGSize(width: 11, height: 7))// 114 116
        enemy.physicsBody?.dynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.contactTestBitMask = 1
 
        //enemy.physicsBody?.categoryBitMask = 8
        //enemy.physicsBody?.categoryBitMask = MAX_FIELD_MASK
        //enemy.physicsBody?.mass = 1
        
        if level.direction == .Right {
            enemy.movementSpeedX = level.speed
            enemy.direction = .Right
        }
        else { // Left
            enemy.movementSpeedX = -level.speed
            enemy.direction = .Left
        }
        
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
        
        let speed:CGFloat = randomBetweenNumbers(3.5, secondNum: 4.5)
        
        let timerDelayValue = randomBetweenNumbers(speed/5, secondNum: speed/3)
        
        let direction:MovingDirection = randomBool() ? .Left : .Right
        
        let verticalSpeed:CGFloat = randomBetweenNumbers(-0.4, secondNum: 0.4)
        
        let enemyType = Int(randomBetweenNumbers(1, secondNum: 5))
        
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
        //addEnemy(level)
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
    
    //MARK: Collectible ------------------------------------
    
    func addCollectible(yPos:CGFloat) {
        let nameOfTextureFile = "bubble"//"star1"
        
        let collectible = Collectible.init(imageNamed: nameOfTextureFile)
        
        collectible.name = "collectible"
        
        collectible.physicsBody = SKPhysicsBody.init(texture: collectible.texture!, size: CGSize(width: 32, height: 32))//(width: 512, height: 512))
        collectible.physicsBody?.dynamic = false
        collectible.physicsBody?.affectedByGravity = false
        collectible.physicsBody?.categoryBitMask = 0
        collectible.physicsBody?.collisionBitMask = 0
        collectible.physicsBody?.contactTestBitMask = 1
        
        collectible.position = CGPoint(x:frameCenter, y:yPos)
        collectible.setScale(bubbleScale)
        
        addChild(collectible)
        collectibles.insert(collectible)
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
        
        // flappy bird controls
        //hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        //hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 1))//was 0.8
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Update to new touch location */
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = false
        holdingForCombo = false
        
        scoreMultiplier = 1
        starScale = 0.1
        bubbleScale = defaultBubbleScale
        
        for collectible in collectibles {
            collectible.runAction(SKAction.scaleTo(defaultBubbleScale, duration: 0.2))
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
        hero.hero.physicsBody?.collisionBitMask = 1
        hero.hero.physicsBody?.categoryBitMask = MAX_FIELD_MASK
        hero.hero.physicsBody?.linearDamping = 0
        
        self.physicsWorld.gravity = CGVectorMake(0.0, -1.0);
        
        for enemy in enemies {
            if enemy.position.y > hero.hero.position.y {
                enemy.physicsBody?.collisionBitMask = 1
            }
        }
    }
}
