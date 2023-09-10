extends Control

@export var grid_size = 6

var current_button: Button
var groups = {}
var ops = {}
var grid_numbers = []
var numbers

func _ready():
	numbers = range(1, grid_size + 1)
	%Grid.columns = grid_size
	grid_numbers.resize(grid_size * grid_size)
	grid_numbers.fill(0)
	for n in grid_size * grid_size:
		var button: Button = %Cell
		if n > 0:
			button = %Cell.duplicate()
			var style_box = button.get("theme_override_styles/normal")
			button.set("theme_override_styles/normal", style_box.duplicate())
			%Grid.add_child(button)
		button.set_meta("group_id", 0)
		button.pressed.connect(on_button_clicked.bind(button))
	#test_get_candidates_for_cell()
	#test_target_matched()
	#test_evaluate_group()
	#test_get_number_sets_for_group()
	test_get_number_combos_for_set()


func on_button_clicked(b: Button):
	if Input.is_key_pressed(KEY_SHIFT):
		current_button = b
		$PopupPanel.popup()
		$PopupPanel/LineEdit.grab_focus()
		$PopupPanel/LineEdit.text = ""
	else:
		var style_box = b.get("theme_override_styles/normal")
		style_box.border_color = %ColorPicker.color
		b.set_meta("group_id", %ColorPicker.color.to_rgba32())


func _on_popup_panel_popup_hide():
	current_button.text = $PopupPanel/LineEdit.text


func _on_solve_pressed():
	extract_groups()
	extract_ops()
	# Populate the grid numbers
	# Test groups for solution


func extract_groups():
	var idx = 0
	for cell in %Grid.get_children():
		var key = cell.get_meta("group_id")
		if groups.has(key):
			groups[key].append(idx)
		else:
			groups[key] = [idx]
		idx += 1


func extract_ops():
	for cell in %Grid.get_children():
		var key = cell.get_meta("group_id")
		var txt = cell.text
		if txt.length() > 0:
			ops[key] = [int(txt.left(-1)), txt.right(1)]


func _on_line_edit_text_submitted(_new_text):
	$PopupPanel.hide()


func get_candidates_for_cell(cell_idx: int):
	var candidates = numbers.duplicate()
	# Scan row and column to remove existing numbers from candidates
	var row_idx = cell_idx / grid_size * grid_size
	var col_idx = cell_idx % grid_size
	for m in grid_size:
		if row_idx != cell_idx:
			candidates.erase(grid_numbers[row_idx])
		row_idx += 1
		if col_idx != cell_idx:
			candidates.erase(grid_numbers[col_idx])
		col_idx += grid_size
	return candidates


func get_number_sets_for_group(group, target, op):
	var sets = []
	for n in range(grid_size, 0, -1):
		get_number_set(target, op, group.size(), 0, n, [], sets)
	return sets


func get_number_combos_for_set(num_set: Array):
	var combos = []
	for nums in num_set:
		for idx in nums.size():
			var combo = []
			append_num(combo, combos, idx, nums)
	return combos


func append_num(combo, combos, new_num_idx, nums):
	combo.append(new_num_idx)
	if combo.size() == nums.size():
		# Convert indexes to the numbers
		var combo_numbers = []
		for idx in combo:
			combo_numbers.append(nums[idx])
		if not combos.has(combo_numbers):
			combos.append(combo_numbers)
		return
	for idx in nums.size():
		if combo.has(idx):
			continue
		append_num(combo.duplicate(), combos, idx, nums)


func test_get_number_combos_for_set():
	print(get_number_combos_for_set([[1,1,1,3],[3,4,1]]))


func get_number_set(target, op, gsize, total, n, num_set, sets):
	if total == target:
		if num_set.size() == gsize:
			sets.append(num_set)
		return
	match op:
		'+':
			if total + n > target:
				return
			total += n
			num_set.append(n)
		'-':
			if total - n < target:
				return
			total -= n
			num_set.append(n)
		'*':
			if total * n > target:
				return
			total *= n
			num_set.append(n)
		'/':
			if total / n < target:
				return
			total /= n
			num_set.append(n)
	#print(set)
	for m in range(n, 0, -1):
		get_number_set(target, op, gsize, total, m, num_set.duplicate(), sets)


func test_get_number_sets_for_group():
	print(get_number_sets_for_group([1,1,1,1], 6, '+'))


func evaluate_group(group: Array, target, op):
	var matched = false
	# Loop over all combinations of numbers in group
	var indexes = range(group.size())
	for idx in indexes:
		var ids = []
		matched = append_idx(ids, idx, indexes, group, target, op)
		if matched:
			break
	return matched


func append_idx(ids: Array, new_id, indexes, group: Array, target, op):
	var done = true
	var matched = false
	ids.append(new_id)
	for idx in indexes:
		if ids.has(idx):
			continue
		done = false
		matched = append_idx(ids.duplicate(), idx, indexes, group, target, op)
		if matched:
			break
	if done:
		print(ids)
		matched = target_matched(ids, group, target, op)
	return matched


func target_matched(ids, group, target, op):
	var n = 0
	for idx in ids:
		var cell_idx = group[idx]
		var num = grid_numbers[cell_idx]
		if num == 0:
			continue
		if n == 0:
			n = num
			continue
		match op:
			'+':
				n += num
			'-':
				n -= num
			'*':
				n *= num
			'/':
				n /= num
	if n == target:
		return true
	else:
		return false


func test_target_matched():
	grid_numbers = [3,4,8,2,2,8]
	assert(target_matched([0,1],[0,1],7,'+')) # ids, group, target, op
	assert(not target_matched([0,1],[0,1],3,'+'))
	assert(target_matched([1,0],[0,1],1,'-'))
	assert(not target_matched([1,0],[0,1],3,'-'))
	assert(target_matched([0,1],[3,5],16,'*'))
	assert(not target_matched([0,1],[3,5],15,'*'))
	assert(target_matched([1,0],[1,2],2,'/'))
	assert(not target_matched([1,0],[1,2],3,'/'))
	assert(target_matched([0,1,2],[5,1,3],2,'-'))


func test_evaluate_group():
	grid_numbers = [3,4,8,2,2,8]
	assert(evaluate_group([0,1], 7, '+'))
	assert(evaluate_group([4,5], 4, '/'))


func test_get_candidates_for_cell():
	grid_numbers = [0,2,0,0, 1,1,1,6, 4,0,0,0, 2,2,2,2]
	grid_size = 4
	assert(get_candidates_for_cell(0) == [3,5,6])
	assert(get_candidates_for_cell(5) == [3,4,5])
	assert(get_candidates_for_cell(15) == [1,3,4,5])
