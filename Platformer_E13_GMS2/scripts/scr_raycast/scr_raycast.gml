/// @description Raycast helpers — replaces Unity Physics2D.Raycast.
/// Rays are always axis-aligned (horizontal OR vertical).
/// Solid objects: inherit par_solid.  One-way platforms: inherit par_through.
/// Slope objects store surf_normal_x / surf_normal_y as instance vars.

/// @function rc_update_origins(bl, bt, br, bb)
/// @desc Returns a struct with the four inset ray-origin corner points.
///       Coordinate note (GMS2 Y-down):
///         bbox_top    = smallest y  (top    of sprite on screen)
///         bbox_bottom = largest  y  (bottom of sprite on screen)
function rc_update_origins(bl, bt, br, bb) {
    return {
        bottom_left_x:  bl + SKIN_WIDTH,
        bottom_left_y:  bb - SKIN_WIDTH,   // bottom = large y; inset upward → subtract
        bottom_right_x: br - SKIN_WIDTH,
        bottom_right_y: bb - SKIN_WIDTH,
        top_left_x:     bl + SKIN_WIDTH,
        top_left_y:     bt + SKIN_WIDTH,   // top = small y; inset downward → add
        top_right_x:    br - SKIN_WIDTH,
        top_right_y:    bt + SKIN_WIDTH
    };
}

/// @function rc_calculate_ray_spacing(bl, bt, br, bb)
/// @desc Mirrors Unity RaycastController.CalculateRaySpacing().
function rc_calculate_ray_spacing(bl, bt, br, bb) {
    var bounds_w = (br - bl) - SKIN_WIDTH * 2;
    var bounds_h = (bb - bt) - SKIN_WIDTH * 2;

    var h_count = max(2, round(bounds_h / DST_BETWEEN_RAYS));
    var v_count = max(2, round(bounds_w / DST_BETWEEN_RAYS));

    return {
        horizontal_ray_count:   h_count,
        vertical_ray_count:     v_count,
        horizontal_ray_spacing: bounds_h / (h_count - 1),
        vertical_ray_spacing:   bounds_w / (v_count - 1)
    };
}

/// @function do_raycast(rx, ry, dir_x, dir_y, ray_length)
/// @desc Casts an axis-aligned ray. Returns hit-info struct.
///       Checks par_solid first, then par_through (is_through = true).
///       Uses collision_line (GMS2 returns closest instance to ray start).
function do_raycast(rx, ry, dir_x, dir_y, ray_length) {
    var result = {
        hit:       false,
        distance:  0,
        normal_x:  0,
        normal_y:  0,
        is_through: false,
        inst:      noone
    };

    var x2 = rx + dir_x * ray_length;
    var y2 = ry + dir_y * ray_length;

    var closest_dist  = ray_length + 1;
    var closest_inst  = noone;
    var closest_thru  = false;

    // --- Check solid geometry ---
    var s_hit = collision_line(rx, ry, x2, y2, par_solid, false, false);
    if (s_hit != noone) {
        var sd = _ray_edge_distance(rx, ry, dir_x, dir_y, s_hit);
        if (sd <= closest_dist) {
            closest_dist = sd;
            closest_inst = s_hit;
            closest_thru = false;
        }
    }

    // --- Check one-way platforms ---
    var t_hit = collision_line(rx, ry, x2, y2, par_through, false, false);
    if (t_hit != noone) {
        var td = _ray_edge_distance(rx, ry, dir_x, dir_y, t_hit);
        if (td < closest_dist) {
            closest_dist = td;
            closest_inst = t_hit;
            closest_thru = true;
        }
    }

    if (closest_inst == noone) return result;

    result.hit        = true;
    result.distance   = closest_dist;
    result.inst       = closest_inst;
    result.is_through = closest_thru;

    // --- Determine surface normal ---
    with (closest_inst) {
        if (variable_instance_exists(id, "surf_normal_x")) {
            result.normal_x = surf_normal_x;
            result.normal_y = surf_normal_y;
        } else {
            // Infer normal from ray direction (axis-aligned AABB surface)
            if (dir_x != 0) {
                result.normal_x = -sign(dir_x);   // wall normal: opposite of ray
                result.normal_y = 0;
            } else {
                result.normal_x = 0;
                result.normal_y = -sign(dir_y);   // floor/ceil normal: opposite of ray
            }
        }
    }

    return result;
}

/// @function _ray_edge_distance(rx, ry, dir_x, dir_y, inst)
/// @desc Computes distance from ray origin to the nearest AABB edge of inst.
function _ray_edge_distance(rx, ry, dir_x, dir_y, inst) {
    if (dir_y == 0) {
        // Horizontal ray
        if (dir_x > 0) return max(0, inst.bbox_left  - rx);
        else           return max(0, rx - inst.bbox_right);
    } else {
        // Vertical ray
        if (dir_y > 0) return max(0, inst.bbox_top    - ry);  // downward: hit top edge
        else           return max(0, ry - inst.bbox_bottom);  // upward:   hit bottom edge
    }
}
