(local fennel (require "fennel"))
(table.insert package.loaders fennel.searcher) ; teach require how to fennel

(local ecs (require "ecs"))

(set add-position
     (fn [entity-id x y]
       (ecs.set-component entity-id :position {:x x
                                               :y y})))

(set add-circle
     (fn [entity-id d]
       (ecs.set-component entity-id :circle {:d d})))

(set add-rectangle
     (fn [entity-id w h]
       (ecs.set-component entity-id :rectangle {:w w
                                                :h h})))

(set add-momentum
     (fn [entity-id dx dy]
       (ecs.set-component entity-id :momentum {:dx dx
                                               :dy dy})))

(set add-color
     (fn [entity-id r g b]
       (ecs.set-component entity-id :color {:r r
                                            :g g
                                            :b b})))

(set add-controllable
     (fn [entity-id up-key down-key]
       (ecs.set-component entity-id :controllable {:up up-key
                                                   :down down-key})))

(set add-collidable
     (fn [entity-id w h]
       (ecs.set-component entity-id :collidable {:w w
                                                 :h h})))

(set add-ai
     (fn [entity-id]
       (ecs.set-component entity-id :ai {})))

(set remove-ai
     (fn [entity-id]
       (ecs.set-component entity-id :ai nil)))

(set love.load
     (fn []
       (set left-score 0)
       (set right-score 0)

       (set bounce-sound (love.audio.newSource "bounce.wav" "static"))
       (set rebound-sound (love.audio.newSource "rebound.wav" "static"))
       (set score-sound (love.audio.newSource "score.wav" "static"))

       (set ball-id (ecs.create-entity))
       (add-position ball-id 100 100)
       (add-color ball-id 255 255 255)
       (add-circle ball-id 10)
       (add-momentum ball-id 350 200)
       (add-collidable ball-id 10 10)

       (set left-paddle-id (ecs.create-entity))
       (add-position left-paddle-id 10 100)
       (add-color left-paddle-id 0 255 255)
       (add-rectangle left-paddle-id 10 100)
       (add-collidable left-paddle-id 10 100)
       (add-controllable left-paddle-id "a" "z")
       (add-ai left-paddle-id)

       (set right-paddle-id (ecs.create-entity))
       (add-position right-paddle-id (- (love.graphics.getWidth) 20) 100)
       (add-color right-paddle-id 255 0 255)
       (add-rectangle right-paddle-id 10 100)
       (add-controllable right-paddle-id "up" "down")
       (add-collidable right-paddle-id 10 100)

       (ecs.create-system :momentum [:momentum :position]
                          (fn [dt entities]
                            (each [i entity-id (ipairs entities)]
                              (let [x (. (. ecs.components.position entity-id) :x)
                                    y (. (. ecs.components.position entity-id) :y)
                                    dx (. (. ecs.components.momentum entity-id) :dx)
                                    dy (. (. ecs.components.momentum entity-id) :dy)]
                                (tset (. ecs.components.position entity-id) :x (+ x (* dx dt)))
                                (tset (. ecs.components.position entity-id) :y (+ y (* dy dt)))))))

       (ecs.create-system :input [:controllable :position]
                          (fn [dt entities]
                            (each [i entity-id (ipairs entities)]
                              (when (love.keyboard.isDown (. (. ecs.components.controllable entity-id) :up))
                                (let [y (. (. ecs.components.position entity-id) :y)]
                                  (tset (. ecs.components.position entity-id) :y (- y (* 300 dt)))))
                              (when (love.keyboard.isDown (. (. ecs.components.controllable entity-id) :down))
                                (let [y (. (. ecs.components.position entity-id) :y)]
                                  (tset (. ecs.components.position entity-id) :y (+ y (* 300 dt))))))))

       (ecs.create-system :ball-collision [:collidable :position :circle :momentum]
                          (fn [dt entities]
                            (each [i entity-id (ipairs entities)]
                              (let [collidable-w (. (. ecs.components.collidable entity-id) :w)
                                    collidable-h (. (. ecs.components.collidable entity-id) :h)
                                    x (. (. ecs.components.position entity-id) :x)
                                    y (. (. ecs.components.position entity-id) :y)
                                    dx (. (. ecs.components.momentum entity-id) :dx)
                                    dy (. (. ecs.components.momentum entity-id) :dy)]
                                (when (< y collidable-h)
                                  (love.audio.play rebound-sound)
                                  (tset (. ecs.components.position entity-id) :y collidable-h)
                                  (tset (. ecs.components.momentum entity-id) :dy (- dy)))
                                (when (>= y (- (love.graphics.getHeight) collidable-h))
                                  (love.audio.play rebound-sound)
                                  (tset (. ecs.components.position entity-id) :y (- (love.graphics.getHeight) collidable-h))
                                  (tset (. ecs.components.momentum entity-id) :dy (- dy)))
                                (let [left-paddle-y (. (. ecs.components.position left-paddle-id) :y)
                                      left-paddle-x (. (. ecs.components.position left-paddle-id) :x)
                                      left-paddle-collision-w (. (. ecs.components.collidable left-paddle-id) :w)
                                      left-paddle-collision-h (. (. ecs.components.collidable left-paddle-id) :h)]
                                  (when (and (< x (+ left-paddle-x left-paddle-collision-w))
                                             (> y left-paddle-y)
                                             (< y (+ left-paddle-y left-paddle-collision-h)))
                                    (love.audio.play bounce-sound)
                                    (tset (. ecs.components.position entity-id) :x (+ left-paddle-x left-paddle-collision-w))
                                    (tset (. ecs.components.momentum entity-id) :dx (- dx))))
                                (let [right-paddle-y (. (. ecs.components.position right-paddle-id) :y)
                                      right-paddle-x (. (. ecs.components.position right-paddle-id) :x)
                                      right-paddle-collision-w (. (. ecs.components.collidable right-paddle-id) :w)
                                      right-paddle-collision-h (. (. ecs.components.collidable right-paddle-id) :h)]
                                  (when (and (> x (- right-paddle-x right-paddle-collision-w))
                                             (> y right-paddle-y)
                                             (< y (+ right-paddle-y right-paddle-collision-h)))
                                    (love.audio.play bounce-sound)
                                    (tset (. ecs.components.position entity-id) :x (- right-paddle-x right-paddle-collision-w))
                                    (tset (. ecs.components.momentum entity-id) :dx (- dx))))))))

       (ecs.create-system :paddle-collision [:collidable :position :rectangle]
                          (fn [dt entities]
                            (each [i entity-id (ipairs entities)]
                              (let [collidable-w (. (. ecs.components.collidable entity-id) :w)
                                    collidable-h (. (. ecs.components.collidable entity-id) :h)
                                    x (. (. ecs.components.position entity-id) :x)
                                    y (. (. ecs.components.position entity-id) :y)]
                                (when (< y 0)
                                  (tset (. ecs.components.position entity-id) :y 0))
                                (when (>= y (- (love.graphics.getHeight) collidable-h))
                                  (tset (. ecs.components.position entity-id) :y (- (love.graphics.getHeight) collidable-h)))))))

       (ecs.create-system :ai [:ai :position :collidable]
                          (fn [dt entities]
                            (each [i entity-id (ipairs entities)]
                              (let [collidable-h (. (. ecs.components.collidable entity-id) :h)
                                    y (. (. ecs.components.position entity-id) :y)
                                    ball-y (. (. ecs.components.position ball-id) :y)]
                                (tset (. ecs.components.position entity-id) :y (- ball-y (/ collidable-h 2)))))))

       (ecs.create-system :scoring [:collidable :position :circle :momentum]
                          (fn [dt entities]
                            (each [i entity-id (ipairs entities)]
                              (let [x (. (. ecs.components.position entity-id) :x)
                                    collidable-w (. (. ecs.components.collidable entity-id) :w)
                                    left-paddle-x (. (. ecs.components.position left-paddle-id) :x)
                                    right-paddle-x (. (. ecs.components.position right-paddle-id) :x)
                                    right-paddle-collision-w (. (. ecs.components.collidable right-paddle-id) :w)]
                                (when (> (+ x collidable-w) (+ right-paddle-x right-paddle-collision-w))
                                  (love.audio.play score-sound)
                                  (set left-score (+ 1 left-score))
                                  (tset (. ecs.components.position entity-id) :x 100))
                                (when (< x left-paddle-x)
                                  (love.audio.play score-sound)
                                  (set right-score (+ 1 right-score))
                                  (tset (. ecs.components.position entity-id) :x 100)
                                  (tset (. ecs.components.momentum entity-id) :dx 350))))))))

