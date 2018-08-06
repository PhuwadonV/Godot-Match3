extends Area2D

const SIZE_X = 70
const SIZE_Y = 70
const VARIATION = 6

const IMAGE_DEFAULT = [
	preload("res://Images/Blocks/block-default-0.png"),
	preload("res://Images/Blocks/block-default-1.png"),
	preload("res://Images/Blocks/block-default-2.png"),
	preload("res://Images/Blocks/block-default-3.png"),
	preload("res://Images/Blocks/block-default-4.png"),
	preload("res://Images/Blocks/block-default-5.png")]
	
const IMAGE_SELECTED = [
	preload("res://Images/Blocks/block-selected-0.png"),
	preload("res://Images/Blocks/block-selected-1.png"),
	preload("res://Images/Blocks/block-selected-2.png"),
	preload("res://Images/Blocks/block-selected-3.png"),
	preload("res://Images/Blocks/block-selected-4.png"),
	preload("res://Images/Blocks/block-selected-5.png")]

export(float) var drop_speed_init
export(float) var drop_speed_limit
export(float) var drop_acceleration
export(float) var swap_speed
export(float) var delay_drop
export(float) var delay_first_drop
export(float) var delay_destroy

var m_sprite
var m_enabled_input = true
var m_enabled_drop_tranform = true
var m_color_id
var m_callbacks
var m_current_drop_speed
var m_delay_drop_countdown
var m_is_enter_drop_stop_state = true
var m_is_enter_drop_move_state = false
var m_is_waiting_to_destroy = false
var m_destroy_countdown
var m_bottom_block
var m_top_block
var m_is_swapping
var m_swap_with
var m_is_swap_back
var m_is_swap_x
var m_move_to_pos_x_or_y
var m_is_limit_drop = false
var m_limit_drop

static func get_random_color_id():
	return (randi() % VARIATION) + 1
	
static func get_shift_color_id(id):
	return 1 if id == VARIATION else id + 1
	
func _ready():
	m_current_drop_speed = drop_speed_init
	m_delay_drop_countdown = delay_drop

func _on_Block_input_event(viewport, event, shape_idx):
	if m_enabled_input and event.is_pressed():
		m_callbacks.block_on_click(self)

func init(color_id):
	m_sprite = get_child(0)
	m_color_id = color_id
	set_texture_to_default()
	
func get_color_id():
	return m_color_id
	
func get_top_block():
	return m_top_block
	
func get_bottom_block():
	return m_bottom_block
	
func get_column_index():
	return int(position.x / SIZE_X)
	
func get_row_index():
	return int(-(position.y + SIZE_Y) / SIZE_Y)
	
func get_pox_x():
	return position.x
	
func get_pox_y():
	return position.y
	
func set_pox_x(x):
	position.x = x
	
func set_pox_y(y):
	position.y = y
	
func set_pos_col_index(x):
	position.x = x * SIZE_X
	
func set_pos_row_index(y):
	position.y = -(y + 1) * SIZE_Y

func set_texture_to_default():
	m_sprite.texture = IMAGE_DEFAULT[m_color_id - 1]
	
func set_texture_to_selected():
	m_sprite.texture = IMAGE_SELECTED[m_color_id - 1]
	
func set_pos_to_top_block(block):
	position.x = block.position.x
	position.y = block.position.y - SIZE_Y
	
func set_pos_to_bottom_block(block):
	position.y = block.position.y + SIZE_Y
	
func set_callbacks(callbacks):
	m_callbacks = callbacks
	
func enable_input():
	m_enabled_input = true
	
func disable_input():
	m_enabled_input = false
	
func enable_drop_tranform():
	m_enabled_drop_tranform = true
	
func disable_drop_tranform():
	m_enabled_drop_tranform = false
	
func drop_tranform_move_alert(delta):
	m_callbacks.block_on_drop_move(self)
	
func drop_tranform_stop_alert(delta):
	m_callbacks.block_on_drop_stop(self)
	
