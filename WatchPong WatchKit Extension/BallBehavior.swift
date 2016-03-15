//
//  BallBehavior.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

class BallBehavior : W2DComponent, W2DBehavior
{
    var     fBallDirection : CGPoint = CGPointMake(0, 0)
    var     fBallSpeed : CGFloat = 0;
    
    override init()
    {
        super.init()
        
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
        fBallDirection = CGPoint(x:x, y:y).normalizedVector()
        
        fBallSpeed = 60.0
    }
    
    func execute(dT:NSTimeInterval, director:W2DDirector!)
    {
        let dV = fBallSpeed * CGFloat(dT)
        
        let sprite : W2DSprite? = component()
        
        guard let ballSprite = sprite
        else
        {
            return;
        }
        
        // try to collide with any collider in the scene
        let collisions = W2DCollider.collideInScene(director.currentScene!, movingNode:sprite, direction:fBallDirection, instantaneousSpeed:dV)
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
            
            fBallDirection = closestCollision!.bounceDirection
            fBallSpeed *= closestCollision!.bounceSpeedFactor
            
            let maxBallSpeed :CGFloat = 120
            
            if fBallSpeed > maxBallSpeed
            {
                fBallSpeed = maxBallSpeed
            }
        }
        else
        {
            // move the ball linearly
            let v = fBallDirection.mul(dV);
            
            let newBallPos = ballSprite.position.add(v)
            ballSprite.position = newBallPos
        }
    }
}

