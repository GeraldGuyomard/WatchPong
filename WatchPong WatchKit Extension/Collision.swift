//
//  Collision.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import Foundation
import WatchScene2D

public struct Collision
{
    public var hitNode : W2DNode!
    public var hitPoint : CGPoint
    
    public var movingNode: W2DNode!
    
    public var bounceDirection : CGPoint
    public var bounceSpeedFactor: CGFloat
    
    public enum Edge
    {
        case left
        case top
        case right
        case bottom
    }
    
    public var edge : Edge
    public var distanceToEdge : CGFloat
    public var edgeNormal: CGPoint
    
    public func closerThan(collision:Collision?) -> Bool
    {
        if let c = collision
        {
            return distanceToEdge < c.distanceToEdge
        }
        else
        {
            return true
        }
    }
}