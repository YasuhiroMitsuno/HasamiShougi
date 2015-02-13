//
//  ShougiModel.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation

struct Point {
    var y: Int, x:Int
    init(y: Int, x: Int) {
        self.y = y
        self.x = x
    }
}

func +(l: Point, r: Point) -> Point {
    return Point(y: l.y + r.y, x:l.x + r.x)
}

func ==(l: Point, r: Point) -> Bool {
    return l.y == r.y && l.x == r.x
}


enum Direction:Int {
    case Up = 1
    case Down, Left, Right
    func toPoint() -> Point {
        switch self {
        case .Up:
            return Point(y: -1, x: 0)
        case .Down:
            return Point(y: 1, x: 0)
        case .Left:
            return Point(y: 0, x: -1)
        case .Right:
            return Point(y: 0, x: -1)
        }
    }
}

enum Piece: Int {
    case Ho, Hu, Masu
}

class BoardData {
    var bin: [[Piece]]
    var turn : Player
    var score: [Player:Int]
    init() {
        bin = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: Piece.Masu))
        for i in 0...8 {
            bin[0][i] = .Hu
            bin[8][i] = .Ho
        }
        turn = .Own
        score = Dictionary(dictionaryLiteral: (.Own, 0), (.Enemy, 0))
    }
    func copy()->BoardData {
        var newBoardData = BoardData()
        newBoardData.turn = turn
        newBoardData.score = score
        return newBoardData
    }
}

protocol ShougiAlgorithmProtocol {
    func hasami(Point) -> Int
}

class ShougiModel {
    private var datas: [BoardData]
    private var currentData: BoardData
    private var selectedPoint: Point?

    init() {
        datas = Array()
        currentData = BoardData()
    }
    
    func piece(p: Point) -> Piece {
        return currentData.bin[p.y][p.x]
    }
    func dataCount() -> Int {
        return datas.count
    }
    func checkPoint(p: Point) -> Bool {
        return p.y >= 0 && p.y < 9 && p.x >= 0 && p.x < 9
    }
    func pushState() {
        datas.append(currentData.copy())
    }
    func popState() {
        currentData =  datas.last!
        datas.removeLast()
    }
    // コマを動かし，ポイントを追加
    func move(from: Point, to: Point) -> Int {
        currentData.bin[to.y][to.x] = currentData.bin[from.y][from.x]
        currentData.bin[from.y][from.x] = .Masu
        return hasami(to)
    }
    
    func score(player: Player) -> Int {
        return currentData.score[player]!
    }

    func prevScore(player: Player, offset: Int) -> Int {
        return datas[datas.endIndex-offset].score[player]!
    }
}

extension ShougiModel : ShougiAlgorithmProtocol {
    func hasami(p: Point) -> Int {
        return 0
/*
        // ハサミの実装
        var count: Int = 0
        var ok : Bool = false
        for var i = y+1;i<9;i++ {
            if currentData.bin[i][x] == enemy() {
                ok = true
            } else {
                if currentData.bin[i][x] == currentData.turn {
                    if (ok) {
                        count += delete(y, fromX: x, toY: i, toX: x)
                    } else {
                        break
                    }
                }
                break
            }
        }
        ok = false
        for var i = y-1;i>=0;i-- {
            if currentData.bin[i][x] == enemy() {
                ok = true
            } else {
                if currentData.bin[i][x] == currentData.turn {
                    if (ok) {
                        count += delete(i, fromX: x, toY: y, toX: x)
                    } else {
                        break
                    }
                }
                break
            }
        }
        ok = false
        for var i = x+1;i<9;i++ {
            if currentData.bin[y][i] == enemy() {
                ok = true
            } else {
                if currentData.bin[y][i] == currentData.turn {
                    if (ok) {
                        count += delete(y, fromX: x, toY: y, toX: i)
                    } else {
                        break
                    }
                }
                break
            }
        }
        ok = false
        for var i = x-1;i>=0;i-- {
            if currentData.bin[y][i] == enemy() {
                ok = true
            } else {
                if currentData.bin[y][i] == currentData.turn {
                    if (ok) {
                        count += delete(y, fromX: i, toY: y, toX: x)
                    } else {
                        break
                    }
                }
                break
            }
        }
        return count
*/
    }
    
    func delete(fromY: Int, fromX:Int, toY: Int, toX: Int) -> Int {
        /*
        var count: Int = 0
        /* 冗長なので直す */
        if fromY < toY {
            for var i=fromY+1;i<toY;i++ {
                currentData.bin[i][fromX] = 0
                count++;
            }
        } else if toY < fromY {
            for var i=toY+1;i<fromY;i++ {
                currentData.bin[i][fromX] = 0
                count++;
            }
        } else if fromX < toX {
            for var i=fromX+1;i<toX;i++ {
                currentData.bin[fromY][i] = 0
                count++;
            }
        } else if toX < fromX {
            for var i=toX+1;i<fromX;i++ {
                currentData.bin[fromY][i] = 0
                count++;
            }
        }
        
        return count
*/
        return 0
    }

}