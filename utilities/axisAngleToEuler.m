function euler_angles_deg = axisAngleToEuler(angle_degrees, axis, order)
    % Normalize the axis vector
    axis_normalized = axis / norm(axis);
    
    % Convert angle from degrees to radians
    angle_radians = angle_degrees;
    
    % Convert axis-angle to quaternion
    % Note: If you have a different MATLAB version, you might need to use the quaternion function or another method.
    q = piAngle2quat(angle_radians, axis_normalized(1), axis_normalized(2), axis_normalized(3));
    
    % Convert quaternion to Euler angles (ZYX order)
    euler_angles_rad = quat2eul(q, order);
    
    % Convert Euler angles from radians to degrees
    euler_angles_deg = rad2deg(euler_angles_rad);
end

function q = piAngle2quat (theta, vx, vy, vz)
    % Convert angle from degrees to radians
    theta_rad = deg2rad(theta);

    % Normalize the axis vector
    norm_v = sqrt(vx^2 + vy^2 + vz^2);
    x = vx / norm_v;
    y = vy / norm_v;
    z = vz / norm_v;

    % Compute quaternion components
    w = cos(theta_rad / 2);
    xp = x * sin(theta_rad / 2);
    yp = y * sin(theta_rad / 2);
    zp = z * sin(theta_rad / 2);

    % Return the quaternion
    q = [w, xp, yp, zp];
end

