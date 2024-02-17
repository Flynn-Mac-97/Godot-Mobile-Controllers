# TickManager.gd
extends Node

# Define the tick rate (ticks per second)
var tick_rate: float = 60
# Calculate the time per tick
var time_per_tick: float = 1.0 / tick_rate
# Keep track of the accumulated time
var time_accumulator: float = 0.0

# Signal to be emitted every tick
signal tick

func _process(delta: float) -> void:
	time_accumulator += delta
	while time_accumulator >= time_per_tick:
		time_accumulator -= time_per_tick
		emit_signal("tick")
