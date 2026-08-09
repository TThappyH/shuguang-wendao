class_name RuntimePerformanceMonitor
extends Node

signal sustained_low_fps(sample: Dictionary)

const SAMPLE_INTERVAL := 0.5
const HISTORY_SIZE := 20
const LOW_FPS_THRESHOLD := 45.0
const LOW_FPS_SAMPLE_LIMIT := 5

var _clock := 0.0
var _low_fps_samples := 0
var _history: Array[Dictionary] = []
var _latest: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_clock += delta
	if _clock < SAMPLE_INTERVAL:
		return
	_clock = 0.0
	_latest = _capture()
	_history.append(_latest)
	while _history.size() > HISTORY_SIZE:
		_history.pop_front()
	if float(_latest.fps) < LOW_FPS_THRESHOLD:
		_low_fps_samples += 1
	else:
		_low_fps_samples = 0
	if _low_fps_samples == LOW_FPS_SAMPLE_LIMIT:
		sustained_low_fps.emit(_latest)

func snapshot() -> Dictionary:
	var average_fps := 0.0
	var peak_draw_calls := 0
	var peak_primitives := 0
	for sample: Dictionary in _history:
		average_fps += float(sample.fps)
		peak_draw_calls = maxi(peak_draw_calls, int(sample.draw_calls))
		peak_primitives = maxi(peak_primitives, int(sample.primitives))
	if not _history.is_empty():
		average_fps /= float(_history.size())
	var result := _latest.duplicate()
	result["average_fps_10s"] = average_fps
	result["peak_draw_calls_10s"] = peak_draw_calls
	result["peak_primitives_10s"] = peak_primitives
	result["sustained_low_fps"] = _low_fps_samples >= LOW_FPS_SAMPLE_LIMIT
	return result

func _capture() -> Dictionary:
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT))
	}
