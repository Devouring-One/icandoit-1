class_name Spell extends Resource

@export var name: String = "New Spell"
@export var mana_cost: float = 10.0
@export var spell_range: float = 300.0

enum SpellType {
	OFFENSIVE,
	DEFENSIVE,
	UTILITY
}

@export var type: SpellType = SpellType.OFFENSIVE
@export var area_of_effect: float = 0.0
@export var damage: float = 25.0
@export var duration: float = 0.0
@export var speed: float = 0.0
@export var cooldown: float = 1.0
@export var cast_time: float = 0.5
@export var description: String = "A powerful spell."
@export var spell_icon: Texture2D = null
@export var spell_scene: PackedScene = null