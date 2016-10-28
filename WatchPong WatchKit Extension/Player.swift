//
//  Player.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 5/12/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

public protocol PlayerDelegate : class
{
    func onHealthChanged(_ player:Player, newHealth:UInt)
    func onScoreChanged(_ player:Player, newHealth:UInt)
}

open class Player
{
    weak open var delegate:PlayerDelegate? = nil
    
    open var health : UInt = 0
    {
        didSet(newValue)
        {
            if let d = self.delegate
            {
                d.onHealthChanged(self, newHealth:newValue)
            }
        }
    }
    
    open var score : UInt = 0
    {
        didSet(newValue)
        {
            if let d = self.delegate
            {
                d.onScoreChanged(self, newHealth:newValue)
            }
        }
    }
}
