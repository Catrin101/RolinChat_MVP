extends Node

## Utility to load images from local files or web URLs.

func load_image(url: String, callback: Callable) -> void:
	if url.begins_with("http"):
		_load_from_web(url, callback)
	else:
		_load_from_local(url, callback)

func _load_from_local(path: String, callback: Callable) -> void:
	var actual_path = path
	if path.begins_with("res://") or path.begins_with("user://"):
		pass # Godot paths are handled directly
	
	if not FileAccess.file_exists(actual_path):
		printerr("[ImageLoader] Local file not found: ", actual_path)
		callback.call(null)
		return
	
	var image = Image.load_from_file(actual_path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		callback.call(texture)
	else:
		printerr("[ImageLoader] Failed to load local image: ", actual_path)
		callback.call(null)

func _load_from_web(url: String, callback: Callable) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(func(result, response_code, headers, body):
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			printerr("[ImageLoader] Web request failed for: ", url)
			callback.call(null)
		else:
			var image = Image.new()
			var error = OK
			
			if url.ends_with(".png"):
				error = image.load_png_from_buffer(body)
			elif url.ends_with(".jpg") or url.ends_with(".jpeg"):
				error = image.load_jpg_from_buffer(body)
			elif url.ends_with(".webp"):
				error = image.load_webp_from_buffer(body)
			else:
				# Try to detect format if no extension
				error = image.load_png_from_buffer(body)
				if error != OK: error = image.load_jpg_from_buffer(body)
				if error != OK: error = image.load_webp_from_buffer(body)
			
			if error == OK:
				var texture = ImageTexture.create_from_image(image)
				callback.call(texture)
			else:
				printerr("[ImageLoader] Failed to parse web image: ", url)
				callback.call(null)
		
		http_request.queue_free()
	)
	
	var error = http_request.request(url)
	if error != OK:
		printerr("[ImageLoader] Error starting web request: ", error)
		callback.call(null)
		http_request.queue_free()
