extends Control

@export var grid_size = 4

var current_button: Button
var cages = {}
var grid_numbers = []
var numbers

class Cage:
	var cells = []
	var number_sets = []
	var target = 0
	var op = '+'

func _ready():
	numbers = range(1, grid_size + 1)
	%Grid.columns = grid_size
	grid_numbers.resize(grid_size * grid_size)
	for n in grid_size * grid_size:
		var button: Button = %Cell
		if n > 0:
			button = %Cell.duplicate()
			var style_box = button.get("theme_override_styles/normal")
			button.set("theme_override_styles/normal", style_box.duplicate())
			%Grid.add_child(button)
		button.set_meta("cage_id", 0)
		button.pressed.connect(on_button_clicked.bind(button))
	#test_get_candidates_for_cell()
	#test_target_matched()
	#test_evaluate_cage()
	test_get_number_sets_for_cage()
	#test_get_number_combos_for_set()
	#test_valid_grid()


func on_button_clicked(b: Button):
	if Input.is_key_pressed(KEY_SHIFT):
		current_button = b
		$PopupPanel.popup()
		$PopupPanel/LineEdit.grab_focus()
		$PopupPanel/LineEdit.text = ""
	else:
		var style_box = b.get("theme_override_styles/normal")
		style_box.border_color = %ColorPicker.color
		b.set_meta("cage_id", %ColorPicker.color.to_rgba32())


func _on_popup_panel_popup_hide():
	current_button.text = $PopupPanel/LineEdit.text


func _on_solve_pressed():
	grid_numbers.fill(0)
	extract_cages()
	set_number_sets()
	if apply_numbers_to_grid(0):
		print(grid_numbers)
	else:
		print("FAILED")


func extract_cages():
	var idx = 0
	for cell in %Grid.get_children():
		var key = cell.get_meta("cage_id")
		var txt = cell.text
		if cages.has(key):
			cages[key].cells.append(idx)
		else:
			var cage = Cage.new()
			cage.cells = [idx]
			cages[key] = cage
		if txt.length() > 0:
			cages[key].target = int(txt.left(-1))
			cages[key].op = txt.right(1)
		idx += 1


func set_number_sets():
	for cage in cages.values():
		cage.number_sets = get_number_sets_for_cage(cage.cells, cage.target, cage.op)


func apply_numbers_to_grid(cage_id):
	if cage_id == cages.size():
		return true 
	for number_set in cages.values()[cage_id].number_sets:
		for idx in number_set.size():
			grid_numbers[cages[cage_id].cells[idx]] = number_set[idx]
		if valid_grid() and apply_numbers_to_grid(cage_id + 1):
			return true
	return false


func valid_grid():
	# Each row or column must contain only 1 of numbers > 0
	var x = 0
	var y = 0
	var xoff = grid_size * grid_size - grid_size + 1
	for n in grid_size:
		var row = grid_numbers.slice(y, y + grid_size)
		var col = grid_numbers.slice(x, x + xoff, grid_size)
		#print(row)
		#print(col)
		for num in numbers:
			if row.count(num) > 1:
				return false
			if col.count(num) > 1:
				return false
		x += 1
		y += grid_size
	return true


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


func get_number_sets_for_cage(cells, target, op):
	var sets = []
	for n in range(grid_size, 0, -1): # 4 3 2 1 if grid_size is 4
		get_number_set(target, op, cells.size(), 0, n, [n], sets)
	return sets


func get_number_set(target, op, cage_size, total, n, num_set, sets):
	#prints(n, num_set)
	if num_set.size() == cage_size:
		if total == target:
			# Take care of bug where duplicate sets are made
			#if not sets.has(num_set):
			sets.append(num_set)
		return true
	if total == 0:
		total = n
	else:
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
	for m in range(n, 0, -1): # n .. 1
		if get_number_set(target, op, cage_size, total, m, num_set.duplicate(), sets):
			break


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


func evaluate_cage(cage: Array, target, op):
	var matched = false
	# Loop over all combinations of numbers in cage
	var indexes = range(cage.size())
	for idx in indexes:
		var ids = []
		matched = append_idx(ids, idx, indexes, cage, target, op)
		if matched:
			break
	return matched


func append_idx(ids: Array, new_id, indexes, cage: Array, target, op):
	var done = true
	var matched = false
	ids.append(new_id)
	for idx in indexes:
		if ids.has(idx):
			continue
		done = false
		matched = append_idx(ids.duplicate(), idx, indexes, cage, target, op)
		if matched:
			break
	if done:
		print(ids)
		matched = target_matched(ids, cage, target, op)
	return matched


func target_matched(ids, cage, target, op):
	var n = 0
	for idx in ids:
		var cell_idx = cage[idx]
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


func test_evaluate_cage():
	grid_numbers = [3,4,8,2,2,8]
	assert(evaluate_cage([0,1], 7, '+'))
	assert(evaluate_cage([4,5], 4, '/'))


func test_get_candidates_for_cell():
	grid_numbers = [0,2,0,0, 1,1,1,6, 4,0,0,0, 2,2,2,2]
	grid_size = 4
	assert(get_candidates_for_cell(0) == [3,5,6])
	assert(get_candidates_for_cell(5) == [3,4,5])
	assert(get_candidates_for_cell(15) == [1,3,4,5])


func test_get_number_combos_for_set():
	print(get_number_combos_for_set([[1,1,1,3],[3,4,1]]))


func test_get_number_sets_for_cage():
	grid_size = 4
	print(get_number_sets_for_cage([1,1,1,1], 6, '+'))
	print(get_number_sets_for_cage([1,1], 3, '+'))
	print(get_number_sets_for_cage([1,1,1], 8, '+'))
	print(get_number_sets_for_cage([1,1,1,1], 1, '-'))
	print(get_number_sets_for_cage([1,1,1], 8, '*'))
	print(get_number_sets_for_cage([1,1,1], 2, '/'))


func test_valid_grid():
	grid_size = 4
	grid_numbers = [1,2,3,4, 2,3,4,1, 3,4,1,2, 4,1,2,3]
	assert(valid_grid())
	grid_numbers = [1,2,3,4, 2,3,2,1, 3,4,1,2, 4,1,0,3] # 2 in row
	assert(not valid_grid())
	grid_numbers = [0,1,2,3, 1,4,3,2, 3,4,1,0, 2,3,0,0] # 4 in col
	assert(not valid_grid())