func update_drop_speed_from_drop_acceleration(delta):
	if drop_speed_limit - m_current_drop_speed <= drop_acceleration * delta:
		m_current_drop_speed = drop_speed_limit
	else:
		m_current_drop_speed += drop_acceleration * delta
	
func update_pos_from_speed(delta, bottom_pos_y):
	var pos_y = position.y + m_current_drop_speed * delta
	if pos_y > bottom_pos_y:
		pos_y = bottom_pos_y
	position.y = pos_y
	
func drop_tranform_move(delta, bottom_pos_y):
	m_is_enter_drop_stop_state = false
	if !m_is_enter_drop_move_state:
		drop_tranform_move_alert(delta)
		m_is_enter_drop_move_state = true
	update_pos_from_speed(delta, bottom_pos_y)
	update_drop_speed_from_drop_acceleration(delta)
	
func drop_tranform_stop(delta):
	m_is_enter_drop_move_state = false
	if !m_is_enter_drop_stop_state:
		drop_tranform_stop_alert(delta)
		m_is_enter_drop_stop_state = true
		m_current_drop_speed = drop_speed_init
		
func drop_tranform(delta, bottom_pos_y):
	if position.y != bottom_pos_y:
		if m_delay_drop_countdown > 0:
			m_delay_drop_countdown -= delta
		else:
			drop_tranform_move(delta, bottom_pos_y)
	else:
		m_delay_drop_countdown = delay_drop
		drop_tranform_stop(delta)
		
func countdown_destroy(delta):
	if m_destroy_countdown > 0:
		m_destroy_countdown -= delta
	else:
		destroy()
		
func update_swap_x(delta):
	if abs(m_move_to_pos_x_or_y - position.x) < swap_speed * delta:
		position.x = m_move_to_pos_x_or_y
		m_is_swapping = false
		if m_top_block:
			m_top_block.enable_drop_tranform()
			m_top_block.unlock_limit_drop()
		if !m_swap_with.m_is_swapping:
			m_callbacks.block_on_stop_swapping(self, m_swap_with, m_is_swap_back)
			m_swap_with.enable_drop_tranform()
			m_swap_with.unlock_limit_drop()
		else:
			m_enabled_drop_tranform = false
	elif m_move_to_pos_x_or_y > position.x:
		position.x += swap_speed * delta
	else:
		position.x -= swap_speed * delta
			
func update_swap_y(delta):
	if abs(m_move_to_pos_x_or_y - position.y) < swap_speed * delta:
		position.y = m_move_to_pos_x_or_y
		m_is_swapping = false
		if m_top_block:
			m_top_block.enable_drop_tranform()
			m_top_block.unlock_limit_drop()
		if !m_swap_with.m_is_swapping:
			m_callbacks.block_on_stop_swapping(self, m_swap_with, m_is_swap_back)
			m_swap_with.enable_drop_tranform()
			m_swap_with.unlock_limit_drop()
		else:
			m_enabled_drop_tranform = false
	elif m_move_to_pos_x_or_y > position.y:
		position.y += swap_speed * delta
	else:
		position.y -= swap_speed * delta
			
func update_swap(delta):
	if m_is_swap_x:
		update_swap_x(delta)
	else:
		update_swap_y(delta)
		
func update(delta):
	if m_is_waiting_to_destroy:
		countdown_destroy(delta)
		return
	if m_is_swapping:
		update_swap(delta)
		return
	if !m_enabled_drop_tranform:
		return
	var bottom_pos_y
	if m_is_limit_drop:
		bottom_pos_y = m_limit_drop
	elif m_bottom_block:
		bottom_pos_y = m_bottom_block.position.y - SIZE_Y
	else:
		bottom_pos_y = 0 - SIZE_Y
	drop_tranform(delta, bottom_pos_y)
		
func set_delay_to_first_drop():
	m_delay_drop_countdown = delay_first_drop

