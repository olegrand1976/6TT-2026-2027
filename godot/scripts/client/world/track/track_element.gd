## Élément de piste — **un script pour tous les matériaux** (pédagogie).
##
## Chaque scène `track/elements/*.tscn` :
##   1. Attache ce script sur la racine.
##   2. Choisit `kind` dans l'inspecteur (herbe, ellipse, bordures…).
##   3. Place les nœuds enfants attendus (`Polygon2D`, `Line2D`, `Sprite2D`, `Collision/`).
##
## Exemple : `asphalt.tscn` → kind=ELLIPSE_SURFACE, enfant Polygon2D, texture bitume.
## Le serveur **ne lit pas** ce script : il scanne les `TrackCollisionMarker` dans l'arbre.
##
## `_set` : permet de voir le changement de texture/couleur dans l'éditeur sans relancer.
class_name TrackElement
extends Node2D

enum Kind {
	GRASS,
	ELLIPSE_SURFACE,
	CURBS,
	START_LINE,
	SPRITE_DECOR,
	WALL_SEGMENT,
}

enum EllipseKind {
	AUTO,
	ASPHALT,
	DIRT,
}

const TEX_GRASS := preload("res://assets/track/grass.png")
const TEX_ASPHALT := preload("res://assets/track/asphalt.png")
const TEX_DIRT := preload("res://assets/track/dirt.png")
const TEX_KERB := preload("res://assets/track/kerb.png")
const TEX_START := preload("res://assets/track/start_line.png")
const TEX_WALL := preload("res://assets/track/wall.png")
const TEX_TREE := preload("res://assets/track/tree.png")
const TEX_ROCK := preload("res://assets/track/rock.png")

@export var kind: Kind = Kind.GRASS
@export var render_layer: int = 0
@export var surface_texture: Texture2D
@export var surface_color: Color = Color.WHITE
@export var use_track_default := true

@export_group("Ellipse (bitume / terre)")
@export var ellipse_kind: EllipseKind = EllipseKind.AUTO
@export var ellipse_radii: Vector2 = Track.OUTER

@export_group("Sprite / mur")
@export var scale_factor := 1.0
@export var length := 80.0
@export var thickness := 6.0
@export var sprite_feet_on_ground := false


func _ready() -> void:
	z_index = render_layer
	_apply_visual()
	if kind == Kind.GRASS:
		queue_redraw()


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"surface_texture":
			surface_texture = value as Texture2D
			_on_surface_exports_changed()
			return true
		&"surface_color":
			surface_color = value as Color
			_on_surface_exports_changed()
			return true
		&"use_track_default":
			use_track_default = value as bool
			_on_surface_exports_changed()
			return true
		&"kind":
			kind = value as Kind
			_on_surface_exports_changed()
			return true
		&"ellipse_radii":
			ellipse_radii = value as Vector2
			_on_surface_exports_changed()
			return true
		&"ellipse_kind":
			ellipse_kind = value as EllipseKind
			_on_surface_exports_changed()
			return true
		&"render_layer":
			render_layer = value as int
			z_index = render_layer
			_on_surface_exports_changed()
			return true
		&"sprite_feet_on_ground":
			sprite_feet_on_ground = value as bool
			_on_surface_exports_changed()
			return true
		&"scale_factor", &"length", &"thickness":
			if property == &"scale_factor":
				scale_factor = value as float
			elif property == &"length":
				length = value as float
			else:
				thickness = value as float
			_on_surface_exports_changed()
			return true
	return false


func _on_surface_exports_changed() -> void:
	_apply_visual()
	queue_redraw()


func _draw() -> void:
	if kind != Kind.GRASS:
		return
	var tex := _resolved_texture(TEX_GRASS)
	if tex == null:
		return
	var half := Track.OUTER * 2.4
	var rect := Rect2(-half, half * 2.0)
	var col := Color.WHITE if use_track_default else surface_color
	draw_world_tiled_rect(self, tex, rect, col)


func _apply_visual() -> void:
	match kind:
		Kind.GRASS:
			pass
		Kind.ELLIPSE_SURFACE:
			_apply_ellipse_surface()
		Kind.CURBS:
			_apply_curbs()
		Kind.START_LINE:
			_apply_start_line()
		Kind.SPRITE_DECOR:
			_apply_sprite_decor()
		Kind.WALL_SEGMENT:
			_apply_wall_segment()
		_:
			assert(false, "TrackElement.Kind inconnu : %d" % int(kind))


func _apply_ellipse_surface() -> void:
	var poly := get_node_or_null("Polygon2D") as Polygon2D
	if poly == null:
		return
	var kind_resolved := ellipse_kind
	if kind_resolved == EllipseKind.AUTO:
		kind_resolved = (
			EllipseKind.ASPHALT if ellipse_radii.x > Track.INNER.x else EllipseKind.DIRT
		)
	var fallback := TEX_ASPHALT if kind_resolved == EllipseKind.ASPHALT else TEX_DIRT
	var tex := _resolved_texture(fallback)
	bind_ellipse_polygon(poly, tex, ellipse_radii)
	var palette := Track.ASPHALT if kind_resolved == EllipseKind.ASPHALT else Track.DIRT
	apply_modulate(poly, palette)


