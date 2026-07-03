function euler_angles_deg = axisAngleToEuler(angle_degrees, axis, order)
    if nargin < 3 || isempty(order), order = 'zyx'; end

    % Normalize the axis vector
    axis_normalized = axis / norm(axis);
    
    % Convert angle from degrees to radians
    angle_radians = angle_degrees;
    
    % Convert axis-angle to quaternion
    % Note: If you have a different MATLAB version, you might need to use the quaternion function or another method.
    q = piAngle2quat(angle_radians, axis_normalized(1), axis_normalized(2), axis_normalized(3));
    
    % Convert quaternion to Euler angles.  MATLAB's quat2eul lives in
    % toolbox-specific locations, so keep a local fallback for core parsing.
    if exist('quat2eul', 'file')
        euler_angles_rad = quat2eul(q, order);
    else
        euler_angles_rad = localQuat2eul(q, order);
    end
    
    % Convert Euler angles from radians to degrees
    euler_angles_deg = rad2deg(euler_angles_rad);
end

function euler = localQuat2eul(q, order)
    % Local scalar-first quaternion to Euler conversion for parser use.
    % The PBRT parser currently requests 'zyx'.  Keep the explicit error for
    % other orders so unsupported cases fail clearly on MATLAB installs that
    % do not provide quat2eul.
    if ~strcmpi(order, 'zyx')
        error('axisAngleToEuler:UnsupportedOrder', ...
            'Local quaternion fallback only supports zyx Euler order.');
    end

    q = q ./ norm(q);
    w = q(1); x = q(2); y = q(3); z = q(4);

    % Rotation matrix from scalar-first quaternion.
    R = [1 - 2*(y^2 + z^2),     2*(x*y - z*w),     2*(x*z + y*w); ...
             2*(x*y + z*w), 1 - 2*(x^2 + z^2),     2*(y*z - x*w); ...
             2*(x*z - y*w),     2*(y*z + x*w), 1 - 2*(x^2 + y^2)];

    pitch = asin(max(-1, min(1, -R(3,1))));
    if abs(cos(pitch)) > eps
        yaw = atan2(R(2,1), R(1,1));
        roll = atan2(R(3,2), R(3,3));
    else
        yaw = atan2(-R(1,2), R(2,2));
        roll = 0;
    end

    euler = [yaw pitch roll];
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
