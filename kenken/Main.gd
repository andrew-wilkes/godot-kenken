extends Control

var current_button: Button
var groups = {}
var ops = {}

func _ready():
	for n in 36:
		var button: Button = %Cell
		if n > 0:
			button = %Cell.duplicate()
			%Grid.add_child(button)
		button.pressed.connect(on_button_clicked.bind(button))


func on_button_clicked(b: Button):
	if Input.is_key_pressed(KEY_SHIFT):
		current_button = b
		$PopupPanel.popup()
		$PopupPanel/LineEdit.grab_focus()
	b.modulate = %ColorPicker.color


func _on_popup_panel_popup_hide():
	current_button.text = $PopupPanel/LineEdit.text


func _on_solve_pressed():
	extract_groups()
	extract_ops()


func extract_groups():
	var idx = 0
	for cell in %Grid.get_children():
		var key = cell.modulate
		if groups.has(key):
			groups[key].append(idx)
		else:
			groups[key] = [idx]
		idx += 1
	print(groups)


func extract_ops():
	for cell in %Grid.get_children():
		var key = cell.modulate
		var txt = cell.text
		if txt.length() > 0:
			ops[key] = [int(txt.left(-1)), txt.right(1)]
	print(ops)
