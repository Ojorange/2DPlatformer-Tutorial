/// @description Camera follow — mirrors Unity CameraFollow.cs.

target = instance_find(obj_player, 0);

// Focus area size in pixels
focus_area_size_x = 4 * PIXELS_PER_UNIT;
focus_area_size_y = 3 * PIXELS_PER_UNIT;

vertical_offset      = 2 * PIXELS_PER_UNIT;   // pixels
look_ahead_dst_x     = 4 * PIXELS_PER_UNIT;
look_smooth_time_x   = 0.5;
vertical_smooth_time = 0.2;

// Focus area state
fa_left   = target.x - focus_area_size_x / 2;
fa_right  = target.x + focus_area_size_x / 2;
fa_bottom = target.bbox_bottom;
fa_top    = target.bbox_bottom - focus_area_size_y;  // GMS2 Y-down: top is smaller y
fa_centre_x = (fa_left + fa_right) / 2;
fa_centre_y = (fa_top  + fa_bottom) / 2;
fa_vel_x  = 0;
fa_vel_y  = 0;

// Look-ahead state
current_look_ahead_x  = 0;
target_look_ahead_x   = 0;
look_ahead_dir_x      = 0;
smooth_look_velocity_x = 0;
smooth_velocity_y      = 0;
look_ahead_stopped     = false;
