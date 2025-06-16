extends Node

var file := FileAccess.open("user://analytics_log.csv", FileAccess.WRITE_READ)

func _ready():
	if file:
		file.seek_end()  # Continue from last log if present
		file.store_line("event,time,data")  # Header only if needed

func log_event(event: String, data: Dictionary):
	var time = Time.get_ticks_msec()
	var line = "%s,%d,%s" % [event, time, JSON.stringify(data)]
	file.store_line(line)
	file.flush()  # Save immediately
