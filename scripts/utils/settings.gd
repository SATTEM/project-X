extends Node
## 全局数据

## UI设计
@export_group("UISettings", "ui_design")
# 分辨率
@export var ui_design_width: int = 1920
@export var ui_design_height: int = 1080
@export var ui_design_monster_spacing: int = 240
@export var ui_design_intent_icon_height: int = 128
@export var ui_design_player_display_size: = Vector2(250, 250)
# 特效设计
@export var ui_design_float_duration: float = 1.0
@export var ui_design_float_offset: float = 40.0
@export var ui_design_intent_shade_alpha: float = 0.5
# 字体
@export var ui_design_font_size: int = 20
# 点击检测半径
@export var ui_design_character_click_radius: float = 100.0

## 机制全局设置
# 每行最大单位数量
@export_group("RowSettings", "position_row")
@export var position_row_player_count = 1
@export var position_row_front_count = 3
@export var position_row_enemy_count = 3
