/// @description Controller2D logic — mirrors Unity Controller2D.cs and RaycastController.cs.
/// All functions operate on the CALLING INSTANCE's variables.
/// Coordinate system: GMS2 Y-DOWN  (vel_y > 0 = falling, move_y > 0 = downward).

// ---------------------------------------------------------------------------
// Public entry-point
// ---------------------------------------------------------------------------

/// @function controller2d_move(move_x_in, move_y_in, inp_x, inp_y, standing_on_platform)
function controller2d_move(move_x_in, move_y_in, inp_x, inp_y, standing_on_platform) {
    move_x        = move_x_in;
    move_y        = move_y_in;
    player_input_x = inp_x;
    player_input_y = inp_y;

    origins = rc_update_origins(bbox_left, bbox_top, bbox_right, bbox_bottom);

    col_reset();
    col_move_amount_old_x = move_x;
    col_move_amount_old_y = move_y;

    // GMS2 Y-down: move_y > 0 means moving DOWN (= descending a slope)
    if (move_y > 0) {
        _descend_slope();
    }

    if (move_x != 0) {
        col_face_dir = sign0(move_x);
    }

    _horizontal_collisions();

    if (move_y != 0) {
        _vertical_collisions();
    }

    x += move_x;
    y += move_y;

    if (standing_on_platform) {
        col_below = true;
    }
}

// ---------------------------------------------------------------------------
// Collision flag reset
// ---------------------------------------------------------------------------

/// @function col_reset()
function col_reset() {
    col_above                 = false;
    col_below                 = false;
    col_left                  = false;
    col_right                 = false;
    col_climbing_slope        = false;
    col_descending_slope      = false;
    col_sliding_down_max_slope = false;
    col_slope_normal_x        = 0;
    col_slope_normal_y        = 0;
    col_slope_angle_old       = col_slope_angle;
    col_slope_angle           = 0;
}

// ---------------------------------------------------------------------------
// Horizontal collisions
// ---------------------------------------------------------------------------

/// @function _horizontal_collisions()
function _horizontal_collisions() {
    var dir_x      = col_face_dir;
    var ray_length = abs(move_x) + SKIN_WIDTH;
    if (abs(move_x) < SKIN_WIDTH) {
        ray_length = 2 * SKIN_WIDTH;
    }

    for (var i = 0; i < h_ray_count; i++) {
        // Origin: bottom-right or bottom-left; travel UP each iteration (y decreases in GMS2)
        var rx = (dir_x == -1) ? origins.bottom_left_x : origins.bottom_right_x;
        var ry = origins.bottom_left_y - h_ray_spacing * i;

        var hit = do_raycast(rx, ry, dir_x, 0, ray_length);
        if (!hit.hit)            continue;
        if (hit.distance == 0)   continue;

        var slope_angle = vec2_angle_from_up(hit.normal_x, hit.normal_y);

        if (i == 0 && slope_angle <= MAX_SLOPE_ANGLE) {
            if (col_descending_slope) {
                col_descending_slope = false;
                move_x = col_move_amount_old_x;
                move_y = col_move_amount_old_y;
            }
            var dist_to_slope = 0;
            if (slope_angle != col_slope_angle_old) {
                dist_to_slope = hit.distance - SKIN_WIDTH;
                move_x -= dist_to_slope * dir_x;
            }
            _climb_slope(slope_angle, hit.normal_x, hit.normal_y);
            move_x += dist_to_slope * dir_x;
        }

        if (!col_climbing_slope || slope_angle > MAX_SLOPE_ANGLE) {
            move_x     = (hit.distance - SKIN_WIDTH) * dir_x;
            ray_length = hit.distance;

            if (col_climbing_slope) {
                // Maintain correct Y while climbing: GMS2 Y-down → upward = negative
                move_y = -tan(col_slope_angle * (pi / 180)) * abs(move_x);
            }

            col_left  = (dir_x == -1);
            col_right = (dir_x ==  1);
        }
    }
}

// ---------------------------------------------------------------------------
// Vertical collisions
// ---------------------------------------------------------------------------

