extends Control

const type_map = {
	"ADDER": "Add",
	"ALU": "ALU",
	"AND": "And",
	"BUS1": "Bus",
	"BUSMUX": "MuxBus",
	"COUNTER": "PC",
	"DECODER": "",
	"DFLIPFLOP": "DFF",
	"DLATCH": "Bit",
	"INBUS16": "IO",
	"INBUS8": "IO",
	"INPUT4": "IO",
	"INPUT8": "IO",
	"INPUTBUS": "Bus",
	"INPUTCLK": "Clock",
	"INPUTPIN": "Wire",
	"INPUTPUSH": "ToggleSwitch",
	"INPUTSW": "ToggleSwitch",
	"JKFLIPFLOP": "",
	"LOOPBUS": "",
	"MULT": "",
	"NAND": "Nand",
	"NOR": "Nor",
	"NOT": "Not",
	"OR": "Or",
	"OUTBUS16": "IO",
	"OUTBUS8": "IO",
	"OUTPUT1": "Wire",
	"OUTPUT4": "IO",
	"OUTPUT8": "IO",
	"OUTPUTBUS": "Bus",
	"OUTPUTPIN": "Wire",
	"RAM": "RAM",
	"REG": "Register",
	"ROM": "ROM",
	"SEG7": "Display",
	"SHIFTREG": "",
	"SRFLIPFLOP": "",
	"XOR": "Xor"
}

var part = {
	node_name = "",
	part_type = "",
	tag = "",
	offset = [],
	data = {}
}

var circuit = {
	title = "",
	connections = [],
	parts = [],
	id_num = 1,
	version = 2,
	scroll_offset = [0, 0],
	snapping_distance = 20,
	snapping_enabled = true,
	zoom = 1.0,
	minimap_enabled = true,
}

var save_dir = ""

func _on_user_button_pressed():
	if save_dir == "":
		$SaveDialog.popup_centered()
	else:
		$FileDialog.current_dir = ProjectSettings.globalize_path("user://").rsplit("/", false, 1)[0]
		$FileDialog.popup_centered()


func _on_file_system_button_pressed():
	if save_dir == "":
		$SaveDialog.popup_centered()
	else:
		$FileDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		$FileDialog.popup_centered()


func _on_file_dialog_files_selected(paths):
	var results = PackedStringArray(["Files created:"])
	for path in paths:
		var res = ResourceLoader.load(path)
		if res is Circuit:
			var circ = circuit.duplicate()
			circ.title = path.get_file().get_slice('.', 0)
			circ.scroll_offset = [res.scroll_offset.x, res.scroll_offset.y]
			circ.snapping_distance = res.snap_distance
			circ.snapping_enabled = res.use_snap
			circ.zoom = res.zoom
			circ.minimap_enabled = res.minimap_enabled
			var removed_parts = []
			for p in res.nodes:
				var new_part = get_part(p)
				if new_part.part_type == "":
					removed_parts.append(new_part.node_name)
				else:
					circ.parts.append(new_part)
			for con in res.connections:
				if removed_parts.has(con.from) or removed_parts.has(con.to):
					continue
				circ.connections.append({
					"from_node": con.from,
					"from_port": con.from_port,
					"to_node": con.to,
					"to_port": con.to_port
				})
			var file_name = save_dir + "/" + circ.title + ".circ"
			save_data(file_name, circ)
			results.append(file_name)
		else:
			results.append("Error loading " + path)
	$VB/Results.text = "\n".join(results)


func get_part(p):
	var new_part = part.duplicate()
	new_part.node_name = p.name
	new_part.part_type = type_map.get(p.type, "")
	new_part.tag = p.data.get("tag", "")
	new_part.offset = [p.offset.x, p.offset.y]
	var n = 0
	if p.type.ends_with("4"):
		n = 4
	elif p.type.ends_with("8"):
		n = 8
	elif p.type.ends_with("16"):
		n = 16
	if n > 0:
		new_part.data["num_wires"] = n
	@warning_ignore("integer_division")
	match new_part.part_type:
		"Display":
			new_part.data = {
				color_index = 1 + 128 / 3,
				num_digits = 1
			}
		"ROM":
			new_part.data["bits"] = 16
			new_part.data["size"] = "8K"
			new_part.data["file"] = ""
		"RAM":
			new_part.data["bits"] = 16
			new_part.data["size"] = "8K"
		"PC":
			new_part.data["bits"] = 16
		"IO":
			new_part.data["bus_color"] = "ffff00ff"
			new_part.data["wire_color"] = "ffffffff"
			new_part.data["labels"] = ["- Data -", "- D0 -"]
			new_part.data["range"] = 0xff
	return new_part


func _on_save_path_button_pressed():
	$SaveDialog.popup_centered()


func _on_save_dialog_dir_selected(dir):
	save_dir = dir


func save_data(file_name, data):
	var save_file = FileAccess.open(file_name, FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(data, "\t")
		save_file.store_line(json_string)


func _on_licence_button_pressed():
	$LicencePanel.popup_centered()
