extends Node
class_name UUID_Utils

## Helper utility to generate UUIDs (needed for Avatar IDs).


static func v4() -> String:
	# Simple pseudo-UUID v4 implementation for Godot
	var b = []
	for i in range(16):
		b.append(randi() % 256)
	
	# Set version to 4
	b[6] = (b[6] & 0x0f) | 0x40
	# Set variant to 10xx
	b[8] = (b[8] & 0x3f) | 0x80
	
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		b[0], b[1], b[2], b[3],
		b[4], b[5],
		b[6], b[7],
		b[8], b[9],
		b[10], b[11], b[12], b[13], b[14], b[15]
	]
