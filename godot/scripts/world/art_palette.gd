class_name ArtPalette
extends RefCounted

const JADE_WHITE := Color("e7e6d5")
const WARM_STONE := Color("c9c2a8")
const INK_TEAL := Color("234f52")
const QING_TEAL := Color("3c8d89")
const JADE_GLOW := Color("70d8c7")
const PALE_GOLD := Color("cfad63")
const BAMBOO := Color("477d58")
const BAMBOO_LIGHT := Color("7ea36a")
const LOTUS := Color("df91a9")
const WATER := Color("4f9ea5")
const SWORD_STONE := Color("71838e")
const EMBER_ROCK := Color("94533c")
const EMBER_GLOW := Color("ee7c43")
const ENEMY_SKIN := Color("5f7658")
const ENEMY_CLOTH := Color("3e3942")

static func material(color: Color, roughness := 0.78, metallic := 0.0, emission := Color.BLACK, emission_energy := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	if emission_energy > 0.0:
		result.emission_enabled = true
		result.emission = emission
		result.emission_energy_multiplier = emission_energy
	return result

static func transparent_material(color: Color, alpha: float, roughness := 0.55) -> StandardMaterial3D:
	var result := material(color, roughness)
	result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	result.albedo_color.a = alpha
	result.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return result

