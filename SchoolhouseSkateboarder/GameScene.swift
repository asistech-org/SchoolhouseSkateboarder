//
//  Created by Alexander Svalov on 24.09.2020.
//

import SpriteKit

// Структура содержит различные физические категории, и мы можем определить,
// какие типы объектов сталкиваются или контактируют друг с другом
struct PhysicsCategory {
    static let skater: UInt32 = 0x1 << 0  // Скейтер
    static let brick: UInt32 = 0x1 << 1   // Секция тротуара
    static let gem: UInt32 = 0x1 << 2     // Самоцвет
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Уровень секций по оси Y
    enum BrickLevel: CGFloat {
        case low = 0.0     // Секции на земле - низкие
        case high = 100.0  // Секции на верхней платформе - высокие
    }
    
    // Состояние игры
    enum GameState {
        case notRunning
        case running
    }
    
    // MARK:- Свойства класса
    
    // Массив, содержащий все текущие секции тротуара
    var bricks = [SKSpriteNode]()
    
    // Массив,содержащий все активные самоцветы
    var gems = [SKSpriteNode]()
    
    // Размер секций на тротуаре
    var brickSize = CGSize.zero
    
    // Текущий уровень определяет положение по оси Y для новых секций
    var brickLevel = BrickLevel.low
    
    // Отслеживаем текущее состояние игры
    var gameState = GameState.notRunning
    
    // Скорость движения тротуара вправо
    // Это значение может увеличиваться по мере продвижения пользователя в игре
    var scrollSpeed: CGFloat = 5.0
    let startingScrollSpeed: CGFloat = 5.0 // Начальная скорость
    
    // Константа для гравитации (того, как быстро объекты падают на Землю)
    let gravitySpeed: CGFloat = 1.5
    
    // Свойства для отслеживания результата
    var score: Int = 0
    var highScore: Int = 0
    var lastScoreUpdateTime: TimeInterval = 0.0
    
    // Время последнего вызова для метода обновления
    var lastUpdateTime: TimeInterval?
    
    // Создаем героя игры - скейтбордистку
    let skater = Skater(imageNamed: "skater")
    
    
    // MARK:- Подготовка игровой сцены
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
        
        // Начало системы координат сцены в левом нижнем углу: [0, 0]
        anchorPoint = CGPoint.zero
        
        // Создаем спрайт ФОН
        let background = SKSpriteNode(imageNamed: "background")

        // Координаты спрайта ФОН устанавливаются относительно его центра
        // Выставляем координаты спрайта относительно системы координат сцены
        let xMid = frame.midX  // X - центра сцены
        let yMid = frame.midY  // Y - центра сцены
        background.position = CGPoint(x: xMid, y: yMid)  // Кооринаты спрайта ФОН
        
        addChild(background)  // Добавляем фон на сцену
        
        setupLabels()  // Добавляем информационные надписи

        skater.setupPhysicsBody()  // Конфигурируем физическе тело скейтера
        addChild(skater)           // Добавляем скейтера на сцену
        
