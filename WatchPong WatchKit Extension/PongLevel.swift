//
//  PongLevel.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

open class PongLevel : W2DComponent, W2DBehavior
{
    var     fPlayer: Player!
    var     fBalls =  [W2DNode]()
    var     fPads = [W2DNode]()
    
    var     fMustStartGame = true;
    var     fLost = false;
    
    func willActivate(_ director:W2DDirector!)
    {
        if (fMustStartGame)
        {
            fMustStartGame = false
            startGame(director)
        }
    }
    
    open static func instance(_ scene:W2DScene!) -> PongLevel?
    {
        return scene.component()
    }
    
    public required init(player:Player!)
    {
        fPlayer = player
    }
    
    open var player:Player!
    {
        get { return fPlayer }
    }
    
    open func execute(_ dT:TimeInterval, director:W2DDirector!)
    {
        if !fLost
        {
            // make sure all balls are still in game
            let context = director.context
            let screenBounds = CGRect(x: 0, y: 0, width: CGFloat(context.width), height: CGFloat(context.height))
            
            for ball in fBalls
            {
                let ballBox = ball.globalBoundingBox
                if !screenBounds.contains(ballBox)
                {
                    onBallLost(director, ball:ball)
                    break
                }
            }
        }
    }
    
    fileprivate func createBrick(_ scene:W2DScene, image:W2DImage, id:Int, health:Int) -> W2DNode
    {
        let brick = W2DSprite(image:image, director:scene.director!)
        scene.addChild(brick)
        
        brick.debugName = "brick \(id)"
        
        let collider = W2DCollider()
        brick.addComponent(collider)
        brick.addComponent(Brick(maxHealth: health))
        
        return brick
    }
    
    fileprivate func createBorders(_ scene:W2DScene)
    {
        let director = scene.director!
        
        let context = director.context
        let screenSize = CGSize(width: CGFloat(context.width), height: CGFloat(context.height))
        let color = W2DColor4f(red: 1.0, green: 1.0, blue: 1.0)
        
        let topBorder = W2DColoredNode(color: color, director: director)
        topBorder.size = CGSize(width: screenSize.width, height: 4.0);
        topBorder.position = CGPoint(x: 0, y: 0)
        topBorder.addComponent(W2DCollider())
        topBorder.debugName = "topBorder"
        scene.addChild(topBorder)
        
        let bottomBorder = W2DColoredNode(color: color, director: director)
        bottomBorder.size = CGSize(width: screenSize.width, height: 4.0);
        bottomBorder.position = CGPoint(x: 0, y: screenSize.height - bottomBorder.size.height)
        bottomBorder.addComponent(W2DCollider())
        topBorder.debugName = "bottomBorder"
        scene.addChild(bottomBorder)
        
        let leftBorder = W2DColoredNode(color: color, director: director)
        leftBorder.size = CGSize(width: 4, height: screenSize.height);
        leftBorder.position = CGPoint(x: 0, y: 0)
        leftBorder.addComponent(W2DCollider())
        topBorder.debugName = "leftBorder"
        scene.addChild(leftBorder)
    }
    
    fileprivate func createBricks(_ scene:W2DScene)
    {
        var pt = CGPoint(x: 16, y: 0);
        
        let director = scene.director!

        let greenBrickImage = director.context.image(named:"brick-green.png")
        let greenBrickSize = greenBrickImage!.size
        
        var id = 0
        
        for _ in 1...6
        {
            let brick = createBrick(scene, image:greenBrickImage!, id:id, health:3)
            id += 1
            
            brick.position = pt
            
            let brickComponent : Brick = brick.component()!
            brickComponent.otherScaleAfterCollision = 0.5
            
            pt.y += greenBrickSize.height * 1.05
        }
        
        let redBrickImage = director.context.image(named:"brick-red.png")
        let redBrickSize = redBrickImage!.size
        
        pt = CGPoint(x: 16 + 2 * greenBrickSize.width, y: greenBrickSize.height * 0.5)
        var rot : CGFloat = 10 * (CGFloat(M_PI) / 180.0)
        
        for _ in 1...4
        {
            let brick = createBrick(scene, image:redBrickImage!, id:id, health:2)
            id += 1

            brick.position = pt
            brick.scale = 0.7
            brick.rotation = rot
            rot = -rot
            
            pt.y += redBrickSize.height * 1.1
        }
        
        pt = CGPoint(x: 16 + 4 * redBrickSize.width, y: redBrickSize.height * 0.25)
        for _ in 1...2
        {
            let brick = createBrick(scene, image:redBrickImage!, id:id, health:1)
            id += 1

            brick.position = pt
            
            pt.y += redBrickSize.height * 2
        }
    }
    
    fileprivate func createBall(_ scene:W2DScene) -> W2DNode
    {
        let director = scene.director!
        
        let sprite = W2DSprite(named: "ball.png", inDirector:director)
        sprite.debugName = "ball"
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        //sprite.scale = 0.5
        
        scene.addChild(sprite)
        
        let ballBeh = BallBehavior()
        sprite.addComponent(ballBeh)
        director.addBehavior(ballBeh)
 
        return sprite
    }
    
