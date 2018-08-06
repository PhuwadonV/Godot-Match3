extends Node2D

const SCENE_BLOCK = preload("res://Scenes/Block.tscn")
const SCRIPT_BLOCK = preload("res://Scripts/Block.gd")

export(int) var BLOCK_COUNT_X = 8
export(int) var BLOCK_COUNT_Y = 8

var m_blocks_color_id = []
var m_blocks = []
var m_top_blocks = []
var m_bottom_blocks = []
var m_destroy_queue = []
var m_selected_block = null
var m_score_label
var m_score_count = 0

func _ready():
	randomize()
	m_score_label = get_parent().get_child(3)
	m_top_blocks.resize(BLOCK_COUNT_X)
	m_bottom_blocks.resize(BLOCK_COUNT_Y)
	gen_blocks_color_id()
	create_blocks()

func _physics_process(delta):
	for blocks_index in m_destroy_queue:
		var delay
		for block_index in blocks_index:
			var block = m_blocks[block_index[0]][block_index[1]]
			if block.is_waiting_to_destroy():
				delay = block.get_remain_time_before_destroy()
			elif delay:
				block.delay_destroy(delay)
			else:
				block.delay_destroy()
	m_destroy_queue.clear()
	for block in m_bottom_blocks:
		while(block):
			block.update(delta)
			block = block.get_top_block()
	
func gen_blocks_color_id():
	m_blocks_color_id.resize(BLOCK_COUNT_X)
	for i in range(BLOCK_COUNT_X):
		m_blocks_color_id[i] = []
		m_blocks_color_id[i].resize(BLOCK_COUNT_Y)
		for j in range(BLOCK_COUNT_Y):
			var rand_val = SCRIPT_BLOCK.get_random_color_id()
			if rand_val == m_blocks_color_id[i][j - 1] and rand_val == m_blocks_color_id[i][j - 2]:
				rand_val = SCRIPT_BLOCK.get_shift_color_id(rand_val)
			if m_blocks_color_id[i - 1] and rand_val == m_blocks_color_id[i - 1][j] and m_blocks_color_id[i - 2] and rand_val == m_blocks_color_id[i - 1][j]:
				rand_val = SCRIPT_BLOCK.get_shift_color_id(rand_val)
				if rand_val == m_blocks_color_id[i][j - 1] and rand_val == m_blocks_color_id[i][j - 2]:
					rand_val = SCRIPT_BLOCK.get_shift_color_id(rand_val)
			m_blocks_color_id[i][j] = rand_val
	
func find_matched_blocks_index(x, y):
	var color_id = m_blocks_color_id[x][y]
	var matched_blocks = []
	if y > 0 and color_id == m_blocks_color_id[x][y - 1]:
		if y > 1 and color_id == m_blocks_color_id[x][y - 2]:
			matched_blocks.push_back([x, y - 1])
			matched_blocks.push_back([x, y - 2])
		elif y < BLOCK_COUNT_Y - 1 and color_id == m_blocks_color_id[x][y + 1]:
			matched_blocks.push_back([x, y - 1])
			matched_blocks.push_back([x, y + 1])
	if y < BLOCK_COUNT_Y - 2 and color_id == m_blocks_color_id[x][y + 1] and color_id == m_blocks_color_id[x][y + 2]:
		matched_blocks.push_back([x, y + 1])
		matched_blocks.push_back([x, y + 2])
	if x > 0 and color_id == m_blocks_color_id[x - 1][y]:
		if x > 1 and color_id == m_blocks_color_id[x - 2][y]:
			matched_blocks.push_back([x - 1, y])
			matched_blocks.push_back([x - 2, y])
		elif x < BLOCK_COUNT_X - 1 and color_id == m_blocks_color_id[x + 1][y]:
			matched_blocks.push_back([x - 1, y])
			matched_blocks.push_back([x + 1, y])
	if x < BLOCK_COUNT_X - 2 and color_id == m_blocks_color_id[x + 1][y] and color_id == m_blocks_color_id[x + 2][y]:
		matched_blocks.push_back([x + 1, y])
		matched_blocks.push_back([x + 2, y])
	if matched_blocks.size() > 0:
		matched_blocks.push_back([x, y])
	return matched_blocks
	
func create_top_block(color_id, x):
	var block = SCENE_BLOCK.instance()
	block.init(color_id)
	block.set_callbacks(self)
	if !m_top_blocks[x]:
		m_top_blocks[x] = block
		m_bottom_blocks[x] = block
		block.set_pos_row_index(0)
		block.set_pos_col_index(x)
	else:
		block.set_pos_to_top_block(m_top_blocks[x])
		m_top_blocks[x].set_top_block(block)
		block.set_bottom_block(m_top_blocks[x])
		m_top_blocks[x] = block
	add_child(block)
	return block
	
