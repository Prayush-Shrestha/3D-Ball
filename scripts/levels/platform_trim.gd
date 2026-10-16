extends Node3D
## PlatformTrim - level beautifier. At runtime it adds a thin golden rim
## around the top edge of every static platform under the sibling
## "Platforms" node, so safe edges read clearly and all levels share one
## premium look. Four thin strips per platform; no physics changes.

@export var strip_height := 0.14
@export var strip_width := 0.4
@export var overhang := 0.12


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.25, 1.0)
	mat.metallic = 0.35
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.2, 1.0)
	mat.emission_energy_multiplier = 0.3
	var platforms: Node = get_parent().get_node_or_null("Platforms")
	if platforms == null:
		return
	for body in platforms.get_children():
		if not (body is StaticBody3D):
			continue
		var mi: MeshInstance3D = body.get_node_or_null("Mesh")
		if mi == null or not (mi.mesh is BoxMesh):
			continue
		_add_rim(body, mi.mesh.size, mat)


func _add_rim(body: StaticBody3D, size: Vector3, mat: Material) -> void:
	var top_y := size.y * 0.5 + strip_height * 0.5 - 0.01
	var long_mesh := BoxMesh.new()
	long_mesh.size = Vector3(size.x + overhang, strip_height, strip_width)
	var short_mesh := BoxMesh.new()
	short_mesh.size = Vector3(strip_width, strip_height, size.z - strip_width * 2.0)
	var edge_z := size.z * 0.5 - strip_width * 0.5 + overhang * 0.5
	var edge_x := size.x * 0.5 - strip_width * 0.5 + overhang * 0.5
	_add_strip(body, long_mesh, mat, Vector3(0, top_y, edge_z))
	_add_strip(body, long_mesh, mat, Vector3(0, top_y, -edge_z))
	_add_strip(body, short_mesh, mat, Vector3(edge_x, top_y, 0))
	_add_strip(body, short_mesh, mat, Vector3(-edge_x, top_y, 0))


func _add_strip(body: StaticBody3D, mesh: BoxMesh, mat: Material, pos: Vector3) -> void:
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = mat
	strip.position = pos
	body.add_child(strip)
