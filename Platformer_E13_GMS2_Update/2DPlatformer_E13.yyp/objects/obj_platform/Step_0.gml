/// @description Moving platform step.

var dt = delta_time / 1000000;
platform_time += dt;

origins = rc_update_origins(bbox_left, bbox_top, bbox_right, bbox_bottom);

var vel = platform_calculate_movement(dt);

platform_calculate_passenger_movement(vel.vx, vel.vy);

platform_move_passengers(true);

x += vel.vx;
y += vel.vy;

platform_move_passengers(false);