/// @function _vertical_collisions()
function _vertical_collisions() {
    // GMS2 Y-down: dir_y = 1 → moving down (falling), dir_y = -1 → moving up (jumping)
    var dir_y      = sign(move_y);
    var ray_length = abs(move_y) + SKIN_WIDTH;

    for (var i = 0; i < v_ray_count; i++) {
        // Cast from bottom (dir_y=1) or top (dir_y=-1), spread horizontally
        var ry = (dir_y == 1) ? origins.bottom_left_y : origins.top_left_y;
        var rx = origins.top_left_x + v_ray_spacing * i + move_x;

        var hit = do_raycast(rx, ry, 0, dir_y, ray_length);
        if (!hit.hit) continue;

        // One-way platform logic
        if (hit.is_through) {
            if (dir_y == -1 || hit.distance == 0) continue; // moving up or inside → skip
            if (col_falling_through_platform)       continue;
            if (player_input_y == 1) {               // pressing DOWN to drop through
                col_falling_through_platform = true;
                alarm[0] = game_get_speed(gamespeed_fps) * 0.5;
                continue;
            }
        }

        move_y     = (hit.distance - SKIN_WIDTH) * dir_y;
        ray_length = hit.distance;

        if (col_climbing_slope) {
            // Keep move_x consistent with slope while climbing
            move_x = move_y / tan(col_slope_angle * (pi / 180)) * sign(move_x);
        }

        col_below = (dir_y ==  1);
        col_above = (dir_y == -1);
    }

    // Re-check for slope change mid-climb
    if (col_climbing_slope) {
        var dir_x2 = sign(move_x);
        var rl2    = abs(move_x) + SKIN_WIDTH;
        var rx2    = (dir_x2 == -1) ? origins.bottom_left_x : origins.bottom_right_x;
        // In GMS2 Y-down, add move_y (positive = down) to get projected position
        var ry2    = origins.bottom_left_y + move_y;

        var hit2 = do_raycast(rx2, ry2, dir_x2, 0, rl2);
        if (hit2.hit) {
            var new_slope = vec2_angle_from_up(hit2.normal_x, hit2.normal_y);
            if (new_slope != col_slope_angle) {
                move_x            = (hit2.distance - SKIN_WIDTH) * dir_x2;
                col_slope_angle   = new_slope;
                col_slope_normal_x = hit2.normal_x;
                col_slope_normal_y = hit2.normal_y;
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Slope helpers
// ---------------------------------------------------------------------------

/// @function _climb_slope(slope_angle, nx, ny)
function _climb_slope(slope_angle, nx, ny) {
    var move_dist  = abs(move_x);
    var climb_y    = sin(slope_angle * (pi / 180)) * move_dist;

    // Unity: if (moveAmount.y <= climbY) { moveAmount.y = climbY; ... }
    // GMS2 Y-down: climbing = upward = negative y.
    // Equivalent: if (move_y >= -climb_y) — player not already rising faster.
    if (move_y >= -climb_y) {
        move_y            = -climb_y;  // upward in GMS2
        move_x            = cos(slope_angle * (pi / 180)) * move_dist * sign(move_x);
        col_below         = true;
        col_climbing_slope = true;
        col_slope_angle   = slope_angle;
        col_slope_normal_x = nx;
        col_slope_normal_y = ny;
    }
}

/// @function _descend_slope()
function _descend_slope() {
    // Cast short downward rays from both bottom corners to detect max-slope sliding
    var rl = abs(move_y) + SKIN_WIDTH;
    var hit_l = do_raycast(origins.bottom_left_x,  origins.bottom_left_y,  0, 1, rl);
    var hit_r = do_raycast(origins.bottom_right_x, origins.bottom_right_y, 0, 1, rl);

    // XOR: exactly one side hits → max slope
    if (hit_l.hit != hit_r.hit) {
        _slide_down_max_slope(hit_l);
        _slide_down_max_slope(hit_r);
    }

    if (!col_sliding_down_max_slope) {
        var dir_x = sign0(move_x);
        // Look opposite to movement direction (behind the foot on the slope)
        var rx = (dir_x == -1) ? origins.bottom_right_x : origins.bottom_left_x;
        var ry = (dir_x == -1) ? origins.bottom_right_y : origins.bottom_left_y;

        var hit = do_raycast(rx, ry, 0, 1, 9999);
        if (hit.hit) {
            var sa = vec2_angle_from_up(hit.normal_x, hit.normal_y);
            if (sa != 0 && sa <= MAX_SLOPE_ANGLE) {
                // slope normal x points in the same direction as movement for a descending slope
                if (sign(hit.normal_x) == dir_x) {
                    if (hit.distance - SKIN_WIDTH <= tan(sa * (pi / 180)) * abs(move_x)) {
                        var dist      = abs(move_x);
                        var desc_y    = sin(sa * (pi / 180)) * dist; // positive → downward in GMS2
                        move_x        = cos(sa * (pi / 180)) * dist * sign(move_x);
                        move_y       += desc_y;                       // more downward in GMS2
                        col_slope_angle       = sa;
                        col_descending_slope  = true;
                        col_below             = true;
                        col_slope_normal_x    = hit.normal_x;
                        col_slope_normal_y    = hit.normal_y;
                    }
                }
            }
        }
    }
}

/// @function _slide_down_max_slope(hit_result)
function _slide_down_max_slope(hit) {
    if (!hit.hit) return;
    var sa = vec2_angle_from_up(hit.normal_x, hit.normal_y);
    if (sa > MAX_SLOPE_ANGLE) {
        move_x                    = sign(hit.normal_x) * (abs(move_y) - hit.distance) / tan(sa * (pi / 180));
        col_slope_angle           = sa;
        col_sliding_down_max_slope = true;
        col_slope_normal_x        = hit.normal_x;
        col_slope_normal_y        = hit.normal_y;
    }
}