func _apply_curbs() -> void:
	var outer := get_node_or_null("OuterKerb") as Line2D
	var inner := get_node_or_null("InnerKerb") as Line2D
	if outer == null or inner == null:
		return
	var tex := _resolved_texture(TEX_KERB)
	var start_angle := _kerb_start_angle(outer, tex, Track.OUTER)
	var outer_pts := Track.ellipse_points(Track.OUTER, 96, start_angle)
	var inner_pts := Track.ellipse_points(Track.INNER, 96, start_angle)
	for line in [outer, inner]:
		line.texture = tex
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.width = 8.0
		line.closed = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		apply_modulate(line, Track.KERB)
	outer.points = outer_pts
	inner.points = inner_pts


## Décale le début de l'ellipse pour rapprocher la phase du carrelage kerb de la grille monde.
static func _kerb_start_angle(line: Line2D, tex: Texture2D, radii: Vector2) -> float:
	if tex == null:
		return 0.0
	var tile := texture_size(tex)
	if tile.x <= 0.0:
		return 0.0
	var anchor := line.to_global(Vector2(radii.x, 0.0))
	var phase_px := fmod(anchor.x, tile.x)
	if phase_px < 0.0:
		phase_px += tile.x
	var avg_r := (radii.x + radii.y) * 0.5
	if avg_r <= 0.0:
		return 0.0
	return phase_px / avg_r


func _apply_start_line() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var tex := _resolved_texture(TEX_START)
	spr.texture = tex
	spr.centered = true
	var width := Track.OUTER.x - Track.INNER.x
	var size := texture_size(tex)
	const LINE_WIDTH := 4.0
	spr.scale = Vector2(width / size.x, LINE_WIDTH / size.y)
	spr.position = Vector2((Track.INNER.x + Track.OUTER.x) * 0.5, 0.0)
	apply_modulate(spr, Color.WHITE)


func _apply_sprite_decor() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var fallback := TEX_TREE if sprite_feet_on_ground else TEX_ROCK
	var tex := _resolved_texture(fallback)
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2.ONE * scale_factor
	if sprite_feet_on_ground:
		var size := texture_size(tex)
		spr.offset = Vector2(0.0, -size.y * 0.5)
	else:
		spr.offset = Vector2.ZERO
	var palette := Track.TREE_CROWN if sprite_feet_on_ground else Track.ROCK
	apply_modulate(spr, palette)


func _apply_wall_segment() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var tex := _resolved_texture(TEX_WALL)
	spr.centered = true
	spr.texture = tex
	var size := texture_size(tex)
	spr.scale = Vector2(length / size.x, thickness / size.y)
	apply_modulate(spr, Track.WALL)


func _resolved_texture(fallback: Texture2D) -> Texture2D:
	if surface_texture != null:
		return surface_texture
	return fallback


func apply_modulate(target: CanvasItem, _palette_default: Color) -> void:
	if use_track_default:
		target.modulate = Color.WHITE
	else:
		target.modulate = surface_color


static func texture_size(tex: Texture2D) -> Vector2:
	var size: Vector2i = tex.get_size()
	return Vector2(float(size.x), float(size.y))


static func world_tile_uvs(points: PackedVector2Array, tile: Vector2) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for p in points:
		uvs.push_back(Vector2(p.x / tile.x, p.y / tile.y))
	return uvs


## Carrelage aligné sur l'origine monde (0,0) — même phase que les UV des ellipses.
static func draw_world_tiled_rect(
	canvas: CanvasItem, tex: Texture2D, rect: Rect2, modulate: Color = Color.WHITE
) -> void:
	var tile := texture_size(tex)
	if tile.x <= 0.0 or tile.y <= 0.0:
		return
	var x0 := int(floor(rect.position.x / tile.x))
	var y0 := int(floor(rect.position.y / tile.y))
	var x1 := int(ceil(rect.end.x / tile.x))
	var y1 := int(ceil(rect.end.y / tile.y))
	for ix in range(x0, x1):
		for iy in range(y0, y1):
			var dest := Rect2(float(ix) * tile.x, float(iy) * tile.y, tile.x, tile.y)
			var clip := rect.intersection(dest)
			if clip.size.x <= 0.0 or clip.size.y <= 0.0:
				continue
			var src := Rect2(clip.position - dest.position, clip.size)
			canvas.draw_texture_rect_region(tex, clip, src, modulate)


static func bind_ellipse_polygon(poly: Polygon2D, tex: Texture2D, radii: Vector2) -> void:
	var points := Track.ellipse_points(radii)
	poly.polygon = points
	if tex == null:
		poly.texture = null
		poly.uv = PackedVector2Array()
		return
	poly.texture = tex
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var tile := texture_size(tex)
	if tile.x <= 0.0 or tile.y <= 0.0:
		return
	poly.texture_scale = Vector2.ONE
	poly.texture_offset = Vector2.ZERO
	poly.uv = world_tile_uvs(points, tile)
