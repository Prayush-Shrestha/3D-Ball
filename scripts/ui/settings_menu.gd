extends PanelContainer
## SettingsMenu - master/music/sfx volume, camera sensitivity, touch toggle.
## Used as a popup panel inside the main menu.

@onready var master_slider: HSlider = $VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $VBox/SfxRow/SfxSlider
@onready var sens_slider: HSlider = $VBox/SensRow/SensSlider
@onready var touch_option: OptionButton = $VBox/TouchRow/TouchOption


func _ready() -> void:
	if touch_option.item_count == 0:
		touch_option.add_item("Auto", 0)
		touch_option.add_item("Always show", 1)
		touch_option.add_item("Hide", 2)
	_load_values()
	master_slider.value_changed.connect(_on_volumes_changed.bind())
	music_slider.value_changed.connect(_on_volumes_changed.bind())
	sfx_slider.value_changed.connect(_on_volumes_changed.bind())
	sens_slider.value_changed.connect(_on_sens_changed)
	touch_option.item_selected.connect(_on_touch_changed)
	var close_btn: Button = get_node_or_null("VBox/CloseButton")
	if close_btn != null and not close_btn.pressed.is_connected(_on_close):
		close_btn.pressed.connect(_on_close)


func _on_close() -> void:
	# Used by the standalone settings scene. Inside the main menu the
	# menu script also hides its panels, so both handlers just hide.
	visible = false
	if get_tree().current_scene != null and get_tree().current_scene.name == "SettingsMenu":
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").load_main_menu()


func _load_values() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	master_slider.value = sm.master_volume * 100.0
	music_slider.value = sm.music_volume * 100.0
	sfx_slider.value = sm.sfx_volume * 100.0
	sens_slider.value = sm.camera_sensitivity * 100.0
	touch_option.select(sm.show_touch_controls)


func _on_volumes_changed(_v: float) -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	sm.set_volumes(master_slider.value / 100.0, music_slider.value / 100.0, sfx_slider.value / 100.0)


func _on_sens_changed(_v: float) -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").camera_sensitivity = sens_slider.value / 100.0
		get_node("/root/SaveManager").save_game()


func _on_touch_changed(idx: int) -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").show_touch_controls = idx
		get_node("/root/SaveManager").save_game()
