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
	
	chart_file_dialog.pressed.connect(chart_file_dialog_pressed)
	meta_file_dialog.pressed.connect(meta_file_dialog_pressed)
	events_file_dialog.pressed.connect(events_file_dialog_pressed)
	output_file_dialog.pressed.connect(output_file_dialog_pressed)
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

func chart_file_dialog_pressed():
	var current : Importer = importers[index]
	if Engine.is_editor_hint():
		var editor_file : EditorFileDialog = EditorFileDialog.new()
		editor_file.title = "Select Chart"
		editor_file.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		editor_file.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		editor_file.filters = ["*" + current.get_extension()]
		editor_file.file_selected.connect(func(path:String)->void:chart_line_edit.text=path;editor_file.queue_free())
		editor_file.visible = true
		add_child(editor_file)
		return
		
	var file_dialog : FileDialog = FileDialog.new()
	file_dialog.title = "Select Chart"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.filters = ["*" + current.get_extension()]
	file_dialog.file_selected.connect(func(path:String)->void:chart_line_edit.text=path;file_dialog.queue_free())
	file_dialog.visible = true
	add_child(file_dialog)
	
func meta_file_dialog_pressed():
	var current : Importer = importers[index]
	if Engine.is_editor_hint():
		var editor_file : EditorFileDialog = EditorFileDialog.new()
		editor_file.title = "Select Chart's Metadata"
		editor_file.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		editor_file.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		editor_file.filters = ["*" + current.get_meta_extension()]
		editor_file.file_selected.connect(func(path:String)->void:meta_line_edit.text=path;editor_file.queue_free())
		editor_file.visible = true
		add_child(editor_file)
		return
		
	var file_dialog : FileDialog = FileDialog.new()
	file_dialog.title = "Select Chart's Metadata"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.filters = ["*" + current.get_meta_extension()]
	file_dialog.file_selected.connect(func(path:String)->void:meta_line_edit.text=path;file_dialog.queue_free())
	file_dialog.visible = true
	add_child(file_dialog)

func events_file_dialog_pressed():
	var current : Importer = importers[index]
	if Engine.is_editor_hint():
		var editor_file : EditorFileDialog = EditorFileDialog.new()
		editor_file.title = "Select Chart's Events"
		editor_file.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		editor_file.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		editor_file.filters = ["*" + current.get_events_extension()]
		editor_file.file_selected.connect(func(path:String)->void:events_line_edit.text=path;editor_file.queue_free())
		editor_file.visible = true
		add_child(editor_file)
		return
		
	var file_dialog : FileDialog = FileDialog.new()
	file_dialog.title = "Select Chart's Events"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.filters = ["*" + current.get_events_extension()]
	file_dialog.file_selected.connect(func(path:String)->void:events_line_edit.text=path;file_dialog.queue_free())
	file_dialog.visible = true
	add_child(file_dialog)
		
func output_file_dialog_pressed():
	var current : Importer = importers[index]
	if Engine.is_editor_hint():
		var editor_file : EditorFileDialog = EditorFileDialog.new()
		editor_file.title = "Select Output Folder"
		editor_file.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
		editor_file.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		editor_file.dir_selected.connect(func(path:String)->void:output_line_edit.text=path;editor_file.queue_free())
		editor_file.visible = true
		add_child(editor_file)
		return
		
	var file_dialog : FileDialog = FileDialog.new()
	file_dialog.title = "Select Output Folder"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_dialog.dir_selected.connect(func(path:String)->void:output_line_edit.text=path;file_dialog.queue_free())
	file_dialog.visible = true
	add_child(file_dialog)
