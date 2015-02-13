//
//  Player.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation

enum Player {
    case Own
    case Enemy
    func piece() -> Piece {
        switch self {
        case .Own:
            return .Ho
        case .Enemy:
            return .Hu
        }
    }
    func enemy() -> Player {
        switch self {
        case .Own:
            return .Enemy
        case .Enemy:
            return .Own
        }        
    }
}