        // Добавляем детектор нажатия, чтобы знать, когда пользователь нажимает на экран
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        
        // Добавляем слой меню с текстом "Tap to play"
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint.zero // точка привязки спрайта
        menuLayer.position = CGPoint.zero    // координаты в родительской системе
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Tap to play", score: nil)
        addChild(menuLayer)
    }
    
    // Настраиваем стартовые свойства скейтера
    func resetSkater() {
        // Задаем начальное положение скейтера, zPosition и minimumY
        let skaterX = frame.midX / 2.0                     // X центра спрайта
        let skaterY = skater.frame.height / 2.0 + 64.0     // Y центра спрайта
        skater.position = CGPoint(x: skaterX, y: skaterY)  // Стартовая позиция спрайта
        skater.zPosition = 10      // Приоритет спрайта в совокупности спрайтов
        skater.minimumY = skaterY  // Уровень земли для спрайта (с учетом центра спрайта)
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    
    // Настройка надписей
    func setupLabels() {
        // Заголовок "очки" в верхнем левом углу
        let scoreTextLabel: SKLabelNode = SKLabelNode(text: "score")
        scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0)
        scoreTextLabel.horizontalAlignmentMode = .left  // Горизонтальное выравнивание
        scoreTextLabel.fontName = "Courier-Bold"
        scoreTextLabel.fontSize = 14.0
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel)
        
        // Количество очков игрока в текущей игре
        let scoreLabel: SKLabelNode = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 18.0
        scoreLabel.name = "scoreLabel"
        scoreLabel.zPosition = 20
        addChild(scoreLabel)
        
        // Заголовок "лучший результат" в правом верхнем углу
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "high score")
        highScoreTextLabel.position =
            CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"
        highScoreTextLabel.fontSize = 14.0
        highScoreTextLabel.zPosition = 20
        addChild(highScoreTextLabel)
        
        // Максимальное количество очков
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position =
            CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 18.0
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.zPosition = 20
        addChild(highScoreLabel)
    }
    
    func updateScoreLabelText() {
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel.text = String(format: "%04d", score)
        }
    }
    
    func updateHighScoreLabelText() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format: "%04d", highScore)
        }
    }
    
    func startGame() {
        // Возвращение к начальным условиям при запуске новой игры
        gameState = .running
        
        resetSkater()
        
        score = 0
        
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        lastUpdateTime = nil
        
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true) // keepingCapacity - сохраняя память

        for gem in gems {
            removeGem(gem)
        }
    }
    
    func gameOver() {
        // По завершении игры проверяем, добился ли игрок нового рекорда
        gameState = .notRunning
        
        if score > highScore {
            highScore = score
            
            updateHighScoreLabelText()
        }
        // Показываем надпись "Game Over!"
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint.zero
        menuLayer.position = CGPoint.zero
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Game Over!", score: score)
        addChild(menuLayer)
    }
    
    
    // MARK:- Порождающие и удаляющие методы
    
    // Порождаем секцию тротуара
    func spawnBrick(atPosition position: CGPoint) -> SKSpriteNode {

        // Создаем спрайт секции и добавляем его к сцене
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        
        // Обновляем свойство brickSize реальным значением размера секции
        brickSize = brick.size
        
        // Добавляем новую секцию к массиву
        bricks.append(brick)
        
        // Настройка физического тела секции
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false  // Влияние гравитации
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0 // Секция не будет отталкиваться от игрока
        
        // Возвращаем новую секцию вызывающему коду
        return brick
    }
    
    // Порождаем самоцвет
    func spawnGem(atPosition position: CGPoint) {
        
        // Создаем спрайт для самоцвета и добавляем его к сцене
        let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = position
        gem.zPosition = 9
        addChild(gem)
        
        // Настройка физического тела секции
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        
        // Добавляем новый самоцвет к массиву
        gems.append(gem)
    }
    
    // Удаляем самоцвет
    func removeGem(_ gem: SKSpriteNode) {
        gem.removeFromParent()
        
        if let gemIndex = gems.firstIndex(of: gem) {
            gems.remove(at: gemIndex)
        }
    }
    
    
    // MARK:- Обновляющие методы
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {

        // Отслеживаем самое большое значение по оси x для всех существующих секций
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            
            let newX = brick.position.x - currentScrollAmount
            
            // Если секция сместилась слишком далеко влево (за пределы экрана), удалите ее
            if newX < -brickSize.width {
                
                brick.removeFromParent()
                
                if let brickIndex = bricks.firstIndex(of: brick) {
                    bricks.remove(at: brickIndex)
                }
                
            } else {
                // Для секции, оставшейся на экране, обновляем положение
                brick.position = CGPoint(x: newX, y: brick.position.y)
                
                //Обновляем значение для крайней правой секции
                if brick.position.x > farthestRightBrickX {
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        
        // Цикл while, обеспечивающий постоянное наполнение экрана секциями
        while farthestRightBrickX < frame.width {
            
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = (brickSize.height / 2.0) + brickLevel.rawValue
            
            // Время от времени мы оставляем разрывы,
            // через которые герой должен перепрыгнуть
            let randomNumber = arc4random_uniform(99)

            if randomNumber < 2 && score > 10 {
                // 2-процентный шанс на то, что у нас возникнет разрыв между
                // секциями после того, как игрок набрал 10 призовых очков
                let gap = 20.0 * scrollSpeed
                brickX += gap
                
                // На каждом разрыве добавляем самоцвет
                let randomGemYAmount = CGFloat(arc4random_uniform(150))
                let newGemY = brickY + skater.size.height + randomGemYAmount
                let newGemX = brickX - gap / 2.0
                
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))

            } else if randomNumber < 4 && score > 20 { // 2 ..< 4
                // 2-процентный шанс на то, что уровень секции Y изменится
                // после того, как игрок набрал 20 призовых очков
                if brickLevel == .high {
                    brickLevel = .low
                } else if brickLevel == .low {
                    brickLevel = .high
                }
            }
            
            // Добавляем новую секцию и обновляем положение самой правой
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
        }
    }
    
    func updateGems(withScrollAmount currentScrollAmount: CGFloat) {
        
        for gem in gems {
            // Обновляем положение каждого самоцвета
            let thisGemX = gem.position.x - currentScrollAmount
            gem.position = CGPoint(x: thisGemX, y: gem.position.y)

            // Удаляем любые самоцветы, ушедшие с экрана
            if gem.position.x < 0.0 {
                removeGem(gem)
            }
        }
    }

    func updateSkater() {
        
        // Определяем, находится ли скейтбордистка на земле
        if let velocityY = skater.physicsBody?.velocity.dy {
            
            if velocityY < -100.0 || velocityY > 100.0 {
                skater.isOnGround = false
            }
        }
        
        // Проверка входа скейтера за пределами экрана
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0
        
        // Проверка опрокидывания скейтера
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        
        // Проверяем, должна ли игра закончиться
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
    
    func updateScore(withCurrentTime currentTime: TimeInterval) {

        // Количество очков игрока увеличивается по мере игры
        // Счет обновляется каждую секунду
        let elapsedTime = currentTime - lastScoreUpdateTime
        
        if elapsedTime > 1.0 {

            // Увеличиваем количество очков
            score += Int(scrollSpeed)
            
            // Присваиваем свойству lastScoreUpdateTime значение текущего времени
            lastScoreUpdateTime = currentTime
            
            updateScoreLabelText()
        }
    }
    
    
    // MARK:- Вызывается перед рендерингом каждого кадра
    //        Called before each frame is rendered
    
    override func update(_ currentTime: TimeInterval) {
        
        if gameState != .running {
            return
        }
        
        // Медленно увеличиваем значение scrollSpeed по мере развития игры
        scrollSpeed += 0.01
        
        // Определяем время, прошедшее с момента последнего вызова update
        var elapsedTime: TimeInterval = 0.0
        
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        
        lastUpdateTime = currentTime
        
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        
        // Рассчитываем, насколько далеко должны сдвинуться объекты при данном обновлении
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount = scrollSpeed * scrollAdjustment
        
        updateBricks(withScrollAmount: currentScrollAmount)
        updateSkater()
        updateGems(withScrollAmount: currentScrollAmount)
        updateScore(withCurrentTime: currentTime)
    }
    
    
    // MARK:- Обработка касания/клика экрана
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        
        if gameState == .running {
            // Скейтбордистка прыгает, если игрок нажимает на экран,
            // пока она находится на земле
            if skater.isOnGround {
                skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
                run(SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false))
            }
        } else {
            // Если игра не запущена, нажатие на экран запускает новую игру
            if let menuLayer: SKSpriteNode = childNode(withName: "menuLayer") as? SKSpriteNode {
                
                menuLayer.removeFromParent()
            }
            startGame()
        }
    }
    
    
    // MARK:- Реализация методов протокола SKPhysicsContactDelegate
    
    // Срабатывает при каждом контакте физических тел
    func didBegin(_ contact: SKPhysicsContact) {
        
        // Проверяем, есть ли контакт между скейтбордисткой и секцией
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater &&
            contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            
            if let velocityY = skater.physicsBody?.velocity.dy {
                if !skater.isOnGround && velocityY < 100.0 {
                    skater.createSparks()
                }
            }
            
            skater.isOnGround = true

        } else if contact.bodyA.categoryBitMask == PhysicsCategory.skater &&
                    contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            
            // Скейтбордистка коснулась самоцвета, поэтому мы его убираем
            if let gem = contact.bodyB.node as? SKSpriteNode {

                removeGem(gem)
                
                // Даем игроку 50 очков за собранный самоцвет
                score += 50
                updateScoreLabelText()
                
                run(SKAction.playSoundFileNamed("gem.wav", waitForCompletion: false))
            }
        }
    }
}
