(local ecs {"entity-max" 0
            "mask" {}
            "components" {}
            "systems" {}})

;; {:mask {0 {:health true
;;            :position true}
;;         1 {:color true}}}

;; {:components {:health [{:hp 100}
;;                        {:hp 30}
;;                        nil
;;                        nil
;;                        {:hp 500}]
;;               :position [nil
;;                          nil
;;                          {:x 100
;;                           :y 300}
;;                          nil]}}

;; {:system {:printer {:components [:health :position]
;;                     :func (fn [dt entities])}
;;           :beeper {:components [:beep]
;;                    :func (fn [dt entities])}}}

(set ecs.create-entity
     (fn []
       (let [id ecs.entity-max]
         (set ecs.entity-max (+ id 1))
         (tset ecs.mask id {})
         id)))

(set ecs.set-component
     (fn [entity-id name data]
       (let [component (. ecs.components name)]
         (tset (. ecs.mask entity-id) name (and data true))
         (if component
           (tset component entity-id data)
           (tset ecs.components name {entity-id data})))))

(set ecs.delete-entity
     (fn [entity-id]
       (tset ecs.mask entity-id nil)
       (each [component array-of-data (pairs ecs.components)]
         (tset array-of-data entity-id nil))))

(set ecs.create-system
     (fn [name components func]
       (tset ecs.systems name {:components components
                               :func func})))

(set ecs.find-entities
     (fn [desired-components]
       (let [entities []]
         (each [entity mask (pairs ecs.mask)]
           (let [found 0]
             (each [i component (ipairs desired-components)]
               (when (. mask component)
                 (set found (+ found 1))))
             (when (= found (# desired-components))
               (tset entities (+ (# entities) 1) entity))))
         entities)))

(set ecs.run-systems
     (fn [dt]
       (each [system-name system (pairs ecs.systems)]
         (let [entities (ecs.find-entities system.components)]
           (when (and entities (> (# entities) 0))
             (system.func dt entities))))))

ecs
