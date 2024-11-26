@tool

extends Control

@onready var console_output : Label = $ScrollContainer/VBoxContainer/ConsoleContainer/ConsoleOutput

@onready var chart_type_selection : OptionButton = $"ScrollContainer/VBoxContainer/TypeContainer/OptionButton"

@onready var chart_line_edit : LineEdit = $"ScrollContainer/VBoxContainer/InputContainer/LineEdit"

@onready var meta_container : HBoxContainer = $ScrollContainer/"VBoxContainer/MetaContainer"
@onready var meta_line_edit : LineEdit = $"ScrollContainer/VBoxContainer/MetaContainer/LineEdit"

@onready var events_container : HBoxContainer = $"ScrollContainer/VBoxContainer/EventsContainer"
@onready var events_line_edit : LineEdit = $"ScrollContainer/VBoxContainer/EventsContainer/LineEdit"

@onready var song_meta_check : CheckBox = $"ScrollContainer/VBoxContainer/OutputOptionsContainer/SongMetaCheck"
@onready var events_check : CheckBox = $"ScrollContainer/VBoxContainer/OutputOptionsContainer/EventsCheck"

@onready var output_line_edit : LineEdit = $"ScrollContainer/VBoxContainer/OutputContainer/LineEdit"
@onready var output_rbc_button : Button = $"HBoxContainer/RBCSaveButton"
@onready var output_trbc_button : Button = $"HBoxContainer/TRBCSaveButton"

@onready var chart_file_dialog : Button = $"ScrollContainer/VBoxContainer/InputContainer/Button"
@onready var meta_file_dialog : Button = $"ScrollContainer/VBoxContainer/MetaContainer/Button"
@onready var events_file_dialog : Button = $"ScrollContainer/VBoxContainer/EventsContainer/Button"
@onready var output_file_dialog : Button = $"ScrollContainer/VBoxContainer/OutputContainer/Button"

var index : int = 0

const Importer = preload("res://addons/rubichart_converter/importer.gd")
var importers : Array[Importer] = []

const chart_selector_scene : PackedScene = preload("res://addons/rubichart_converter/resources/ChartSelector.tscn")

func _ready() -> void:
	var importers_path : String = "res://addons/rubichart_converter/converters/"
	var scripts : PackedStringArray = DirAccess.get_files_at(importers_path)
	for i in scripts.size():
		if scripts[i].ends_with(".uid"):
			continue
		
		var current : Importer = (load(importers_path + scripts[i]) as GDScript).new() as Importer
		current.main_scene = self
		chart_type_selection.add_item(current.get_name())
		importers.push_back(current)
	
	chart_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, [importers[index].get_extension()], func(path:String)->void:chart_line_edit.text=path))
	meta_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, [importers[index].get_meta_extension()], func(path:String)->void:meta_file_dialog.text=path))
	events_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, [importers[index].get_events_extension()], func(path:String)->void:events_line_edit.text=path))
	output_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_DIR, [], func(path:String)->void:output_line_edit.text=path))
	
	chart_type_selection.item_selected.connect(on_type_changed)
	output_rbc_button.pressed.connect(convert_to_rbc)
	output_trbc_button.pressed.connect(func()->void:print_new_line(".trbc has not been made yet, sorry! :("))
	
	index = 0
	on_type_changed(index)

func on_type_changed(idx : int):
	index = idx
	var current : Importer = importers[index]
	
	chart_line_edit.placeholder_text = "res://path/to/chart" + current.get_extension()
	
	events_container.visible = current.needs_events_file()
	events_line_edit.placeholder_text = "res://path/to/events" + current.get_events_extension()
	
	meta_container.visible = current.needs_meta_file()
	meta_line_edit.placeholder_text = "res://path/to/meta" + current.get_meta_extension()

func convert_to_rbc() -> void:
	clear_console()
	
	var output : Dictionary = await get_output()
	if output.is_empty():
		return
	
	var output_folder : String = output_line_edit.text
	var charts : Dictionary = output["charts"] as Dictionary
	for key in charts.keys():
		var writer : FileAccess = FileAccess.open(output_folder + "/" + key + ".rbc", FileAccess.WRITE)
		writer.store_buffer((charts[key] as RubiChart).ToBytes())
		writer.close()
		
		EditorInterface.get_file_system_dock().navigate_to_path(output_folder + "/" + key + ".rbc")

	if song_meta_check.button_pressed:
		ResourceSaver.save(output["meta"], output_folder + "/Meta.tres")
	if events_check.button_pressed:
		ResourceSaver.save(output["events"], output_folder + "/Events.tres")

func get_output() -> Dictionary:
	var current : Importer = importers[index]
	var chart_contents : FileAccess = FileAccess.open(chart_line_edit.text, FileAccess.READ)
	var meta_contents : FileAccess = FileAccess.open(meta_line_edit.text, FileAccess.READ) if current.needs_meta_file() else null
	var events_contents : FileAccess = FileAccess.open(events_line_edit.text, FileAccess.READ) if current.needs_events_file() else null
	var output : Dictionary = await importers[index].convert_chart(chart_contents, meta_contents, events_contents)
	
	var file_accessors : Array[FileAccess] = [chart_contents, meta_contents, events_contents]
	for i in file_accessors.size():
		var file_access : FileAccess = file_accessors[i]
		if file_access == null or !file_access.is_open():
			continue
			
		file_access.close()
	
	return output

func print_new_line(text : String) -> void:
	console_output.text += "\n" + text
	
func clear_console() -> void:
	console_output.text = ""
	
func open_file_dialog(file_mode : int, extensions : PackedStringArray, on_single_chosen : Callable, on_multiple_chosen : Callable = func():):
	var current : Importer = importers[index]
	if Engine.is_editor_hint():
		var editor_file : EditorFileDialog = EditorFileDialog.new()
		editor_file.file_mode = file_mode
		editor_file.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		editor_file.filters = extensions
		
		editor_file.file_selected.connect(func(path:String)->void:on_single_chosen.call(path);editor_file.queue_free())
		editor_file.files_selected.connect(func(paths:PackedStringArray)->void:on_multiple_chosen.call(paths);editor_file.queue_free())
		editor_file.dir_selected.connect(func(path:String)->void:on_single_chosen.call(path);editor_file.queue_free())
		
		editor_file.visible = true
		add_child(editor_file)
		return
		
	var file_dialog : FileDialog = FileDialog.new()
	file_dialog.file_mode = file_mode
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.filters = extensions
	
	file_dialog.file_selected.connect(func(path:String)->void:on_single_chosen.call(path);file_dialog.queue_free())
	file_dialog.files_selected.connect(func(paths:PackedStringArray)->void:on_multiple_chosen.call(paths);file_dialog.queue_free())
	file_dialog.dir_selected.connect(func(path:String)->void:on_single_chosen.call(path);file_dialog.queue_free())
	
	file_dialog.visible = true
	add_child(file_dialog)

func open_chart_selector(selections : PackedStringArray) -> PackedInt32Array:
	var chart_selector : AcceptDialog = chart_selector_scene.instantiate()
	var item_list : ItemList = chart_selector.get_node("VBoxContainer/ScrollContainer/ItemList")
	for i in selections.size():
		item_list.add_item(selections[i])

	add_child(chart_selector)
	chart_selector.visible = true
	await chart_selector.confirmed
	chart_selector.queue_free()
	
	return item_list.get_selected_items()