(set love.update
     (fn [dt]
       (ecs.run-systems dt)))

(set love.keypressed
     (fn [key]
       (when (= key "h")
         (if (. (. ecs.mask left-paddle-id) :ai)
           (remove-ai left-paddle-id)
           (add-ai left-paddle-id)))))

(set render-circles
     (fn []
       (let [entities (ecs.find-entities [:circle :position :color])]
         (when (and entities (> (# entities) 0))
           (each [i entity (ipairs entities)]
             (love.graphics.setColor (. (. ecs.components.color entity) :r)
                                     (. (. ecs.components.color entity) :g)
                                     (. (. ecs.components.color entity) :b))
             (love.graphics.circle "fill"
                                   (. (. ecs.components.position entity) :x)
                                   (. (. ecs.components.position entity) :y)
                                   (. (. ecs.components.circle entity) :d)))))))

(set render-rectangles
     (fn []
       (let [entities (ecs.find-entities [:rectangle :position :color])]
         (when (and entities (> (# entities) 0))
           (each [i entity (ipairs entities)]
             (love.graphics.setColor (. (. ecs.components.color entity) :r)
                                     (. (. ecs.components.color entity) :g)
                                     (. (. ecs.components.color entity) :b))
             (love.graphics.rectangle "fill"
                                      (. (. ecs.components.position entity) :x)
                                      (. (. ecs.components.position entity) :y)
                                      (. (. ecs.components.rectangle entity) :w)
                                      (. (. ecs.components.rectangle entity) :h)))))))

(set render-scores
     (fn []
       (love.graphics.setColor 255 0 0)
       (love.graphics.print left-score 0 0 0 3)
       (love.graphics.print right-score (- (love.graphics.getWidth) 22) 0 0 3)))

(set love.draw
     (fn []
       (render-circles)
       (render-rectangles)
       (render-scores)))