func destroy():
	m_callbacks.block_on_destroy(self)
	if m_top_block:
		m_top_block.m_delay_drop_countdown = delay_first_drop
		m_top_block.m_bottom_block = m_bottom_block
	if m_bottom_block:
		m_bottom_block.m_top_block = m_top_block
	queue_free()
	
func is_waiting_to_destroy():
	return m_is_waiting_to_destroy
	
func get_remain_time_before_destroy():
	return m_destroy_countdown
	
func delay_destroy(delay = delay_destroy):
	m_callbacks.block_on_delay_destroy(self)
	m_enabled_input = false
	if !m_is_waiting_to_destroy:
		m_is_waiting_to_destroy = true
		m_destroy_countdown = delay
		return true
	else:
		return false

func set_top_block(top_block):
	m_top_block = top_block

func set_bottom_block(bottom_block):
	m_bottom_block = bottom_block
	
func swap_x(block):
	m_is_swap_x = true
	block.m_is_swap_x = true
	m_move_to_pos_x_or_y = block.get_column_index() * SIZE_X
	block.m_move_to_pos_x_or_y = get_column_index() * SIZE_X
	if m_top_block:
		m_top_block.m_bottom_block = block
	if block.m_top_block:
		block.m_top_block.m_bottom_block = self
	if m_bottom_block:
		m_bottom_block.m_top_block = block
	else:
		m_callbacks.block_on_change_bottom(block, get_column_index())
	if block.m_bottom_block:
		block.m_bottom_block.m_top_block = self
	else:
		m_callbacks.block_on_change_bottom(self, block.get_column_index())
	var buff = m_top_block
	m_top_block = block.m_top_block
	block.m_top_block = buff
	buff = m_bottom_block
	m_bottom_block = block.m_bottom_block
	block.m_bottom_block = buff
	
func swap_y_top(block):
	m_is_swap_x = false
	block.m_is_swap_x = false
	m_move_to_pos_x_or_y = -(block.get_row_index() + 1) * SIZE_Y
	block.m_move_to_pos_x_or_y = -(get_row_index() + 1) * SIZE_Y
	if block.m_top_block:
		block.m_top_block.set_limit_drop(-(block.get_row_index() + 2) * SIZE_Y)
		block.m_top_block.m_bottom_block = self
	if m_bottom_block:
		m_bottom_block.m_top_block = block
	else:
		m_callbacks.block_on_change_bottom(block, get_column_index())
	m_top_block = block.m_top_block
	block.m_top_block = self
	block.m_bottom_block = m_bottom_block
	m_bottom_block = block
	
func swap_y_bottom(block):
	m_is_swap_x = false
	block.m_is_swap_x = false
	m_move_to_pos_x_or_y = -(block.get_row_index() + 1) * SIZE_Y
	block.m_move_to_pos_x_or_y = -(get_row_index() + 1) * SIZE_Y
	if m_top_block:
		m_top_block.set_limit_drop(-(get_row_index() + 2) * SIZE_Y)
		m_top_block.m_bottom_block = block
	if block.m_bottom_block:
		block.m_bottom_block.m_top_block = self
	else:
		m_callbacks.block_on_change_bottom(self, block.get_column_index())
	block.m_top_block = m_top_block
	m_top_block = block
	m_bottom_block = block.m_bottom_block
	block.m_bottom_block = self
	
func enable_swap(block, is_swap_back):
	m_is_swapping = true
	block.m_is_swapping = true
	m_is_swap_back = is_swap_back
	block.m_is_swap_back = is_swap_back
	m_swap_with = block
	block.m_swap_with = self
	
func swap(block, is_swap_back = false):
	enable_swap(block, is_swap_back)
	if block == m_top_block:
		swap_y_top(block)
	elif block == m_bottom_block:
		swap_y_bottom(block)
	else:
		swap_x(block)
		
func set_limit_drop(y):
	m_is_limit_drop = true
	m_limit_drop = y
	
func unlock_limit_drop():
	m_is_limit_drop = false