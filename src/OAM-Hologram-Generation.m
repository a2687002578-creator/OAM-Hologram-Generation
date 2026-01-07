%% ForkedDiffractionGrating_OAM_Superposition_Fixed
%
% Based on code by Brett Rojec and Kiko Galvez.
% Refactored by Sun-optica (BIT) to match original physics exactly.

clear all;
close all;

%% 1. Parameter Definitions
s = 0.1;          % Fringe density
ell1 = 1;         % Corresponds to original 'ell'
ell2 = 4;         % Corresponds to original 'e22'

% Parameters matching original code
Nx = 1024; 
Ny = 1024;  
w = 100;          % Waist width
ampmod = false;   % Amplitude modulation switch
phaseblaze = true;
bowmanblaze = false;

imName = 'SLMpat'; 

%% 2. Optimized Phase Calculation (Vectorized)

% 2.1 Coordinate System
x0 = Nx/2; 
y0 = Ny/2;
[x_grid, y_grid] = meshgrid(1:Nx, 1:Ny);
xr = x_grid - x0;
yr = y_grid - y0;
[phi, r] = cart2pol(xr, yr); % Get polar coordinates

% 2.2 Construct Fields (Restoring Original Logic)

% --- Field 1 (Original: terms with ell) ---
% Original used -sin(ell*phi) and -cos(ell*phi), which is -exp(1j*ell*phi)
Term1 = -exp(1j * ell1 * phi); 

% --- Field 2 (Original: terms with e22) ---
% Restore the amplitude scaling factor from original code:
% factor = sqrt(ell!/e22!) * (r*sqrt(2)/w)^(abs(e22)-abs(ell))
fact_ratio = sqrt(factorial(abs(ell1)) / factorial(abs(ell2)));
radial_term = (r * sqrt(2) / w) .^ (abs(ell2) - abs(ell1));

Amplitude_Factor = fact_ratio * radial_term;

Term2 = Amplitude_Factor .* exp(1j * ell2 * phi);

% 2.3 Superposition
E_total = Term1 + Term2;

% 2.4 Extract Phase
% Original code logic: atan2(Im, Re) is essentially angle(E_total)
raw_phase = angle(E_total);

% 2.5 Add Grating (Tilt)
phi_final = raw_phase + s * xr; 

% 2.6 Amplitude Modulation "Fudge" Factor (Optional)
% If you want strictly original behavior when ampmod=true
fudge = ones(Ny, Nx);
if ampmod
    % Original formula approximation
    fudge = (r.^abs(ell1)) .* exp(-r.^2/w^2) / ((w*sqrt(ell1/2))^abs(ell1)*exp(-ell1/2));
end

%% 3. Modulation and Output

% Normalize to [0, 1]
if phaseblaze
    r1 = mod(phi_final, 2*pi) / (2*pi);
else
    % Binary
    r1 = mod(phi_final, 2*pi) / (2*pi);
    r1(r1 >= 0.5) = 1;
    r1(r1 < 0.5) = 0;
end

% Apply Amp Mod
if ampmod
    r1 = r1 .* fudge;
end

% Bowman Blaze (Skipped for brevity, can be added if needed)

% Output
C = zeros(Ny, Nx, 3);
C(:,:,1) = r1; C(:,:,2) = r1; C(:,:,3) = r1;

figure(1);
imshow(C, [0 1]);
colormap(gray);
axis equal; axis off;
title(['Restored OAM Pattern: l1=', num2str(ell1), ', l2=', num2str(ell2)]);

%% 4. Save Output to Sibling 'results' Folder

% 1. Get the absolute path of the folder containing this script (e.g., .../src)
%    mfilename('fullpath') returns the full path of the script without extension
currentScriptPath = mfilename('fullpath');
[currentFolder, ~, ~] = fileparts(currentScriptPath);

% 2. Go up one level to the Project Root (e.g., .../Project)
%    We use fileparts again on the currentFolder to get its parent
[projectRoot, ~, ~] = fileparts(currentFolder);

% 3. Define the full path for the 'results' folder (e.g., .../Project/results)
outputDir = fullfile(projectRoot, 'results');

% 4. Check if 'results' folder exists, if not, create it automatically
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['Created new directory: ', outputDir]);
end

% 5. Construct the full file path
fullFileName = fullfile(outputDir, [imName, '_Restored.bmp']);

% 6. Save the image
imwrite(C, fullFileName, 'png');

disp(['Success! Image saved to: ', fullFileName]);