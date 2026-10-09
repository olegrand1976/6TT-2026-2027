extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/grass.png")


func _ready() -> void:
	z_index = -30
	queue_redraw()


func _draw() -> void:
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	if tex == null:
		return
	# Même rectangle que l'ancien `track_view.gd` : centré sur la piste (0, 0).
	var half := Track.OUTER * 2.4
	var rect := Rect2(-half, half * 2.0)
	var col := Color.WHITE if use_track_default else surface_color
	TrackElement.draw_world_tiled_rect(self, tex, rect, col)
