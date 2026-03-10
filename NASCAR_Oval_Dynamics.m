%% =========================================================================
%  NASCAR OVAL DYNAMICS SIMULATOR
%  =========================================================================
%  Author      : Eliazar Alvarez
%  Date        : March 2026
%  Institution : University of Texas at San Antonio
%  Course      : Personal Portfolio Project
%
%  Description : Models lateral g-forces, tire loads, and wedge adjustment
%                effects on a NASCAR Cup car navigating banked oval corners.
%                Compares three superspeedways: Daytona, Charlotte, Talladega.
%
%  Outputs     : 1. Lateral g-force vs speed (Daytona single track)
%                2. Lateral g-force vs speed (3-track comparison)
%                3. Wedge adjustment vs rear cross weight (handling balance)
%
%  Tools       : MATLAB
%  GitHub      : github.com/aeliazar11/NASCAR-Oval-Dynamics
%% =========================================================================

%% --- HOUSEKEEPING ---
clear;          % Clear all variables from workspace
clc;            % Clear command window
close all;      % Close any open figure windows

%% --- CONSTANTS ---
g           = 9.81;         % Gravitational acceleration (m/s^2)
mph_to_ms   = 0.44704;      % Conversion factor: mph to m/s
lbs_to_N    = 4.448;        % Conversion factor: pounds to Newtons

%% --- CAR PARAMETERS ---
% Based on NASCAR Cup Series technical regulations
mass        = 1500;         % Vehicle mass (kg)
wheelbase   = 2.87;         % Front to rear axle distance (m)
track_width = 1.57;         % Left to right tire centerline distance (m)
cg_height   = 0.48;         % Center of gravity height above ground (m)

%% --- SPEED RANGE ---
speed_mph   = 180:1:200;            % Speed array: 180 to 200 mph (1 mph steps)
speed_ms    = speed_mph * mph_to_ms; % Convert to m/s for calculations

%% =========================================================================
%  SECTION 1 — SINGLE TRACK: DAYTONA LATERAL G-FORCE
%% =========================================================================

%% --- DAYTONA TRACK PARAMETERS ---
banking_deg     = 31;                   % Banking angle (degrees)
banking_rad     = deg2rad(banking_deg); % Convert to radians
radius_daytona  = 305;                  % Corner radius (m)

%% --- LATERAL FORCE CALCULATIONS ---
% Centripetal acceleration required to navigate the corner: a = v^2 / r
a_lateral   = (speed_ms.^2) / radius_daytona;  % Lateral acceleration (m/s^2)

% Convert to g-force for intuitive interpretation
lat_g       = a_lateral / g;                    % Lateral g-force (g)

% Net lateral force the tires must produce
% Banking assists the tires — gravity component reduces required tire force
lateral_force = mass * (a_lateral - g * tan(banking_rad));  % (N)

%% --- TIRE LOAD CALCULATIONS ---
weight          = mass * g;                     % Total vehicle weight (N)
load_static     = weight / 2;                   % Static load per side (N)

% Load transfer: weight shifts to outside (right) tires during left-hand corners
load_transfer   = (mass .* a_lateral * cg_height) / track_width;  % (N)

load_outside    = load_static + load_transfer;  % Right side tires (N)
load_inside     = load_static - load_transfer;  % Left side tires (N)

%% =========================================================================
%  SECTION 2 — THREE TRACK COMPARISON
%% =========================================================================

%% --- TRACK DATABASE ---
% Each track defined by name, banking angle (deg), and corner radius (m)
tracks(1).name      = 'Daytona';
tracks(1).banking   = 31;
tracks(1).radius    = 305;

tracks(2).name      = 'Charlotte';
tracks(2).banking   = 24;
tracks(2).radius    = 213;

tracks(3).name      = 'Talladega';
tracks(3).banking   = 33;
tracks(3).radius    = 320;

% Plot colors for each track
colors = ['b', 'r', 'g'];

%% --- CALCULATE G-FORCE FOR EACH TRACK ---
% Pre-allocate results matrix for efficiency: rows = tracks, cols = speeds
lat_g_all = zeros(3, length(speed_mph));

for i = 1:3
    a_lat_track         = (speed_ms.^2) / tracks(i).radius;
    lat_g_all(i,:)      = a_lat_track / g;
end

%% =========================================================================
%  SECTION 3 — WEDGE ADJUSTMENT MODEL
%% =========================================================================

%% --- WEDGE PARAMETERS ---
% Wedge adjusts rear spring perch, shifting load between LR and RR tires
% Positive wedge = more right rear load = tighter handling
wedge_lbs   = -30:5:30;         % Adjustment range (lbs)
wedge_N     = wedge_lbs * lbs_to_N; % Convert to Newtons

%% --- REFERENCE CONDITION: DAYTONA AT 190 MPH ---
speed_ref       = 190 * mph_to_ms;                      % Convert to m/s
a_lat_ref       = (speed_ref^2) / tracks(1).radius;     % Lateral accel (m/s^2)

%% --- CORNER WEIGHT CALCULATIONS ---
rr_static       = (mass * g) / 4;      % Right rear static corner weight (N)
lr_static       = (mass * g) / 4;      % Left rear static corner weight (N)

% Rear axle lateral load transfer
lat_transfer    = ((mass/2) * a_lat_ref * cg_height) / track_width;
lat_transfer    = min(lat_transfer, rr_static * 0.08);  % Physical cap (N)

% Corner loads with cornering and wedge applied
rr_load         = rr_static + lat_transfer + wedge_N;   % Right rear (N)
lr_load         = lr_static - lat_transfer - wedge_N;   % Left rear (N)

% Rear cross weight percentage — key NASCAR setup metric
% 50% = neutral, >53% = tight (understeer), <47% = loose (oversteer)
rear_cross      = (rr_load ./ (rr_load + lr_load)) * 100;  % (%)

%% =========================================================================
%  PLOTS
%% =========================================================================

%% --- FIGURE 1: Daytona Lateral G-Force vs Speed ---
figure(1);
plot(speed_mph, lat_g, 'b-', 'LineWidth', 2);
xlabel('Speed (mph)');
ylabel('Lateral G-Force (g)');
title('NASCAR Lateral G-Force vs Speed — Daytona (31° Banking)');
grid on;
xlim([180 200]);

%% --- FIGURE 2: Three Track Comparison ---
figure(2);
hold on;
for i = 1:3
    plot(speed_mph, lat_g_all(i,:), colors(i), ...
         'LineWidth', 2, ...
         'DisplayName', tracks(i).name);
end
hold off;
xlabel('Speed (mph)');
ylabel('Lateral G-Force (g)');
title('NASCAR Lateral G-Force vs Speed — Superspeedway Comparison');
legend('show', 'Location', 'northwest');
grid on;
xlim([180 200]);

%% --- FIGURE 3: Wedge Adjustment vs Handling Balance ---
figure(3);
plot(wedge_lbs, rear_cross, 'r-', 'LineWidth', 2);
xlabel('Wedge Adjustment (lbs)');
ylabel('Rear Cross Weight (%)');
title('NASCAR Wedge Adjustment vs Handling Balance — Daytona 190 mph');
yline(50, 'k--', 'Neutral',     'LineWidth', 1.5);
yline(53, 'b--', 'Tight Limit', 'LineWidth', 1.5);
yline(47, 'g--', 'Loose Limit', 'LineWidth', 1.5);
ylim([46 57]);
grid on;

%% --- END OF SCRIPT ---