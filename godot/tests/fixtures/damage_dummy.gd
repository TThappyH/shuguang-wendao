class_name DamageDummy
extends Node3D

var hp := 100.0
var hit_count := 0

func _ready() -> void:
	add_to_group("enemies")

func take_damage(amount: float, _direction := Vector3.ZERO) -> void:
	hp -= amount
	hit_count += 1
