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
            let ballSize = ball.size
            let maxX = contextWidth - ballSize.width
            
            let pos = ball.position
            if pos.x >= maxX // going to far on the right
            {
                onLost(director)
                break
            }
        }
    }
    
    private func createBrick(scene:W2DScene, image:W2DImage) -> W2DNode
    {
        let brick = W2DSprite(image:image, director:scene.director!)
        scene.addChild(brick)
        
        let collider = Collider()
        collider.collisionCallback = {
            [](collision:Collision) -> Collision? in
            {
                collision.node.removeFromParent()
                
                return collision
            }()}
        
        brick.addComponent(collider)
        
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
        topBorder.addComponent(Collider())
        scene.addChild(topBorder)
        
        let bottomBorder = W2DColoredNode(color: color, director: director)
        bottomBorder.size = CGSizeMake(screenSize.width, 4.0);
        bottomBorder.position = CGPointMake(0, screenSize.height - bottomBorder.size.height)
        bottomBorder.addComponent(Collider())
        scene.addChild(bottomBorder)
        
        let leftBorder = W2DColoredNode(color: color, director: director)
        leftBorder.size = CGSizeMake(4, screenSize.height);
        leftBorder.position = CGPointMake(0, 0)
        leftBorder.addComponent(Collider())
        scene.addChild(leftBorder)
    }
    
    private func createBricks(scene:W2DScene)
    {
        var pt = CGPointMake(16, 0);
        
        let director = scene.director!
        
        let brickImage = director.context.image(named:"brick-red.png")
        let brickSize = brickImage!.size
        
        for _ in 1...6
        {
            let brick = createBrick(scene, image:brickImage!)
            brick.position = pt
            
            pt.y += brickSize.height * 1.05
        }
        
        pt = CGPointMake(16 + 2 * brickSize.width, brickSize.height * 0.5)
        for _ in 1...4
        {
            let brick = createBrick(scene, image:brickImage!)
            brick.position = pt
            
            pt.y += brickSize.height * 1.1
        }
        
        pt = CGPointMake(16 + 4 * brickSize.width, brickSize.height * 0.25)
        for _ in 1...2
        {
            let brick = createBrick(scene, image:brickImage!)
            brick.position = pt
            
            pt.y += brickSize.height * 2
        }
    }
    
    private func createBall(scene:W2DScene) -> W2DNode
    {
        let director = scene.director!
        
        let sprite = W2DSprite(named: "ball.png", inDirector:director)
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
        scene.addChild(sprite)
        
        sprite.position = CGPointMake(CGFloat(director.context.width) - sprite.size.width, 0)
        let padBeh = Collider()
        padBeh.bounceSpeedFactor = 1.3
        padBeh.collisionCallback = {
            (var collision:Collision) -> Collision? in
            {
                WKInterfaceDevice.currentDevice().playHaptic(.Retry)
                
                if (collision.edge == .left)
                {
                    // deviate the direction depending on distance to middle
                    let hitY = collision.hitPoint.y
                    let myBox = collision.node.globalBoundingBox
                    assert(hitY >= myBox.origin.y)
                    assert(hitY <= myBox.origin.y + myBox.size.height)
                    
                    let middleY = myBox.origin.y + myBox.size.height / 2
                    var normalizedDist = 2.0 * (hitY - middleY) / myBox.size.height
                    //normalizedDist *= normalizedDist
                    
                    assert(normalizedDist <= 1.0)
                    assert(normalizedDist >= -1.0)
                    
                    let deviationRange: CGFloat = 20.0
                    let deviationAngleInDegree = (-normalizedDist * deviationRange)
                    let deviationAngle = deviationAngleInDegree * CGFloat(M_PI) / 180.0
                    
                    let rotation = CGAffineTransformMakeRotation(deviationAngle)
                    let deviatedDirection = CGPointApplyAffineTransform(collision.direction, rotation)
                                        
                    collision.direction = deviatedDirection.normalizedVector()
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
            let ballPos = CGPointMake(contextWidth - (2 * ballSize.width), (contextHeight - ballSize.height) / 2)
            ball.position = ballPos
        }

        fLost = false
        director.currentScene!.backgroundColor = W2DColor4f()
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
