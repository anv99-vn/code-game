class_name YAMLParser


static func load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("YAMLParser: Cannot open file: %s" % path)
		return {}
	var content := file.get_as_text()
	file.close()
	return parse(content)


static func parse(content: String) -> Dictionary:
	var result := {}
	var current_section := ""
	var lines := content.split("\n")
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			continue
		var indent := line.length() - line.lstrip(" ").length()
		if indent == 0 and stripped.ends_with(":"):
			current_section = stripped.substr(0, stripped.length() - 1)
			result[current_section] = {}
		elif indent > 0 and current_section != "" and stripped.contains(":"):
			var parts := stripped.split(":", true, 1)
			if parts.size() == 2:
				var key := parts[0].strip_edges()
				var value_str := parts[1].strip_edges()
				result[current_section][key] = _parse_value(value_str)
	return result


static func _parse_value(s: String) -> Variant:
	if s == "true":
		return true
	if s == "false":
		return false
	if s == "null":
		return null
	if s.begins_with('"') and s.ends_with('"'):
		return s.substr(1, s.length() - 2)
	if s.begins_with("'") and s.ends_with("'"):
		return s.substr(1, s.length() - 2)
	if s.is_valid_int():
		return s.to_int()
	if s.is_valid_float():
		return s.to_float()
	return s
