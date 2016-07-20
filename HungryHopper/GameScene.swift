//
//  GameScene.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/8/16.
//  Copyright (c) 2016 Ross Justin. All rights reserved.
//

/*
 TODO:
 fix memory leak
 */

import SpriteKit

enum GameState {
    case Paused, Active, GameOver
}

enum ObstacleType {
    case MarchingLine, Door, BackAndForth
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero:MSReferenceNode!
    var isTouching = false
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var enemyTimer: CFTimeInterval = 0
    let enemyDelaySeconds:CFTimeInterval = 0.1
    var enemies = Set<Enemy>()
    var background:SKSpriteNode!
    var impulseX:CGFloat = 0.0
    var impulseXContinuous:CGFloat = 0.05
    var cam:SKCameraNode!
    let gravityInWater:CGFloat = -2.0
    let gravityOutOfWater:CGFloat = -9.0
    var gameState:GameState = .Active
    
    //obstacle
    var obstacles = Set<Obstacle>()
    var obstacleTimer:CFTimeInterval = 0
    let obstacleDelaySeconds:CFTimeInterval = 1
    
    
    override func didMoveToView(view: SKView) {
        background = childNodeWithName("background") as! SKSpriteNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        hero.hero.position = CGPoint(x: self.frame.width/2, y: 50)
        addChild(hero)
        
        physicsWorld.contactDelegate = self
        
        /* Camera */
        cam = SKCameraNode() //initialize and assign an instance of SKCameraNode to the cam variable.
        cam.scaleAsPoint = CGPoint(x: 2.0, y: 2.0) //the scale sets the zoom level of the camera on the given position
        
        self.camera = cam //set the scene's camera to reference cam
        self.addChild(cam) //make the cam a childElement of the scene itself.
        
        //position the camera on the gamescene.
        cam.position = hero.hero.position //CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        
        self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        if gameState == .Paused {
            
        }
        else if gameState == .GameOver {
            restartGame()
        }
        else if gameState == .Active {
            /* Called before each frame is rendered */
            
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
            camPosition.x -= 50
            
            let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 1.0/60)
            cam.runAction(moveCamToPlayer)
            
            enemyTimer += fixedDelta
            obstacleTimer += fixedDelta
            
            
            
            /*
            if enemyTimer >= enemyDelaySeconds {
                //addRandomEnemy()
                enemyTimer = 0
            }
            
            if obstacleTimer >= obstacleDelaySeconds{
                addObstacle()
                obstacleTimer = 0
            }
             */
 
            moveEnemies()
            removeEnemiesOutOfBounds()
            
            moveObstacles()
            removeObstaclesOutOfBounds()
            
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
    }
    
    func addRectangleMarchingLine(position:CGPoint, size:CGSize, speed:CGFloat, timingGap:CGFloat){
        
    }
    
    func addObstacle(type:ObstacleType){
        /*
        switch type {
        case .MarchingLine:
            
            break
        case .Door:
            
            break
        case.BackAndForth:
            
            break
        default:
            break
            
        }
        */
        let radius:CGFloat = 10
        let position = CGPoint(x:-300, y:100)
        //let obstacle = Obstacle.init(circleOfRadius: radius)
        let obstacle = Obstacle.init(rect:CGRect(origin:position, size:CGSizeMake(100, 20)))
        obstacle.name = "obs"
        
        obstacle.physicsBody = SKPhysicsBody.init(circleOfRadius: radius, center: position)
        obstacle.physicsBody?.dynamic = true
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.categoryBitMask = 8
        obstacle.physicsBody?.collisionBitMask = 0
        obstacle.physicsBody?.contactTestBitMask = 1
        
        obstacle.zPosition = 1
        
        obstacle.position = position
        obstacle.movementSpeed = 3
        
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
            if (obstacle.direction == .Right && obstacle.position.x > self.frame.width + 500) ||
                (obstacle.direction == .Left && obstacle.position.x < -500) {
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
    
    /*
     func addEnemyGroup(amount:Int, size:CGFloat, position:CGFloat){
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
     }
     */
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
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func randomBool() -> Bool {
        return arc4random_uniform(2) == 0 ? true: false
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
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
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if (nodeA.name == "hero" && nodeB.name == "enemy"){
            heroEnemyContact(nodeA as! Hero, enemy: nodeB as! Enemy)
        }
        else if (nodeA.name == "enemy" && nodeB.name == "hero") {
            heroEnemyContact(nodeB as! Hero, enemy: nodeA as! Enemy)
        }
    }
    
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
}
