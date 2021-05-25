Schoolhouse Skateboarder
=
Аркада: прыжки через препятствия и сбор алмазов.

### Выполнено по книге
Coding iPhone Apps for Kids: A Playful Introduction to Swift  
by Gloria Winquist and Matt McCarthy

### Описание
Для управления спрайтами в двумерном пространстве использован фреймворк SpriteKit.

Экземпляр SKView (наследник UIView) - представление, отображающее игровую сцену.

Экземпляр SKScene - сцена, на которой формируется игровая анимация.  
Сцена загружается из файла GameScene.sks и ссылается на класс GameScene.

Класс GameScene реализует протокол SKPhysicsContactDelegate и содержит:
- все свойства игры;
- методы, реализующие игровую механику;
- управление звуком.

Класс Skater (наследник SKSpriteNode) - спрайт, описывающий скейтбордиста:
- свойства скейтбордиста (скорость прыжка, уровень земли и др.);
- свойства физического тела (плотность, угловая амплитуда и др.);
- формирование искр для конкретного экземпляра класса.

Класс MenuLayer (наследник SKSpriteNode) - спрайт, описывающий игровое меню:
- в начале игры выводит сообщение "Tap to play";
- в конце игры выводит сообщение "Game Over!".

Искры формируются с помощью излучателя частиц (SpriteKit Particle Emitter),  
загружаемого из файла ресурсов sparks.sks

### Компоненты
SKView, SKScene, SKSpriteNode, SKLabelNode, SKPhysicsBody, SKAction, SKEmitterNode

Bundle.main, NSKeyedUnarchiver

CGSize, CGVector, CGPoint, CGFloat

UITapGestureRecognizer, UIColor
