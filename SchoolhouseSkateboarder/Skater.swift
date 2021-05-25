//
//  Created by Alexander Svalov on 25.09.2020.
//

import SpriteKit

class Skater: SKSpriteNode {

    var velocity = CGPoint.zero     // Скорость по оси X и по оси Y
    var minimumY: CGFloat = 0.0     // Уровень земли
    var jumpSpeed: CGFloat = 20.0   // Скорость прыжка
    var isOnGround = true           // Игрок на земле (может прыгать)
    
    func setupPhysicsBody() {
        
        if let skaterTexture = texture {
            
            physicsBody = SKPhysicsBody(texture: skaterTexture, size: size)
            physicsBody?.isDynamic = true  // Передаем управление движением физ. движку
            physicsBody?.density = 6.0     // Плотность
            physicsBody?.allowsRotation = false
            physicsBody?.angularDamping = 1.0  // Угловая амплитуда
            
            physicsBody?.categoryBitMask = PhysicsCategory.skater
            physicsBody?.collisionBitMask = PhysicsCategory.brick
            physicsBody?.contactTestBitMask = PhysicsCategory.brick | PhysicsCategory.gem
        }
    }
    
    func createSparks() {

        // Находим файл эмиттера искр в проекте
        let bundle = Bundle.main
        
        if let sparksPath = bundle.path(forResource: "sparks", ofType: "sks") {
            
            // Создаем узел эмиттера искр
            let sparksNode = NSKeyedUnarchiver.unarchiveObject(withFile: sparksPath) as! SKEmitterNode
            sparksNode.position = CGPoint(x: 0.0, y: -50.0)
            addChild(sparksNode)
            
            // Производим действие, ждем полсекунды, а затем удаляем эмиттер
            let waitAction = SKAction.wait(forDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            let waitThenRemove = SKAction.sequence([waitAction, removeAction])
            
            sparksNode.run(waitThenRemove)
        }
    }
}
