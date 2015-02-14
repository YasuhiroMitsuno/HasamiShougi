//
//  ShougiController.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation


class ShougiController {
    private var model: ShougiModel
    private var selectedPoint: Point?
    var movablePoints: [Point]

    init() {
        model = ShougiModel()
        movablePoints = Array()
    }
    
    func piece(point: Point) -> Piece {
        return model.piece(point)
    }
    
    func selectedPiece() -> Piece? {
        if var point = selectedPoint {
            return model.piece(point)
        }
        return nil
    }
    func currentPlayer() -> Player {
        return model.currentData.turn
    }
    func select(point: Point?) -> Bool {
        if var _point = point {
            if !model.checkPoint(_point) || model.piece(_point).type == .Masu {
                return false
            }
            // 選択したピースの所有権が選択者か判定
            if model.piece(_point).type != currentPlayer().pieceType() {
                return false
            }

            selectedPoint = _point
            movablePoints.removeAll();

            for vector in vectors {
                for var p:Point=selectedPoint!+vector;model.checkPoint(p);p=p+vector {
                    if model.piece(p).type != .Masu {
                        break
                    }
                    movablePoints.append(p)
                }
            }
            
            return true
        }
        return false
    }
    func unselect() {
        movablePoints.removeAll();
        selectedPoint = nil;
    }
    
    func canMove(p: Point) -> Bool {
        if let _selectedPoint = selectedPoint {
            if movablePoints.filter({T in T == p}).count > 0 {
                return true
            }
        }
        return false
    }

    func movePiece(p: Point) -> Bool {
        if !canMove(p) {
            return false
        }

        // 動かす前の状態を保存
        model.pushState()
        // コマの移動
        let points =  model.move(selectedPoint!, to: p)
        // ターン交代
        model.switchPlayer()
        
        unselect()
        return true
    }
    
    // 待った
    func matta() -> Bool {
        if model.dataCount() < 2 {
            return false
        }
        unselect()
        model.popState()
        model.popState()
        return true
    }
    
    // 勝利していたらプレーヤーを返す
    func winner() -> Player? {
        if model.score(.Own) >= 5 {
            return .Own
        }
        if model.score(.Enemy) >= 5 {
            return .Enemy
        }
        if model.dataCount() > 2 {
            if abs(model.prevScore(.Own, offset: 1) - model.prevScore(.Enemy, offset: 1)) >= 3 &&
                abs(model.score(.Own) - model.score(.Enemy)) >= 3 {
                    return model.score(.Own) > model.score(.Enemy) ? .Own : .Enemy
            }
        }
        return nil
    }
    
    func pieceOfPlayer(player: Player) -> [Point] {
        var arr:[Point] = Array()
        for i in 0...8 {
            for j in 0...8 {
                if piece(Point(y: i, x: j)).type == player.pieceType() {
                    arr.append(Point(y: i, x: j))
                }
            }
        }
        return arr
    }
}

extension ShougiController {
    func algorithm() {
        var tmpModel = model
        var nModel = model.copy()
        model = nModel
        
        let cPlayer = currentPlayer()

        var maxScore: Int = 0
        var sPiece: Point?
        var sPoint: Point?
        let currentScore = model.score(cPlayer)

        var pieces = pieceOfPlayer(currentPlayer())
        for piece in pieces {
            select(piece)
            for point in movablePoints {
                movePiece(point)
                if model.score(cPlayer) >= maxScore {
                    maxScore = model.score(cPlayer)
                    sPiece = piece
                    sPoint = point
                }                
                model.popState()
                select(piece)
            }
        }



        model = tmpModel
        if maxScore > currentScore {
            select(sPiece)
            movePiece(sPoint!)
        } else {
            randomAlgorithm()
        }
    }
    
    
    
    func randomAlgorithm() {
        var pieces = pieceOfPlayer(currentPlayer())
        var r = random()%pieces.count
        select(pieceOfPlayer(currentPlayer())[r])
        var c = movablePoints.count
        if c != 0 {
            var p = movablePoints[random()%c]
            movePiece(p)
        }
    }
}