func create_blocks():
	m_blocks.resize(BLOCK_COUNT_X)
	for i in range(BLOCK_COUNT_X):
		m_blocks[i] = []
		m_blocks[i].resize(BLOCK_COUNT_Y)
		for j in range(BLOCK_COUNT_Y):
			m_blocks[i][j] = create_top_block(m_blocks_color_id[i][j], i)
	for i in range(BLOCK_COUNT_X):
		create_top_block(SCRIPT_BLOCK.get_random_color_id(), i)
	
func is_adjacent(block1, block2):
	return abs(block1.get_column_index() - block2.get_column_index()) + abs(block1.get_row_index() - block2.get_row_index()) == 1
	
func block_on_destroy(block):
	m_score_count += 1
	m_score_label.text = "Score : " + str(m_score_count)
	var index_col = block.get_column_index()
	var index_row = block.get_row_index()
	create_top_block(SCRIPT_BLOCK.get_random_color_id(), index_col)
	if block == m_bottom_blocks[index_col]:
		if block.get_top_block():
			m_bottom_blocks[index_col] = block.get_top_block()
		else:
			m_bottom_blocks[index_col] = null
	m_blocks_color_id[index_col][index_row] = 0
	m_blocks[index_col][index_row] = null
	
func block_on_click(block):
	if m_selected_block == null:
		m_selected_block = block
		m_selected_block.set_texture_to_selected()
	elif m_selected_block == block:
		m_selected_block.set_texture_to_default()
		m_selected_block = null
	elif m_selected_block.get_color_id() != block.get_color_id() and is_adjacent(m_selected_block, block):
		var index_x_1 = m_selected_block.get_column_index()
		var index_y_1 = m_selected_block.get_row_index()
		var index_x_2 = block.get_column_index()
		var index_y_2 = block.get_row_index()
		m_blocks_color_id[index_x_1][index_y_1] = 0
		m_blocks[index_x_1][index_y_1] = null
		m_blocks_color_id[index_x_2][index_y_2] = 0
		m_blocks[index_x_2][index_y_2] = null
		m_selected_block.disable_input()
		block.disable_input()
		m_selected_block.swap(block)
		m_selected_block.set_texture_to_default()
		m_selected_block = null
	else:
		m_selected_block.set_texture_to_default()
		m_selected_block = block
		m_selected_block.set_texture_to_selected()
		
func block_on_drop_move(block):
	block.disable_input()
	var index_col = block.get_column_index()
	var index_row = block.get_row_index()
	if(index_col >= BLOCK_COUNT_X or index_row >= BLOCK_COUNT_Y):
		return
	m_blocks_color_id[index_col][index_row] = 0
	m_blocks[index_col][index_row] = null
	
func block_on_drop_stop(block):
	block.enable_input()
	var index_col = block.get_column_index()
	var index_row = block.get_row_index()
	if(index_col >= BLOCK_COUNT_X or index_row >= BLOCK_COUNT_Y):
		return
	m_blocks_color_id[index_col][index_row] = block.get_color_id()
	m_blocks[index_col][index_row] = block
	var matched_blocks = find_matched_blocks_index(index_col, index_row)
	if matched_blocks.size() > 0:
		m_destroy_queue.push_back(matched_blocks)
		
func block_on_stop_swapping(block1, block2, is_swap_back):
	var index_x_1 = block1.get_column_index()
	var index_y_1 = block1.get_row_index()
	var index_x_2 = block2.get_column_index()
	var index_y_2 = block2.get_row_index()
	m_blocks_color_id[index_x_1][index_y_1] = block1.get_color_id()
	m_blocks[index_x_1][index_y_1] = block1
	m_blocks_color_id[index_x_2][index_y_2] = block2.get_color_id()
	m_blocks[index_x_2][index_y_2] = block2
	
	if !block1.get_top_block():
		m_top_blocks[block1.get_column_index()] = block1
	if !block2.get_top_block():
		m_top_blocks[block2.get_column_index()] = block2	

	block1.enable_input()
	block2.enable_input()
	
	var matched_blocks_index_1 = find_matched_blocks_index(index_x_1, index_y_1)
	var matched_blocks_index_2 = find_matched_blocks_index(index_x_2, index_y_2)
	
	var matched = true 
	
	if !is_swap_back and matched_blocks_index_1.size() == 0:
		if matched_blocks_index_2.size() == 0:
			block1.swap(block2, true)
			m_blocks_color_id[index_x_1][index_y_1] = 0
			m_blocks[index_x_1][index_y_1] = null
			m_blocks_color_id[index_x_2][index_y_2] = 0
			m_blocks[index_x_2][index_y_2] = null
		else:
			block1.enable_input()
			m_destroy_queue.push_back(matched_blocks_index_2)
	elif matched_blocks_index_2.size() == 0:
		block2.enable_input()
		m_destroy_queue.push_back(matched_blocks_index_1)
	else:
		m_destroy_queue.push_back(matched_blocks_index_1)
		m_destroy_queue.push_back(matched_blocks_index_2)
		
func block_on_change_bottom(block, column_index):
	m_bottom_blocks[column_index] = block
	
func block_on_delay_destroy(block):
	if m_selected_block == block:
		m_selected_block.set_texture_to_default()
		m_selected_block = null