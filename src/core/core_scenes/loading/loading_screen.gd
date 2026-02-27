extends Control

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var color_rect: ColorRect = %ColorRect


func _ready() -> void:
	color_rect.color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	
	# Configure bar to accept 0.0..1.0 directly
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0


# Set progress_bar value
func set_progress(progress: float) -> void:
	var clamped: float = clamp(progress, 0.0, 1.0)
	progress_bar.value = clamped
