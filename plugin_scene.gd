@tool

extends Control

@onready var console_output : Label = $VBoxContainer/ConsoleContainer/PanelContainer/ConsoleOutput

@onready var chart_type_selection : OptionButton = $"VBoxContainer/TypeContainer/OptionButton"

@onready var chart_line_edit : LineEdit = $"VBoxContainer/InputContainer/LineEdit"

@onready var meta_container : HBoxContainer = $"VBoxContainer/MetaContainer"
@onready var meta_line_edit : LineEdit = $"VBoxContainer/MetaContainer/LineEdit"

@onready var events_container : HBoxContainer = $"VBoxContainer/EventsContainer"
@onready var events_line_edit : LineEdit = $"VBoxContainer/EventsContainer/LineEdit"

@onready var song_meta_check : CheckBox = $"VBoxContainer/OutputOptionsContainer/SongMetaCheck"
@onready var events_check : CheckBox = $"VBoxContainer/OutputOptionsContainer/EventsCheck"

@onready var output_line_edit : LineEdit = $"VBoxContainer/OutputContainer/LineEdit"
@onready var output_button : Button = $"VBoxContainer/SaveButton"

@onready var chart_file_dialog : Button = $"VBoxContainer/InputContainer/Button"
@onready var meta_file_dialog : Button = $"VBoxContainer/MetaContainer/Button"
@onready var events_file_dialog : Button = $"VBoxContainer/EventsContainer/Button"
@onready var output_file_dialog : Button = $"VBoxContainer/OutputContainer/Button"

var index : int = 0

const Importer = preload("res://addons/rubichart_importer/importer.gd")
var importers : Array[Importer] = []

func _ready() -> void:
	var importers_path : String = "res://addons/rubichart_importer/importers/"
	var scripts : PackedStringArray = DirAccess.get_files_at(importers_path)
	for i in scripts.size():
		var current : Importer = (load(importers_path + scripts[i]) as GDScript).new() as Importer
		current.main_scene = self
		chart_type_selection.add_item(current.get_name())
		importers.push_back(current)
	
	chart_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, [importers[index].get_extension()], func(path:String)->void:chart_line_edit.text=path))
	meta_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, [importers[index].get_meta_extension()], func(path:String)->void:meta_file_dialog.text=path))
	events_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, [importers[index].get_events_extension()], func(path:String)->void:events_line_edit.text=path))
	output_file_dialog.pressed.connect(func()->void:open_file_dialog(FileDialog.FILE_MODE_OPEN_DIR, [], func(path:String)->void:output_line_edit.text=path))
	
	chart_type_selection.item_selected.connect(on_type_changed)
	output_button.pressed.connect(start_convert)
	
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

func start_convert() -> void:
	clear_console()
	var current : Importer = importers[index]
	
	var chart_contents : String = FileAccess.get_file_as_string(chart_line_edit.text)
	var meta_contents : String = FileAccess.get_file_as_string(meta_line_edit.text) if current.needs_meta_file() else ""
	var events_contents : String = FileAccess.get_file_as_string(events_line_edit.text) if current.needs_events_file() else ""
	var output : Dictionary = importers[index].convert_chart(chart_contents, meta_contents, events_contents)
	
	var output_folder : String = output_line_edit.text
	ResourceSaver.save(output["chart"], output_folder + "/Chart.tres")
	if song_meta_check.button_pressed:
		ResourceSaver.save(output["meta"], output_folder + "/Meta.tres")
	if events_check.button_pressed:
		ResourceSaver.save(output["events"], output_folder + "/Events.tres")

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
