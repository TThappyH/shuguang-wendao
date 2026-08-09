class_name WorldConfig
extends RefCounted

const PLAYER_RADIUS := 0.42
const WORLD_LIMIT := 43.0
const EXTERNAL_MAP_ENABLED := true
const EXTERNAL_MAP_RADIUS := 36.5

const REGIONS := {
	"ruins": {"name": "晨曦遗庭", "short": "庭", "center": Vector2(0, 0), "size": Vector2(22, 22), "floor": Color("b8c9be"), "accent": Color("66cbbc")},
	"bamboo": {"name": "碧篁剑林", "short": "篁", "center": Vector2(28, 0), "size": Vector2(26, 28), "floor": Color("91b59b"), "accent": Color("4ea879")},
	"marsh": {"name": "青莲灵泽", "short": "莲", "center": Vector2(-28, 0), "size": Vector2(26, 28), "floor": Color("8cb7b2"), "accent": Color("5fc5bd")},
	"sword": {"name": "问剑古冢", "short": "剑", "center": Vector2(0, -28), "size": Vector2(28, 26), "floor": Color("9faeb9"), "accent": Color("8baed0")},
	"ember": {"name": "丹霞裂谷", "short": "丹", "center": Vector2(0, 28), "size": Vector2(28, 26), "floor": Color("bd9678"), "accent": Color("e57d48")}
}

const LINKS := [
	{"id": "ruins-bamboo", "center": Vector2(13, 0), "size": Vector2(8, 8)},
	{"id": "ruins-marsh", "center": Vector2(-13, 0), "size": Vector2(8, 8)},
	{"id": "ruins-sword", "center": Vector2(0, -13), "size": Vector2(8, 8)},
	{"id": "ruins-ember", "center": Vector2(0, 13), "size": Vector2(8, 8)}
]

const BLOCKERS := [
	{"id":"center-nw", "region":"ruins", "p":Vector2(-7,-7), "s":Vector2(2.4,2.4), "h":1.1, "kind":"plinth"},
	{"id":"center-ne", "region":"ruins", "p":Vector2(7,-7), "s":Vector2(2.4,2.4), "h":1.1, "kind":"plinth"},
	{"id":"center-sw", "region":"ruins", "p":Vector2(-7,7), "s":Vector2(2.4,2.4), "h":1.1, "kind":"plinth"},
	{"id":"center-se", "region":"ruins", "p":Vector2(7,7), "s":Vector2(2.4,2.4), "h":1.1, "kind":"plinth"},
	{"id":"bamboo-p1", "region":"bamboo", "p":Vector2(22,-8), "s":Vector2(1.2,5.0), "h":3.8, "kind":"pillar"},
	{"id":"bamboo-p2", "region":"bamboo", "p":Vector2(28,4), "s":Vector2(1.2,5.0), "h":4.8, "kind":"pillar"},
	{"id":"bamboo-p3", "region":"bamboo", "p":Vector2(34,8), "s":Vector2(1.2,5.0), "h":4.2, "kind":"pillar"},
	{"id":"bamboo-p4", "region":"bamboo", "p":Vector2(35,-8), "s":Vector2(1.2,4.2), "h":3.4, "kind":"pillar"},
	{"id":"bamboo-p5", "region":"bamboo", "p":Vector2(22,8), "s":Vector2(1.2,4.2), "h":3.4, "kind":"pillar"},
	{"id":"marsh-i1", "region":"marsh", "p":Vector2(-23,-7), "s":Vector2(4.2,3.2), "h":0.72, "kind":"island"},
	{"id":"marsh-i2", "region":"marsh", "p":Vector2(-31,0), "s":Vector2(4.6,3.4), "h":0.92, "kind":"island"},
	{"id":"marsh-i3", "region":"marsh", "p":Vector2(-23,8), "s":Vector2(3.8,3.2), "h":0.66, "kind":"island"},
	{"id":"marsh-i4", "region":"marsh", "p":Vector2(-37,-8), "s":Vector2(3.2,3.0), "h":0.62, "kind":"island"},
	{"id":"sword-s1", "region":"sword", "p":Vector2(-8,-24), "s":Vector2(1.0,3.6), "h":2.7, "kind":"stele"},
	{"id":"sword-s2", "region":"sword", "p":Vector2(0,-33), "s":Vector2(1.0,4.0), "h":3.4, "kind":"stele"},
	{"id":"sword-s3", "region":"sword", "p":Vector2(8,-24), "s":Vector2(1.0,3.6), "h":2.7, "kind":"stele"},
	{"id":"sword-s4", "region":"sword", "p":Vector2(-8,-36), "s":Vector2(1.0,3.0), "h":2.3, "kind":"stele"},
	{"id":"sword-s5", "region":"sword", "p":Vector2(8,-36), "s":Vector2(1.0,3.0), "h":2.3, "kind":"stele"},
	{"id":"ember-w1", "region":"ember", "p":Vector2(-8,23), "s":Vector2(7.0,1.4), "h":2.8, "kind":"canyon"},
	{"id":"ember-w2", "region":"ember", "p":Vector2(6,29), "s":Vector2(8.0,1.4), "h":3.4, "kind":"canyon"},
	{"id":"ember-w3", "region":"ember", "p":Vector2(-6,36), "s":Vector2(8.0,1.4), "h":3.0, "kind":"canyon"}
]

static func region_for_position(world_position: Vector3) -> String:
	var point := Vector2(world_position.x, world_position.z)
	for id: String in REGIONS:
		var region: Dictionary = REGIONS[id]
		if _point_in_rect(point, region.center, region.size, 0.0):
			return id
	if absf(point.x) > absf(point.y):
		return "bamboo" if point.x > 0.0 else "marsh"
	return "ember" if point.y > 0.0 else "sword"

static func is_walkable(world_position: Vector3, radius: float = PLAYER_RADIUS) -> bool:
	var point := Vector2(world_position.x, world_position.z)
	for id: String in REGIONS:
		var region: Dictionary = REGIONS[id]
		if _point_in_rect(point, region.center, region.size, radius):
			return not _hits_blocker(point, radius)
	for link: Dictionary in LINKS:
		if _point_in_rect(point, link.center, link.size, radius):
			return not _hits_blocker(point, radius)
	return false

static func navigation_target(from_position: Vector3, to_position: Vector3) -> Vector3:
	var from_region := region_for_position(from_position)
	var to_region := region_for_position(to_position)
	if from_region == to_region:
		return to_position
	var gates := {
		"bamboo": {"inner":Vector3(10,0,0), "outer":Vector3(17,0,0)},
		"marsh": {"inner":Vector3(-10,0,0), "outer":Vector3(-17,0,0)},
		"sword": {"inner":Vector3(0,0,-10), "outer":Vector3(0,0,-17)},
		"ember": {"inner":Vector3(0,0,10), "outer":Vector3(0,0,17)}
	}
	if from_region != "ruins":
		return gates[from_region].inner
	if to_region != "ruins":
		return gates[to_region].outer
	return to_position

static func _point_in_rect(point: Vector2, center: Vector2, size: Vector2, margin: float) -> bool:
	return absf(point.x - center.x) <= size.x * 0.5 - margin and absf(point.y - center.y) <= size.y * 0.5 - margin

static func _hits_blocker(point: Vector2, radius: float) -> bool:
	for blocker: Dictionary in BLOCKERS:
		if _point_in_rect(point, blocker.p, blocker.s + Vector2.ONE * radius * 2.0, 0.0):
			return true
	return false
