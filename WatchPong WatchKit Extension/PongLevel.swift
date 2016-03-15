//
//  PongLevel.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

public class PongLevel : W2DComponent, W2DBehavior
{
    var     fBalls =  [W2DNode]()
    var     fPads = [W2DNode]()
    
    var     fMustStartGame = true;
    var     fLost = false;
    
    func willActivate(director:W2DDirector!)
    {
        if (fMustStartGame)
        {
            fMustStartGame = false
            startGame(director)
        }
    }
    
    public func execute(dT:NSTimeInterval, director:W2DDirector!)
    {
        // make sure all balls are still in game
        let context = director.context
        let contextWidth = CGFloat(context.width);
        
        for ball in fBalls
        {            
            let ballBox = ball.globalBoundingBox
            let ballPos = ballBox.origin.x + ballBox.size.width
            if ballPos >= contextWidth // going to far on the right
            {
                onLost(director)
                break
            }
        }
    }
    
    private func createBrick(scene:W2DScene, image:W2DImage, id:Int, health:Int) -> W2DNode
    {
        let brick = W2DSprite(image:image, director:scene.director!)
        scene.addChild(brick)
        
        brick.debugName = "brick \(id)"
        
        let collider = W2DCollider()
        brick.addComponent(collider)
        brick.addComponent(Brick(maxHealth: health))
        
        return brick
    }
    
    private func createBorders(scene:W2DScene)
    {
        let director = scene.director!
        
        let context = director.context
        let screenSize = CGSizeMake(CGFloat(context.width), CGFloat(context.height))
        let color = W2DColor4f(red: 1.0, green: 1.0, blue: 1.0)
        
        let topBorder = W2DColoredNode(color: color, director: director)
        topBorder.size = CGSizeMake(screenSize.width, 4.0);
        topBorder.position = CGPointMake(0, 0)
        topBorder.addComponent(W2DCollider())
        topBorder.debugName = "topBorder"
        scene.addChild(topBorder)
        
        let bottomBorder = W2DColoredNode(color: color, director: director)
        bottomBorder.size = CGSizeMake(screenSize.width, 4.0);
        bottomBorder.position = CGPointMake(0, screenSize.height - bottomBorder.size.height)
        bottomBorder.addComponent(W2DCollider())
        topBorder.debugName = "bottomBorder"
        scene.addChild(bottomBorder)
        
        let leftBorder = W2DColoredNode(color: color, director: director)
        leftBorder.size = CGSizeMake(4, screenSize.height);
        leftBorder.position = CGPointMake(0, 0)
        leftBorder.addComponent(W2DCollider())
        topBorder.debugName = "leftBorder"
        scene.addChild(leftBorder)
    }
    
    private func createBricks(scene:W2DScene)
    {
        var pt = CGPointMake(16, 0);
        
        let director = scene.director!
        
        let brickImage = director.context.image(named:"brick-red.png")
        let brickSize = brickImage!.size
        
        var id = 0
        
        for _ in 1...6
        {
            let brick = createBrick(scene, image:brickImage!, id:id++, health:3)
            brick.position = pt
            
            let brickComponent : Brick = brick.component()!
            brickComponent.otherScaleAfterCollision = 0.5
            
            pt.y += brickSize.height * 1.05
        }
        
        pt = CGPointMake(16 + 2 * brickSize.width, brickSize.height * 0.5)
        for _ in 1...4
        {
            let brick = createBrick(scene, image:brickImage!, id:id++, health:2)
            brick.position = pt
            
            pt.y += brickSize.height * 1.1
        }
        
        pt = CGPointMake(16 + 4 * brickSize.width, brickSize.height * 0.25)
        for _ in 1...2
        {
            let brick = createBrick(scene, image:brickImage!, id:id++, health:1)
            brick.position = pt
            
            pt.y += brickSize.height * 2
        }
    }
    
    private func createBall(scene:W2DScene) -> W2DNode
    {
        let director = scene.director!
        
        let sprite = W2DSprite(named: "ball.png", inDirector:director)
        sprite.debugName = "ball"
        sprite.anchorPoint = CGPointMake(0.5, 0.5)
        //sprite.scale = 0.5
        
        scene.addChild(sprite)
        
        let ballBeh = BallBehavior()
        sprite.addComponent(ballBeh)
        director.addBehavior(ballBeh)
 
        return sprite
    }
    
    private func createPad(scene:W2DScene) -> W2DNode
    {
        let director = scene.director!
        
        let sprite = W2DSprite(named:"pad.png", inDirector: director)
        sprite.debugName = "pad"
        scene.addChild(sprite)
        
        sprite.position = CGPointMake(CGFloat(director.context.width) - sprite.size.width, 0)
        let padBeh = W2DCollider()
        padBeh.bounceSpeedFactor = 1.3
        padBeh.collisionCallback = {
            (var collision:W2DCollision) -> W2DCollision? in
            {
                WKInterfaceDevice.currentDevice().playHaptic(.Retry)
                
                if collision.edgeIndex == 0 // left edge
                {
                    // deviate the direction depending on distance to middle
                    let hitY = collision.hitPoint.y
                    let myBox = collision.hitNode.globalBoundingBox
                    
                    let middleY = myBox.origin.y + myBox.size.height / 2
                    var normalizedDist = 2.0 * (hitY - middleY) / myBox.size.height
                    
                    let deviationRange: CGFloat = 20.0
                    let deviationAngleInDegree = (-normalizedDist * deviationRange)
                    let deviationAngle = deviationAngleInDegree * CGFloat(M_PI) / 180.0
                    
                    let rotation = CGAffineTransformMakeRotation(deviationAngle)
                    let deviatedDirection = CGPointApplyAffineTransform(collision.bounceDirection, rotation)
                                        
                    collision.bounceDirection = deviatedDirection.normalizedVector()
                }
                
                return collision
            }()}
        
        sprite.addComponent(padBeh)
        
        return sprite
    }
    
    public func createScene(director:W2DDirector) -> W2DScene
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
    
    private func startGame(director:W2DDirector!)
    {
        director.addBehavior(self)
        
        let context = director.context
        
        let contextWidth = CGFloat(context.width)
        let contextHeight = CGFloat(context.height)
        
        let normalizedPadY = Float(0.5)
        director.setDigitalCrownValue(normalizedPadY)
        self.setPadPosition(normalizedPadY, director:director)
        
        for ball in fBalls
        {
            let ballSize = ball.size
            let s = ball.scale
            let ballPos = CGPointMake(contextWidth - (2 * ballSize.width * s), (contextHeight - (ballSize.height * s)) / 2)
            ball.position = ballPos
        }

        fLost = false
        director.currentScene!.backgroundColor = W2DColor4f(red: 0, green: 0, blue: 0, alpha: 0)
    }

    private func onLost(director:W2DDirector!)
    {
        fLost = true
        director.currentScene!.backgroundColor = W2DColor4f(red:1, green:0, blue:0)
        
        WKInterfaceDevice.currentDevice().playHaptic(.Failure)
        
        director.stop()
    }
    
    internal func setPadPosition(value:Float, director:W2DDirector!)
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
