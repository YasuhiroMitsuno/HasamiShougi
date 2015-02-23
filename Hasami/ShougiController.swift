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
        srandomdev()
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
            movablePoints = model.movablePoints(selectedPoint!)
            
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
    
    func reset() {
        model = ShougiModel()
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
        let start = NSDate()
        
        var tmpModel = model
        var nModel = model.copy()
        model = nModel
        
        let cPlayer = currentPlayer()

        var maxDamage: Double = 0
        var minDamage: Double = 100
        var diff: Bool = false
        var sPiece: Point?
        var sPoint: Point?
        let currentScore = model.score(cPlayer)
        let currentEScore = model.score(cPlayer.enemy())
        let score = model.score(cPlayer.enemy()) - model.score(cPlayer)
        var twice: Bool = false
        var pieces = pieceOfPlayer(cPlayer)
        for piece in pieces {
            select(piece)
            for point in movablePoints {
                select(piece)
                movePiece(point)
                maxDamage = -100
                var pieces2 = pieceOfPlayer(cPlayer.enemy())
                for piece2 in pieces2 {
                    select(piece2)
                    var alphacut: Bool = false
                    for point2 in movablePoints {
                        select(piece2)
                        movePiece(point2)
                        if Double(model.score(cPlayer.enemy())) - Double(model.score(cPlayer)) >= maxDamage {
                            maxDamage = Double(model.score(cPlayer.enemy())) - Double(model.score(cPlayer))
                        }
                        if model.score(cPlayer.enemy()) != currentEScore || model.score(cPlayer) != currentScore {
                            diff = true
                        }
                        model.popState()
                        if maxDamage >= minDamage {
                            alphacut = true
                            break
                        }
                    }
                    if alphacut {
                        break
                    }
                }
                if maxDamage < minDamage {
                    sPiece = piece
                    sPoint = point
                    minDamage = maxDamage
                }
                model.popState()
            }
        }



        model = tmpModel
        if diff {
            select(sPiece)
            movePiece(sPoint!)
        } else {
            randomAlgorithm()
        }
        let elapsed = NSDate().timeIntervalSinceDate(start)
        println(elapsed)
    }

    func randomAlgorithm() {
        NSLog("random")
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