    fileprivate func createPad(_ scene:W2DScene) -> W2DNode
    {
        let director = scene.director!
        
        let sprite = W2DSprite(named:"pad.png", inDirector: director)
        sprite.debugName = "pad"
        scene.addChild(sprite)
        
        sprite.position = CGPoint(x: CGFloat(director.context.width) - sprite.size.width, y: 0)
        let padBeh = W2DCollider()
        padBeh.bounceSpeedFactor = 1.3
        padBeh.collisionCallback = {
            (collision: inout W2DCollision) -> W2DCollision? in
            {
                WKInterfaceDevice.current().play(.retry)
                
                if collision.edgeIndex == 0 // left edge
                {
                    // deviate the direction depending on distance to middle
                    let hitY = collision.hitPoint.y
                    let myBox = collision.hitNode.globalBoundingBox
                    
                    let middleY = myBox.origin.y + myBox.size.height / 2
                    let normalizedDist = 2.0 * (hitY - middleY) / myBox.size.height
                    
                    let deviationRange: CGFloat = 20.0
                    let deviationAngleInDegree = (-normalizedDist * deviationRange)
                    let deviationAngle = deviationAngleInDegree * CGFloat(M_PI) / 180.0
                    
                    let rotation = CGAffineTransform(rotationAngle: deviationAngle)
                    let deviatedDirection = collision.bounceDirection.applying(rotation)
                                        
                    collision.bounceDirection = deviatedDirection.normalizedVector()
                }
                
                return collision
            }()}
        
        sprite.addComponent(padBeh)
        
        return sprite
    }
    
    open func createScene(_ director:W2DDirector) -> W2DScene
    {
        let scene = W2DScene(director: director)
        scene.addComponent(self)
        
        createBorders(scene)
        createBricks(scene)
        
        let ball = createBall(scene)
        fBalls.append(ball)
        
        let pad = createPad(scene)
        fPads.append(pad)
        
        return scene
    }
    
    fileprivate func startGame(_ director:W2DDirector!)
    {
        director.addBehavior(self)
                
        let normalizedPadY = Float(0.5)
        director.setDigitalCrownValue(normalizedPadY)
        self.setPadPosition(normalizedPadY, director:director)
        
        for ball in fBalls
        {
            if let movingObject: MovingObject? = ball.component()
            {
                movingObject?.resetToInitialState()
            }
        }

        fLost = false
        director.currentScene!.backgroundColor = nil
    }

    fileprivate func onBallLost(_ director:W2DDirector!, ball:W2DNode!)
    {
        fLost = true
        
        let movingObjectOrNil: MovingObject? = ball.component()
        if let movingObject = movingObjectOrNil
        {
            movingObject.speed = 0.0
        }
        
        director.currentScene!.backgroundColor = W2DColor4f(red:1, green:0, blue:0)
        WKInterfaceDevice.current().play(.failure)
        
        fPlayer.health = fPlayer.health - 1
        
        // lost anim
        let actionDuration : TimeInterval = 0.25
        
        let fadeToRed = W2DLambdaAction(duration: actionDuration,
            lambda: {(target:W2DNode?, c:CGFloat) in
                let color = W2DColor4f(red:c, green:0, blue:0, alpha:c)
                director.currentScene!.backgroundColor = color

        })
        fadeToRed.name = "fadeToRed"
        
        let fadeToTransparent = W2DLambdaAction(duration:actionDuration,
            lambda: {(target:W2DNode?, c:CGFloat) in
                let color = W2DColor4f(red:1.0 - c, green:0, blue:0, alpha:1.0 - c)
                director.currentScene!.backgroundColor = color
                
        })
        fadeToTransparent.name = "fadeToTransparent"
        
        let completion = W2DLambdaAction(
            lambda: {(target:W2DNode?, c:CGFloat) in
            if self.fPlayer.health == 0
            {
                // Game Over
                director.stop()
            }
            else if let movingObject = movingObjectOrNil
            {
                director.currentScene!.backgroundColor = nil
                
                // reposition ball and resume
                movingObject.resetToInitialState()
                self.fLost = false
            }
        })
        completion.name = "LostAnimCompletion"

        // Blinking ball
        let makeBallInvisibleAction = W2DLambdaAction(
                                                lambda: {(target:W2DNode?, c:CGFloat) in

                                                ball.hidden = true
                                                    
        })
        makeBallInvisibleAction.name = "makeBallInVisibleAction"

        let makeBallVisibleAction = W2DLambdaAction(
                                                      lambda: {(target:W2DNode?, c:CGFloat) in

                                                ball.hidden = false
                                                        
        })
        makeBallVisibleAction.name = "makeBallVisibleAction"
        
        let blinkBallAction = W2DSequenceAction()
        blinkBallAction.addAction(makeBallInvisibleAction)
        blinkBallAction.addAction(W2DDelayAction(duration: actionDuration))
        blinkBallAction.addAction(makeBallVisibleAction)
        blinkBallAction.addAction(W2DDelayAction(duration: actionDuration))
        
        
        let fadeBackgroundAction = W2DSequenceAction()
        fadeBackgroundAction.addAction(fadeToRed)
        fadeBackgroundAction.addAction(fadeToTransparent)
        
        let spawnAction = W2DSpawnAction()
        spawnAction.addAction(blinkBallAction)
        spawnAction.addAction(fadeBackgroundAction)
        
        let repeatAction = W2DRepeatAction(action: spawnAction, count: 2)
        
        let lostAnim = W2DSequenceAction()
        lostAnim.addAction(repeatAction)
        lostAnim.addAction(completion)
        
        director.currentScene!.run(lostAnim)
    }
    
    internal func setPadPosition(_ value:Float, director:W2DDirector!)
    {
        let context = director.context
        
        for pad in fPads
        {
            let availableHeight = CGFloat(context.height) - pad.size.height
            
            var pos = pad.position
            pos.y = CGFloat(value) * availableHeight
            pad.position = pos
        }
    }

}
