//
//  Collider.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import Foundation
import WatchScene2D

public class Collider : W2DComponent
{
    public var isActive = true
    
    static public func collideInScene(scene:W2DScene!, ball:W2DNode!, direction:CGPoint, instantaneousSpeed:CGFloat) -> [Collision]
    {
        var collisions = [Collision]()
        _collideRecursive(scene, considerThisNode: false, ball:ball, direction:direction, instantaneousSpeed:instantaneousSpeed, collisions:&collisions)
        return collisions
    }
    
    static private func _collideRecursive(node:W2DNode!, considerThisNode:Bool, ball:W2DNode!, direction:CGPoint, instantaneousSpeed:CGFloat, inout collisions:[Collision])
    {
        if considerThisNode
        {
            let collider : Collider? = node.component()
            if let c = collider
            {
                if let collision = c.collide(ball, direction: direction, instantaneousSpeed:instantaneousSpeed)
                {
                    collisions.append(collision)
                }
            }
        }
        
        if let children = node.children
        {
            for child in children
            {
                _collideRecursive(child, considerThisNode: true, ball: ball, direction: direction, instantaneousSpeed: instantaneousSpeed, collisions:&collisions)
            }
        }
    }
    
    public var bounceSpeedFactor : CGFloat = 1.0
    
    public var collisionCallback : ((collision:Collision) -> Collision?)?

    public func collide(otherNode:W2DNode!, direction:CGPoint, instantaneousSpeed:CGFloat) -> Collision?
    {
        if !self.isActive
        {
            return nil
        }
        
        let m : W2DNode? = component()
        guard let myNode = m
            else
        {
            return nil
        }
        
        // first easy rejections with AABBs
        let myBox = myNode.globalBoundingBox
        let otherBox = otherNode.globalBoundingBox
        
        var otherMovedBox = otherBox
        otherMovedBox.origin = otherMovedBox.origin.add(direction.mul(instantaneousSpeed))
        
        let otherMovingBox = CGRectUnion(otherBox, otherMovedBox)
        
        if (!myBox.intersects(otherMovingBox))
        {
            return nil
        }
        
        // ray box intersection is happening now
        let radius = otherBox.size.width / 2.0
        let pos = CGPointMake(otherBox.origin.x + radius, otherBox.origin.y + radius)
        
        var collision : Collision? = nil
        
        let A = myBox.origin
        let B = CGPointMake(myBox.origin.x, myBox.origin.y + myBox.size.height)
        let C = CGPointMake(myBox.origin.x + myBox.size.width, myBox.origin.y + myBox.size.height)
        let D = CGPointMake(myBox.origin.x + myBox.size.width, myBox.origin.y)
        
        if let c = collisionWithEdge(Collision.Edge.left, myNode: myNode, otherNodePosition: pos, otherNodeRadius: radius, vertex1: A, vertex2:B, direction:direction, newDirection: CGPointMake(-direction.x, direction.y))
        {
            if (collision == nil) || (collision!.t > c.t)
            {
                collision = c
            }
        }

        if let c = collisionWithEdge(Collision.Edge.right, myNode: myNode, otherNodePosition: pos, otherNodeRadius: radius, vertex1: D, vertex2:C, direction:direction,newDirection: CGPointMake(-direction.x, direction.y))
        {
            if (collision == nil) || (collision!.t > c.t)
            {
                collision = c
            }
        }

        if let c = collisionWithEdge(Collision.Edge.bottom, myNode: myNode, otherNodePosition: pos, otherNodeRadius: radius, vertex1: A, vertex2:D, direction:direction,newDirection: CGPointMake(direction.x, -direction.y))
        {
            if (collision == nil) || (collision!.t > c.t)
            {
                collision = c
            }
        }

        if let c = collisionWithEdge(Collision.Edge.top, myNode: myNode, otherNodePosition: pos, otherNodeRadius: radius, vertex1: B, vertex2:C, direction:direction,newDirection: CGPointMake(direction.x, -direction.y))
        {
            if (collision == nil) || (collision!.t > c.t)
            {
                collision = c
            }
        }
        
        if let c = collision
        {
            if let cb = self.collisionCallback
            {
                collision = cb(collision: c)
            }
        }
        
        return collision
    }

    private func collisionWithEdge(edge: Collision.Edge, myNode:W2DNode, otherNodePosition:CGPoint, otherNodeRadius:CGFloat, vertex1:CGPoint, vertex2:CGPoint, direction:CGPoint, newDirection:CGPoint) ->Collision?
    {
        let AO = otherNodePosition.sub(vertex1)
        let edgeNormal = edge.normal
        if AO.dot(edgeNormal) <= 0
        {
            return nil
        }
        
        if direction.dot(edgeNormal) >= 0
        {
            return nil
        }
        
        let AB = vertex2.sub(vertex1)
        
        let edgeLength = AB.norm()
        let normalizedEdge = CGPointMake(AB.x / edgeLength, AB.y / edgeLength)
        
        let AH = AO.dot(normalizedEdge)
        if AH < -otherNodeRadius
        {
            return nil
        }
        
        if AH > edgeLength
        {
            return nil
        }
        
        // perpendicular distance
        let squareOHLength = AO.squareNorm() - (AH * AH)
        if squareOHLength > (otherNodeRadius * otherNodeRadius)
        {
            // too far
            return nil
        }
        
        let hitPoint = CGPointMake(vertex1.x + (normalizedEdge.x * AH), vertex1.y + (normalizedEdge.y * AH))
        let t = sqrt(squareOHLength)
        
        return Collision(node:myNode, hitPoint:hitPoint, direction:newDirection, bounceSpeedFactor:bounceSpeedFactor, t:t, edge:edge)
    }
}
