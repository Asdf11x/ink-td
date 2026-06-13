class_name TimeFormatter
extends RefCounted


static func format_duration(seconds: float) -> String:
	var total: int = maxi(0, int(floor(seconds)))
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	var secs: int = total % 60

	var parts: PackedStringArray = []
	if hours > 0:
		parts.append("%d h" % hours)
	if minutes > 0 or hours > 0:
		parts.append("%d min" % minutes)
	parts.append("%d sec" % secs)
	return " ".join(parts)
