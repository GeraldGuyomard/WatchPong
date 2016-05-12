//
//  BallBehavior.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

class BallBehavior : W2DComponent, W2DBehavior, MovingObject
{
    var     fDirection : CGPoint = CGPointMake(0, 0)
    var     fSpeed : CGFloat = 0;
    
    var direction : CGPoint
    {
        get { return fDirection }
        set(newValue) { fDirection = newValue }
    }
    
    var speed : CGFloat
    {
        get { return fSpeed }
        set(newValue) { fSpeed = newValue }
    }
    
    func resetToInitialState()
    {
        // random angle between -45 and 45
        let rInt = rand()
        let r = Float(Double(rInt) / Double(RAND_MAX))
        let minV : Float = -45.0
        let maxV : Float = 45.0
        let a = (r * (maxV - minV)) + minV
        
        let angle = Float(a) * Float(M_PI) / 180
        
        let x = CGFloat(-cosf(angle))
        let y = CGFloat(-sinf(angle))
        
        // normalization is in theory already normalized...
        fDirection = CGPoint(x:x, y:y).normalizedVector()
        fSpeed = 60.0
        
        // Position on screen
        let myNodeOrNil : W2DNode? = self.component()
        if let myNode = myNodeOrNil
        {
            let ballSize = myNode.size
            let s = myNode.scale
            
            let context = myNode.director!.context
            
            let contextWidth = CGFloat(context.width)
            let contextHeight = CGFloat(context.height)
            
            let ballPos = CGPointMake(contextWidth - (2 * ballSize.width * s), (contextHeight - (ballSize.height * s)) / 2)
            myNode.position = ballPos
        }
    }
    
    func execute(dT:NSTimeInterval, director:W2DDirector!)
    {
        let dV = fSpeed * CGFloat(dT)
        
        let sprite : W2DSprite? = component()
        
        guard let ballSprite = sprite
        else
        {
            return;
        }
        
        // try to collide with any collider in the scene
        let collisions = W2DCollider.collideInScene(director.currentScene!, movingNode:sprite, direction:fDirection, instantaneousSpeed:dV)
        if !collisions.isEmpty
        {
            var closestCollision : W2DCollision?
            var minDist = CGFloat.max
            
            for c in collisions
            {
                if (c.distanceToEdge < minDist)
                {
                    minDist = c.distanceToEdge
                    closestCollision = c
                }
            }
            
            // move back the ball
            let edgeNormal = closestCollision!.edgeNormal
            let stepBack = edgeNormal.mul(closestCollision!.distanceToEdge)
            let newPos = closestCollision!.hitPoint.add(stepBack)
            
            ballSprite.position = newPos
            
            fDirection = closestCollision!.bounceDirection
            fSpeed *= closestCollision!.bounceSpeedFactor
            
            let maxBallSpeed :CGFloat = 120
            
            if fSpeed > maxBallSpeed
            {
                fSpeed = maxBallSpeed
            }
        }
        else
        {
            // move the ball linearly
            let v = fDirection.mul(dV);
            
            let newBallPos = ballSprite.position.add(v)
            ballSprite.position = newBallPos
        }
    }
}

